/**
 * Copyright 2025 Hiroyuki Matsuoka
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @description The mock implementation of the `IEloquent` interface, designed to enable fast,
 * reliable, and database-independent unit testing of service classes.
 *
 * Instead of interacting with the Salesforce database, `MockEloquent` operates on an
 * in-memory list of `IEntry` objects (typically `MockEntry` instances) that are
 * provided during its construction. This allows a developer to precisely control the
 * data that a query will "return" in a test scenario.
 *
 * DML operations like `doInsert` are simulated (e.g., by assigning a mock Id) without
 * performing any actual DML. The class also includes a constructor to force exceptions,
 * enabling robust testing of error-handling logic.
 *
 * Scope of the simulation: this mock reproduces the SHAPE of DML — which inputs the
 * platform rejects (Id present on insert, Id missing on update/delete, null elements,
 * null arguments, an unusable external-Id field, a field token from another SObject
 * type, a missing or duplicated external-Id value inside one call), what the results
 * carry, and the
 * all-or-nothing rollback contract. It does NOT reproduce the MEANING of an org:
 * field-level security and CRUD (userMode()/systemMode() are no-ops here), validation
 * rules, required fields, unique constraints, triggers and their side effects,
 * lookup filters, field length and value-type conformance (STRING_TOO_LONG etc.), or governor limits. Nor does it reproduce the 10-chunk limit on
 * type-mixed lists. Those belong to integration tests against a real org.
 * @see IEloquent
 * @see Eloquent
 * @see MockEntry
 * @directory ApexEloquent/Eloquents
 */
public with sharing class MockEloquent implements IEloquent {
  private static final String DEFAULT_LABEL = 'default';

  private final List<IEntry> entries;
  private Integer insertCount;
  private Map<String, List<ErrorConfig>> errorQueueMap = new Map<String, List<ErrorConfig>>();
  private ErrorConfig lastConfig;

  /**
   * @deprecated Direct field access will be removed in a future major version.
   * Use lastScribe() instead — this holds the same value.
   */
  @TestVisible
  private Scribe scribe;

  private Map<String, List<Scribe>> scribesByLabel = new Map<String, List<Scribe>>();

  private String currentLabel = DEFAULT_LABEL;
  private Boolean strictMode = false;
  private Boolean labelSetForNextOp = false;
  private Map<String, String> consumedLabelToMethod = new Map<String, String>();
  private Map<String, List<IEntry>> attachedDataByLabel = new Map<String, List<IEntry>>();

  private Map<Id, String> saveErrorsById = new Map<Id, String>();
  private Map<String, String> saveErrorsByExternalId = new Map<String, String>();
  private List<WhenMatcher> saveErrorMatchers = new List<WhenMatcher>();

  /**
   * Field/value matcher registered via failSaveWhen(). Kept as a value object
   * because Apex maps cannot key on (field, value) pairs directly.
   */
  private class WhenMatcher {
    private final Schema.SObjectField field;
    private final Object value;
    private final String message;

    private WhenMatcher(Schema.SObjectField field, Object value, String message) {
      this.field = field;
      this.value = value;
      this.message = message;
    }
  }
  private Map<String, List<SObject>> upsertedByLabel = new Map<String, List<SObject>>();
  private Map<String, Integer> deletedCountByLabel = new Map<String, Integer>();

  /**
   * @deprecated Direct field access will be removed in a future major version.
   * Use upsertedRecordsAt('default') instead. Reflects 'default' label only.
   */
  public List<SObject> upsertedRecords = new List<SObject>();

  /**
   * @deprecated Direct field access will be removed in a future major version.
   * Use deletedCountAt('default') instead. Reflects 'default' label only.
   */
  public Integer deletedCount = 0;

  private String CLASS_NAME = 'MockEloquent';
  private ApexEloquentException testException = ApexEloquentException.at(CLASS_NAME)
    .error('Forced Exception for Testing')
    .reason(
      'MockEloquent was configured to throw this exception to verify the error handling logic in the calling class'
    )
    .action('If this was unexpected, check the \'failOnXxx\' method in your test setup');

  /**
   * constructor
   */
  public MockEloquent() {
    this.entries = new List<IEntry>();
    this.insertCount = 0;
    this.scribe = null;
  }

  /**
   * constructor with a single Entry
   *
   * @param entry IEntry to be added
   */
  public MockEloquent(IEntry entry) {
    if (entry == null) {
      this.entries = new List<IEntry>();
    } else {
      this.entries = new List<IEntry>{ entry };
    }
    this.insertCount = 0;
    this.scribe = null;
  }

  /**
   * constructor with a list of SObjects
   *
   * @param records List<SObject> to be added
   */
  public MockEloquent(List<IEntry> entries) {
    this.entries = entries;
    this.insertCount = 0;
    this.scribe = null;
  }

  // ===========================================================================
  // label() + per-label routing (issue_42)
  // ===========================================================================

  /**
   * @inheritDoc
   */
  public IEloquent label(String label) {
    if (label == null || String.isBlank(label)) {
      ApexEloquentException.required(CLASS_NAME, 'label(String label)', 'label', label).fire();
    }
    this.currentLabel = label;
    this.labelSetForNextOp = true;
    this.strictMode = true; // sticky — once on, stays on for this MockEloquent instance
    return this;
  }

  /**
   * @inheritDoc
   * No-op in the mock: there is no real database, so access mode has no effect on captured data.
   * Unlike Eloquent (which returns a mode-switched copy), the mock returns itself so every
   * spy and assertion keeps pointing at the one instance the test holds.
   */
  public IEloquent userMode() {
    return this;
  }

  /**
   * @inheritDoc
   * No-op in the mock: there is no real database, so access mode has no effect on captured data.
   * Unlike Eloquent (which returns a mode-switched copy), the mock returns itself so every
   * spy and assertion keeps pointing at the one instance the test holds.
   */
  public IEloquent systemMode() {
    return this;
  }

  /**
   * Pre-load data for a label. Subsequent read calls tagged with that label
   * will see this data as the query source. Overwrites prior attach.
   *
   * Returns a new instance (the receiver is unmodified), like every test-setup
   * builder on this class — always use the return value.
   */
  public MockEloquent attach(String label, List<IEntry> entries) {
    if (label == null || String.isBlank(label)) {
      ApexEloquentException.required(CLASS_NAME, 'attach(String label, List<IEntry> entries)', 'label', label)
        .fire();
    }
    MockEloquent newMockEloquent = this.copy();
    newMockEloquent.attachedDataByLabel.put(label, entries == null ? new List<IEntry>() : entries);
    return newMockEloquent;
  }

  /**
   * Pre-load a single entry for a label.
   */
  public MockEloquent attach(String label, IEntry entry) {
    return this.attach(label, entry == null ? new List<IEntry>() : new List<IEntry>{ entry });
  }

  /**
   * Registers a per-record save failure for every SaveResult/UpsertResult/
   * DeleteResult-returning DML (the allOrNone overloads of doInsert / doUpdate /
   * doUpsert / doUpsertByExternalId / doDelete).
   *
   * With allOrNone = false the record's result carries success = false and the
   * given message, and the record is NOT added to the upsert spy (it was not saved).
   * With allOrNone = true the whole operation throws before anything is recorded,
   * mirroring real all-or-nothing DML.
   *
   * The target is identified by record Id — pair with MockEntry.autoId().
   * Rows reaching doUpsertByExternalId() WITHOUT an Id (the defining case for an
   * external-Id upsert) cannot be targeted here: use failSaveByExternalId() instead.
   * Failed results carry a fixed statusCode (FIELD_CUSTOM_VALIDATION_EXCEPTION;
   * DELETE_FAILED for deletes) — code branching on getStatusCode() cannot be
   * verified against the mock.
   *
   * Returns a new instance (the receiver is unmodified), like every test-setup
   * builder on this class — always use the return value.
   */
  public MockEloquent failSave(Id recordId, String errorMessage) {
    String method = 'failSave(Id recordId, String errorMessage)';
    if (recordId == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'recordId', recordId).fire();
    }
    if (String.isBlank(errorMessage)) {
      ApexEloquentException.required(CLASS_NAME, method, 'errorMessage', errorMessage).fire();
    }
    MockEloquent newMockEloquent = this.copy();
    newMockEloquent.saveErrorsById.put(recordId, errorMessage);
    return newMockEloquent;
  }

  /**
   * Registers a per-record save failure for doUpsertByExternalId(), keyed by the
   * external Id field's VALUE — the key the caller actually has. failSave(Id, ...)
   * cannot target rows that do not exist in the org yet: they carry no Salesforce
   * Id before the mock assigns one, and needing no Id is the defining situation
   * for an external-Id upsert (issue #89).
   *
   * With allOrNone = false the row's UpsertResult carries success = false and the
   * given message, and the record is NOT added to the upsert spy (it was not saved).
   * With allOrNone = true the whole operation throws before anything is recorded,
   * mirroring real all-or-nothing DML.
   *
   * Returns a new instance (the receiver is unmodified), like every test-setup
   * builder on this class — always use the return value.
   *
   * @param externalIdValue value of the external Id field identifying the failing row
   * @param errorMessage error message the failed UpsertResult carries
   * @return a new MockEloquent with the failure registered
   */
  public MockEloquent failSaveByExternalId(String externalIdValue, String errorMessage) {
    String method = 'failSaveByExternalId(String externalIdValue, String errorMessage)';
    if (String.isBlank(externalIdValue)) {
      ApexEloquentException.required(CLASS_NAME, method, 'externalIdValue', externalIdValue).fire();
    }
    if (String.isBlank(errorMessage)) {
      ApexEloquentException.required(CLASS_NAME, method, 'errorMessage', errorMessage).fire();
    }
    MockEloquent newMockEloquent = this.copy();
    newMockEloquent.saveErrorsByExternalId.put(externalIdValue, errorMessage);
    return newMockEloquent;
  }

  /**
   * Registers a per-record save failure matched by an arbitrary field value.
   * This is the targeting mechanism for rows that carry NO Salesforce Id when the
   * DML runs — above all doInsert(..., allOrNone) and the create path of
   * doUpsert(..., allOrNone), which failSave(Id, ...) can never reach (issue #80,
   * same class of hole as #89).
   *
   * Matching applies to every SaveResult/UpsertResult/DeleteResult-returning DML:
   * a row whose {@code field} equals {@code value} fails. With allOrNone = false
   * the row's result carries success = false and the given message and the record
   * is NOT recorded in the spy; with allOrNone = true the whole operation throws.
   *
   * Platform-originated rejections come first: on doUpsertByExternalId a row whose
   * key value is missing, duplicated inside the same call, or read through a token
   * of another SObject type fails for that reason, whatever failSave* registered.
   *
   * Resolution order per row: failSave (record Id) → failSaveByExternalId
   * (external-Id upsert only) → failSaveWhen matchers. The mechanism priority is
   * fixed regardless of registration order; among failSaveWhen matchers the one
   * registered first wins; re-registering the same key on failSave /
   * failSaveByExternalId overwrites the earlier message (last wins).
   *
   * Value semantics: comparison uses Apex ==, so Strings match case-insensitively
   * and numeric values match across Integer/Decimal (measured). A null value
   * matches every row where the field is unset. A matcher cannot be scoped to a
   * single DML verb — it applies to all of them. Failed results carry a fixed
   * statusCode (FIELD_CUSTOM_VALIDATION_EXCEPTION; DELETE_FAILED for deletes), so
   * code that branches on getStatusCode() cannot be verified against the mock.
   *
   * Returns a new instance (the receiver is unmodified), like every test-setup
   * builder on this class — always use the return value.
   *
   * @param field field whose value identifies the failing row
   * @param value value that marks a row as failing (compared with ==)
   * @param errorMessage error message the failed result carries
   * @return a new MockEloquent with the failure registered
   */
  public MockEloquent failSaveWhen(Schema.SObjectField field, Object value, String errorMessage) {
    String method = 'failSaveWhen(Schema.SObjectField field, Object value, String errorMessage)';
    if (field == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'field', field).fire();
    }
    if (String.isBlank(errorMessage)) {
      ApexEloquentException.required(CLASS_NAME, method, 'errorMessage', errorMessage).fire();
    }
    MockEloquent newMockEloquent = this.copy();
    newMockEloquent.saveErrorMatchers.add(new WhenMatcher(field, value, errorMessage));
    return newMockEloquent;
  }

  /**
   * Returns the query executed under a given label — the read-side counterpart of
   * upsertedRecordsAt. Pair it with `Scribe.assertCondition` to fix, in a unit test,
   * that a Usecase narrowed its query by the input it was handed.
   *
   * ```
   * mock.scribeAt('fetch').assertCondition(new InConditionClause('Id', contactIds));
   * ```
   *
   * Returns null when nothing ran under that label, so a branch that skips the query
   * can be asserted with `Assert.isNull(mock.scribeAt('fetch'))`.
   *
   * Once `.label(...)` is in use, consume-once allows a label at most one successful
   * operation, so this returns the single query for it. Without labels every read lands
   * in the 'default' bucket and several can pile up — this throws in that case and
   * points at scribesAt, rather than silently picking one.
   *
   * @param label The routing label the read ran under.
   * @return The query executed under that label, or null when none ran.
   * @throws ApexEloquentException when more than one query ran under that label.
   */
  public Scribe scribeAt(String label) {
    List<Scribe> scribes = this.scribesAt(label);
    if (scribes.isEmpty()) {
      return null;
    }
    if (scribes.size() > 1) {
      String error = 'Ambiguous query lookup';
      String reason = 'Label \'' + label + '\' recorded ' + scribes.size() + ' queries, so a single one cannot be named.';
      String action = 'Use scribesAt(\'' + label + '\') to get them in execution order, or label each read separately.';
      ApexEloquentException.at(CLASS_NAME)
        .method('scribeAt(String label)')
        .error(error)
        .reason(reason)
        .action(action)
        .param('label', label)
        .fire();
    }
    return scribes[0];
  }

  /**
   * Returns every query executed under a given label, in execution order. Returns an
   * empty list when nothing ran under that label — a branch that skips the query is a
   * normal thing to assert, not an error.
   *
   * @param label The routing label the reads ran under.
   * @return The queries in execution order; empty when none ran.
   */
  public List<Scribe> scribesAt(String label) {
    return this.scribesByLabel.containsKey(label)
      ? new List<Scribe>(this.scribesByLabel.get(label))
      : new List<Scribe>();
  }

  /**
   * Returns the most recently executed query, whatever label it ran under, or null when
   * no read has run. This is the value the deprecated `scribe` field also holds.
   *
   * @return The last executed query, or null when none ran.
   */
  public Scribe lastScribe() {
    return this.scribe;
  }

  /**
   * Records a query against its label at the moment it is issued.
   *
   * Unlike the DML spies, which record only what was saved, this records what was ASKED:
   * a read that goes on to fail — `firstOrFail` finding nothing, an unattached label — is
   * still a query the Usecase built, and that is the thing being inspected. Only failures
   * raised before the query is seen at all (`failOnGet`, a null Scribe) leave no trace.
   *
   * ⚠️ A consequence: a failed read releases its label, so retrying under the same label
   * records twice and `scribeAt` then reports the ambiguity. Use `scribesAt` there.
   *
   * @param label The routing label the read ran under.
   * @param scribe The query that was executed.
   */
  private void recordScribe(String label, Scribe scribe) {
    this.scribe = scribe;
    if (!this.scribesByLabel.containsKey(label)) {
      this.scribesByLabel.put(label, new List<Scribe>());
    }
    this.scribesByLabel.get(label).add(scribe);
  }

  /**
   * Returns the records upserted (inserted / updated / upserted) under a given label.
   * Returns empty list if no DML ran under that label.
   */
  public List<SObject> upsertedRecordsAt(String label) {
    return this.upsertedByLabel.containsKey(label) ? this.upsertedByLabel.get(label) : new List<SObject>();
  }

  /**
   * Returns the records upserted (inserted / updated / upserted) under a given
   * label, wrapped as IEntry — the symmetric counterpart of the IEntry-based DML
   * inputs (issue #86): what goes in as IEntry can be asserted as IEntry.
   *
   * @param label routing label the DML ran under
   * @return recorded records wrapped as IEntry; empty list if no DML ran under that label
   */
  public List<IEntry> upsertedEntriesAt(String label) {
    List<IEntry> entries = new List<IEntry>();
    for (SObject record : this.upsertedRecordsAt(label)) {
      entries.add(new Entry(record));
    }
    return entries;
  }

  /**
   * Returns the number of records deleted under a given label.
   * Returns 0 if no doDelete ran under that label.
   */
  public Integer deletedCountAt(String label) {
    return this.deletedCountByLabel.containsKey(label) ? this.deletedCountByLabel.get(label) : 0;
  }

  /**
   * Scopes the most recently configured failOnXxx to a label. Reads as
   * "fail on get when label is 'opp'". Same modifier pattern as repeat().
   *
   * Failures on one method form a FIFO queue per label: two failOnGet(...)
   * .whenLabel('opp') configs fire in insertion order on successive 'opp'
   * reads, and .repeat() makes a labeled failure fire on every attempt.
   *
   * Returns a new instance (the receiver is unmodified), like every test-setup
   * builder on this class — always use the return value.
   *
   * @throws ApexEloquentException if called without a preceding failOnXxx(),
   *         with a blank label, or with the reserved 'default' label (a
   *         failOnXxx without whenLabel(...) already targets 'default')
   */
  public MockEloquent whenLabel(String label) {
    String method = 'whenLabel(String label)';
    if (label == null || String.isBlank(label)) {
      ApexEloquentException.required(CLASS_NAME, method, 'label', label).fire();
    }
    if (label == DEFAULT_LABEL) {
      String reason =
        'whenLabel(\'' +
        DEFAULT_LABEL +
        '\') is redundant: a failOnXxx registered without whenLabel(...) already targets the \'' +
        DEFAULT_LABEL +
        '\' label.';
      String action = 'Drop the whenLabel(...) call, or scope the failure to a real label.';
      ApexEloquentException.invalidOperation(CLASS_NAME, method, reason).action(action).fire();
    }
    if (this.lastConfig == null) {
      String reason = 'No failOnXxx to scope. whenLabel() modifies the most recently configured failure.';
      String action = 'Call failOnGet() / failOnDoInsert() / etc. before calling whenLabel(...).';
      ApexEloquentException.invalidOperation(CLASS_NAME, method, reason).action(action).fire();
    }
    // copy() maps this.lastConfig to its clone on the new instance
    MockEloquent newMockEloquent = this.copy();
    newMockEloquent.lastConfig.label = label;
    return newMockEloquent;
  }

  /**
   * Captures the current label for routing, resets the transient label state,
   * and enforces strict-mode rules:
   *   (1) once strict mode is active, every operation must be preceded by .label(...)
   *   (2) each label allows at most one SUCCESSFUL operation per MockEloquent instance
   *       (a failed operation releases its label so the attempt can be retried)
   *
   * @param method the operation consuming the label; recorded so a consume-once
   *        violation can name what consumed the label first
   */
  private String consumeLabel(String method) {
    String label = this.currentLabel;
    Boolean wasSet = this.labelSetForNextOp;

    // reset transient state first so a caller that catches the exception
    // starts the next operation from a clean slate
    this.currentLabel = DEFAULT_LABEL;
    this.labelSetForNextOp = false;

    // lenient mode: anything goes — no enforcement, no consumed-label tracking
    if (!this.strictMode) {
      return label;
    }

    // strict mode: both rules apply
    if (!wasSet) {
      String reason = 'Strict mode is active on this MockEloquent: every operation must be preceded by .label(...).';
      String action = 'Call .label(X) before this read/DML, or use a fresh MockEloquent instance if you want lenient mode.';
      ApexEloquentException.invalidOperation(CLASS_NAME, 'label(String label) [strict mode required]', reason).action(action).fire();
    }
    if (this.consumedLabelToMethod.containsKey(label)) {
      String reason =
        'Label \'' +
        label +
        '\' was already consumed by ' +
        this.consumedLabelToMethod.get(label) +
        ' on this MockEloquent instance.';
      String action = 'A label allows at most one successful operation per MockEloquent (failed attempts may be retried). Use a different label name, or construct a fresh MockEloquent.';
      ApexEloquentException.invalidOperation(CLASS_NAME, 'label(String label) [consume-once]', reason)
        .action(action)
        .param('label', label)
        .fire();
    }
    this.consumedLabelToMethod.put(label, method);
    return label;
  }

  /**
   * Releases a label whose operation failed. consume-once guards one
   * SUCCESSFUL operation per label — a failed attempt did not fulfill the
   * label's intent, so the same label may be retried.
   *
   * Invariant: every path that reaches releaseLabel must not have recorded
   * anything in the spies yet (validate first, record last) — otherwise a
   * retried label would double-record. List DML therefore validates the whole
   * list before its first recordUpsert/recordDelete.
   */
  private void releaseLabel(String label) {
    this.consumedLabelToMethod.remove(label);
  }

  /**
   * Returns the list of entries that read operations should treat as the
   * query source for the given label. Order of precedence:
   *   1. preloaded via attach(label, ...)
   *   2. legacy MockEloquent(List<IEntry>) entries — only when label == 'default'
   *
   * A labeled read on a label that was never attached is a test-setup bug
   * (a forgotten or typo'd attach): the query would silently return an empty
   * list and the zero-row path would pass without verifying anything. In test
   * context this therefore throws instead (mirroring ApexTrace's automatic
   * Strict mode). An explicitly attached empty list remains the legitimate
   * way to declare the zero-row path — "not attached" and "attached empty"
   * are distinct states.
   */
  private List<IEntry> activeEntries(String label) {
    if (this.attachedDataByLabel.containsKey(label)) {
      return this.attachedDataByLabel.get(label);
    }
    if (label != DEFAULT_LABEL && Test.isRunningTest()) {
      List<String> attachedLabels = new List<String>(this.attachedDataByLabel.keySet());
      attachedLabels.sort();
      String reason =
        'label \'' + label + '\' has no attached entries.\n' +
        'Attached labels: [' + String.join(attachedLabels, ', ') + ']';
      String action =
        'Attach the data for this label, or if you intend to test the zero-row path, ' +
        'attach an empty list explicitly: .attach(label, new List<IEntry>())';
      ApexEloquentException.invalidOperation(CLASS_NAME, 'activeEntries(String label)', reason)
        .action(action)
        .param('label', label)
        .fire();
    }
    return label == DEFAULT_LABEL ? this.entries : new List<IEntry>();
  }

  private void recordUpsert(String label, SObject record) {
    if (label == DEFAULT_LABEL) {
      this.upsertedRecords.add(record);
    }
    if (!this.upsertedByLabel.containsKey(label)) {
      this.upsertedByLabel.put(label, new List<SObject>());
    }
    this.upsertedByLabel.get(label).add(record);
  }

  private void recordUpsertAll(String label, List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return;
    }
    if (label == DEFAULT_LABEL) {
      this.upsertedRecords.addAll(records);
    }
    if (!this.upsertedByLabel.containsKey(label)) {
      this.upsertedByLabel.put(label, new List<SObject>());
    }
    this.upsertedByLabel.get(label).addAll(records);
  }

  private void recordDelete(String label, Integer count) {
    if (label == DEFAULT_LABEL) {
      this.deletedCount += count;
    }
    Integer prev = this.deletedCountByLabel.containsKey(label) ? this.deletedCountByLabel.get(label) : 0;
    this.deletedCountByLabel.put(label, prev + count);
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> get(Scribe scribe) {
    String method = 'get(Scribe scribe)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
      }

      this.recordScribe(label, scribe);
      String soql = scribe.toSoql(); // for showing and validate SOQL
      FieldStructure fieldStructure = scribe.isAggregate()
        ? scribe.buildAggregateFieldStructure()
        : scribe.buildFieldStructure();
      List<IEntry> result = new List<IEntry>();
      for (IEntry entry : this.activeEntries(label)) {
        result.add(entry.setFieldStructure(fieldStructure));
      }
      return result;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> rawSoql(String soql) {
    String method = 'rawSoql(String soql)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (String.isBlank(soql)) {
        ApexEloquentException.required(CLASS_NAME, method, 'soql', soql).fire();
      }
      // Raw SOQL bypasses the Scribe FieldStructure pipeline, so we cannot apply
      // "select-forgotten detection" to the mocked rows. For MockEntry instances,
      // turn off skipFieldValidation so callers can read any field; non-MockEntry
      // entries pass through unchanged.
      List<IEntry> result = new List<IEntry>();
      for (IEntry entry : this.activeEntries(label)) {
        if (entry instanceof MockEntry) {
          result.add(((MockEntry) entry).withoutFieldValidation());
        } else {
          result.add(entry);
        }
      }
      return result;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<SObject> getAsSObject(Scribe scribe) {
    String method = 'getAsSObject(Scribe scribe)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
      }

      this.recordScribe(label, scribe);
      String soql = scribe.toSoql(); // for showing and validate SOQL
      List<SObject> result = new List<SObject>();
      for (IEntry entry : this.activeEntries(label)) {
        result.add(entry.getRecord());
      }
      return result;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public IEntry first(Scribe scribe) {
    String method = 'first(Scribe scribe)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
      }

      this.recordScribe(label, scribe);
      String soql = scribe.toSoql(); // for showing and validate SOQL
      // Aggregate Scribes need the aggregate FieldStructure so aliases resolve,
      // exactly as get() selects it (issue #85).
      FieldStructure fieldStructure = scribe.isAggregate()
        ? scribe.buildAggregateFieldStructure()
        : scribe.buildFieldStructure();
      List<IEntry> source = this.activeEntries(label);
      if (source.isEmpty()) {
        return null;
      }
      return source[0].setFieldStructure(fieldStructure);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public SObject firstAsSObject(Scribe scribe) {
    String method = 'firstAsSObject(Scribe scribe)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
      }

      this.recordScribe(label, scribe);
      String soql = scribe.toSoql(); // for showing and validate SOQL
      List<IEntry> source = this.activeEntries(label);
      if (source.isEmpty()) {
        return null;
      }
      return source[0].getRecord();
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public IEntry firstOrFail(Scribe scribe) {
    String method = 'firstOrFail(Scribe scribe)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
      }

      this.recordScribe(label, scribe);
      String soql = scribe.toSoql(); // for showing and validate SOQL
      // Aggregate Scribes need the aggregate FieldStructure so aliases resolve,
      // exactly as get() selects it (issue #85).
      FieldStructure fieldStructure = scribe.isAggregate()
        ? scribe.buildAggregateFieldStructure()
        : scribe.buildFieldStructure();
      List<IEntry> source = this.activeEntries(label);
      if (source.isEmpty()) {
        String error = 'No records were found for the given criteria';
        String reason = 'The query execution returned zero records';
        String action = 'Ensure the test data is correctly registered in MockEloquent';
        ApexEloquentException.at(CLASS_NAME)
          .method(method)
          .error(error)
          .reason(reason)
          .action(action)
          .param('SOQL', scribe.toSoql())
          .fire();
      }
      return source[0].setFieldStructure(fieldStructure);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public IEntry firstOrFail(Scribe scribe, Exception orFail) {
    String method = 'firstOrFail(Scribe scribe, Exception orFail)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
      }
      if (orFail == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'orFail', null).fire();
      }

      this.recordScribe(label, scribe);
      String soql = scribe.toSoql(); // for showing and validate SOQL
      // Aggregate Scribes need the aggregate FieldStructure so aliases resolve,
      // exactly as get() selects it (issue #85).
      FieldStructure fieldStructure = scribe.isAggregate()
        ? scribe.buildAggregateFieldStructure()
        : scribe.buildFieldStructure();
      List<IEntry> source = this.activeEntries(label);
      if (source.isEmpty()) {
        throw orFail;
      }
      return source[0].setFieldStructure(fieldStructure);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public SObject firstOrFailAsSObject(Scribe scribe) {
    String method = 'firstOrFailAsSObject(Scribe scribe)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
      }

      this.recordScribe(label, scribe);
      String soql = scribe.toSoql(); // for showing and validate SOQL
      List<IEntry> source = this.activeEntries(label);
      if (source.isEmpty()) {
        String error = 'No records were found for the given criteria';
        String reason = 'The query execution returned zero records';
        String action = 'Ensure the test data is correctly registered in MockEloquent';
        ApexEloquentException.at(CLASS_NAME)
          .method(method)
          .error(error)
          .reason(reason)
          .action(action)
          .param('SOQL', scribe.toSoql())
          .fire();
      }
      return source[0].getRecord();
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public SObject doInsert(SObject record) {
    String method = 'doInsert(SObject record)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', record).fire();
      }
      if (record.Id != null) {
        this.fireInsertWithIdError(method, record.Id);
      }

      record.Id = this.generateId(record);
      this.recordUpsert(label, record);
      return record;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doInsert(List<SObject> records) {
    String method = 'doInsert(List<SObject> records)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      // Validate everything BEFORE assigning any Id or recording anything: without
      // an allOrNone argument the operation is all-or-nothing, so a mid-list
      // rejection must leave no trace (real DML rolls the whole call back).
      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'insert');
        }
        if (record.Id != null) {
          this.fireInsertWithIdError(method, record.Id);
        }
      }
      for (SObject record : records) {
        record.Id = this.generateId(record);
      }
      this.recordUpsertAll(label, records);
      return records;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.SaveResult doInsert(SObject record, Boolean allOrNone) {
    String method = 'doInsert(SObject record, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      if (record.Id != null) {
        // Real Database.insert rejects records that already have an Id: throws for
        // allOrNone=true, row-level INVALID_FIELD_FOR_INSERT_UPDATE for false (measured).
        if (allOrNone == true) {
          this.fireInsertWithIdError(method, record.Id);
        }
        return buildInsertWithIdSaveResult();
      }
      String failure = this.resolveSaveFailure(record);
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'insert', record.Id, failure);
        }
        return buildFailedSaveResult(null, failure);
      }
      record.Id = this.generateId(record);
      this.recordUpsert(label, record);
      return buildSuccessSaveResult(record.Id);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.SaveResult doInsert(IEntry entry, Boolean allOrNone) {
    String method = 'doInsert(IEntry entry, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      // Mirror Eloquent: the caller's entry stays untouched — the Id lands on the
      // internal clone and is reported through the SaveResult.
      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'insert');
      }
      if (record.Id != null) {
        if (allOrNone == true) {
          this.fireInsertWithIdError(method, record.Id);
        }
        return buildInsertWithIdSaveResult();
      }
      String failure = this.resolveSaveFailure(record);
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'insert', record.Id, failure);
        }
        return buildFailedSaveResult(null, failure);
      }
      record.Id = this.generateId(record);
      this.recordUpsert(label, record);
      return buildSuccessSaveResult(record.Id);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.SaveResult> doInsert(List<SObject> records, Boolean allOrNone) {
    String method = 'doInsert(List<SObject> records, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'insert');
        }
      }
      if (allOrNone == true) {
        for (SObject record : records) {
          if (record.Id != null) {
            this.fireInsertWithIdError(method, record.Id);
          }
          String failure = this.resolveSaveFailure(record);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'insert', record.Id, failure);
          }
        }
      }
      List<Database.SaveResult> results = new List<Database.SaveResult>();
      for (SObject record : records) {
        if (record.Id != null) {
          // Reachable only with allOrNone=false: real Database.insert reports a
          // row-level INVALID_FIELD_FOR_INSERT_UPDATE and processes the other rows (measured).
          results.add(buildInsertWithIdSaveResult());
          continue;
        }
        String rowFailure = this.resolveSaveFailure(record);
        if (rowFailure != null) {
          results.add(buildFailedSaveResult(null, rowFailure));
          continue;
        }
        record.Id = this.generateId(record);
        this.recordUpsert(label, record);
        results.add(buildSuccessSaveResult(record.Id));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.SaveResult> doInsert(List<IEntry> entries, Boolean allOrNone) {
    String method = 'doInsert(List<IEntry> entries, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      // Mirror Eloquent: the caller's entries stay untouched — Ids land on the clones.
      // getRecord() is taken once per entry (MockEntry clones on every call).
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'insert');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'insert');
        }
        records.add(record);
      }
      if (allOrNone == true) {
        // Pre-pass: real all-or-nothing DML rolls everything back, so the mock
        // must throw BEFORE any Id is assigned or any row is recorded.
        for (SObject record : records) {
          if (record.Id != null) {
            this.fireInsertWithIdError(method, record.Id);
          }
          String failure = this.resolveSaveFailure(record);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'insert', record.Id, failure);
          }
        }
      }
      List<Database.SaveResult> results = new List<Database.SaveResult>();
      for (SObject record : records) {
        if (record.Id != null) {
          results.add(buildInsertWithIdSaveResult());
          continue;
        }
        String rowFailure = this.resolveSaveFailure(record);
        if (rowFailure != null) {
          results.add(buildFailedSaveResult(null, rowFailure));
          continue;
        }
        record.Id = this.generateId(record);
        this.recordUpsert(label, record);
        results.add(buildSuccessSaveResult(record.Id));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public IEntry doInsert(IEntry entry) {
    String method = 'doInsert(IEntry entry)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }

      // Mirror Eloquent: the caller's entry stays untouched and the Id is carried
      // by the returned Entry, exactly as Database.insert writes it back to the
      // clone that Eloquent wraps into its return value.
      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'insert');
      }
      if (record.Id != null) {
        this.fireInsertWithIdError(method, record.Id);
      }
      record.Id = this.generateId(record);
      this.recordUpsert(label, record);
      return new Entry(record);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doInsert(List<IEntry> entries) {
    String method = 'doInsert(List<IEntry> entries)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }

      // Validate everything BEFORE assigning any Id or recording anything: without
      // an allOrNone argument the operation is all-or-nothing, so a mid-list
      // rejection must leave no trace (real DML rolls the whole call back).
      // getRecord() is taken once per entry (MockEntry clones on every call).
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'insert');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'insert');
        }
        if (record.Id != null) {
          this.fireInsertWithIdError(method, record.Id);
        }
        records.add(record);
      }
      // Mirror Eloquent: return fresh Entry instances carrying the Ids instead of
      // mutating and aliasing the caller's entries.
      List<IEntry> insertedEntries = new List<IEntry>();
      for (SObject record : records) {
        record.Id = this.generateId(record);
        this.recordUpsert(label, record);
        insertedEntries.add(new Entry(record));
      }
      return insertedEntries;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public SObject doUpdate(SObject record) {
    String method = 'doUpdate(SObject record)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (record.Id == null) {
        this.fireUpdateWithoutIdError(method);
      }

      this.recordUpsert(label, record);
      return record;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpdate(IEntry entry) {
    String method = 'doUpdate(IEntry entry)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'update');
      }
      if (record.Id == null) {
        this.fireUpdateWithoutIdError(method);
      }
      this.recordUpsert(label, record);
      // Mirror Eloquent: return a fresh Entry wrapping the updated clone instead of
      // aliasing the caller's entry.
      return new Entry(record);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpdate(List<SObject> records) {
    String method = 'doUpdate(List<SObject> records)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }

      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'update');
        }
        if (record.Id == null) {
          this.fireUpdateWithoutIdError(method);
        }
      }
      this.recordUpsertAll(label, records);
      return records;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpdate(List<IEntry> entries) {
    String method = 'doUpdate(List<IEntry> entries)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }

      // Validate everything BEFORE recording anything: without an allOrNone
      // argument the operation is all-or-nothing, so a mid-list rejection must
      // leave no trace (real DML rolls the whole call back).
      // getRecord() is taken once per entry (MockEntry clones on every call).
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'update');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'update');
        }
        if (record.Id == null) {
          this.fireUpdateWithoutIdError(method);
        }
        records.add(record);
      }
      // Mirror Eloquent: return fresh Entry instances wrapping the updated clones
      // instead of aliasing the caller's entries.
      List<IEntry> updatedEntries = new List<IEntry>();
      for (SObject record : records) {
        this.recordUpsert(label, record);
        updatedEntries.add(new Entry(record));
      }

      return updatedEntries;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.SaveResult doUpdate(SObject record, Boolean allOrNone) {
    String method = 'doUpdate(SObject record, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      if (record.Id == null) {
        // Real Database.update throws for allOrNone=true and returns a row-level
        // MISSING_ARGUMENT failure for allOrNone=false.
        if (allOrNone == true) {
          this.fireUpdateWithoutIdError(method);
        }
        return buildMissingIdSaveResult();
      }
      String failure = this.resolveSaveFailure(record);
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'update', record.Id, failure);
        }
        return buildFailedSaveResult(record.Id, failure);
      }
      this.recordUpsert(label, record);
      return buildSuccessSaveResult(record.Id);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.SaveResult doUpdate(IEntry entry, Boolean allOrNone) {
    String method = 'doUpdate(IEntry entry, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'update');
      }
      if (record.Id == null) {
        // Real Database.update throws for allOrNone=true and returns a row-level
        // MISSING_ARGUMENT failure for allOrNone=false.
        if (allOrNone == true) {
          this.fireUpdateWithoutIdError(method);
        }
        return buildMissingIdSaveResult();
      }
      String failure = this.resolveSaveFailure(record);
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'update', record.Id, failure);
        }
        return buildFailedSaveResult(record.Id, failure);
      }
      this.recordUpsert(label, record);
      return buildSuccessSaveResult(record.Id);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.SaveResult> doUpdate(List<SObject> records, Boolean allOrNone) {
    String method = 'doUpdate(List<SObject> records, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'update');
        }
      }
      if (allOrNone == true) {
        for (SObject record : records) {
          if (record.Id == null) {
            this.fireUpdateWithoutIdError(method);
          }
          String failure = this.resolveSaveFailure(record);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'update', record.Id, failure);
          }
        }
      }
      List<Database.SaveResult> results = new List<Database.SaveResult>();
      for (SObject record : records) {
        if (record.Id == null) {
          // Reachable only with allOrNone=false: real Database.update reports a
          // row-level MISSING_ARGUMENT failure and processes the other rows.
          results.add(buildMissingIdSaveResult());
          continue;
        }
        String rowFailure = this.resolveSaveFailure(record);
        if (rowFailure != null) {
          results.add(buildFailedSaveResult(record.Id, rowFailure));
          continue;
        }
        this.recordUpsert(label, record);
        results.add(buildSuccessSaveResult(record.Id));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.SaveResult> doUpdate(List<IEntry> entries, Boolean allOrNone) {
    String method = 'doUpdate(List<IEntry> entries, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      // getRecord() is taken once per entry (MockEntry clones on every call).
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'update');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'update');
        }
        records.add(record);
      }
      if (allOrNone == true) {
        for (SObject record : records) {
          if (record.Id == null) {
            this.fireUpdateWithoutIdError(method);
          }
          String failure = this.resolveSaveFailure(record);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'update', record.Id, failure);
          }
        }
      }
      List<Database.SaveResult> results = new List<Database.SaveResult>();
      for (SObject record : records) {
        if (record.Id == null) {
          // Reachable only with allOrNone=false: real Database.update reports a
          // row-level MISSING_ARGUMENT failure and processes the other rows.
          results.add(buildMissingIdSaveResult());
          continue;
        }
        String rowFailure = this.resolveSaveFailure(record);
        if (rowFailure != null) {
          results.add(buildFailedSaveResult(record.Id, rowFailure));
          continue;
        }
        this.recordUpsert(label, record);
        results.add(buildSuccessSaveResult(record.Id));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  private Boolean isSaveFailure(SObject record) {
    return record != null && record.Id != null && this.saveErrorsById.containsKey(record.Id);
  }

  /**
   * Fire the unified null-element error for list DML. Real Database DML rejects
   * lists containing null elements with a ListException before processing any row
   * (measured on API v67.0), so the mock fails fast the same way.
   *
   * @param method calling method signature
   * @param operation DML verb for the error headline
   */
  private void fireNullElementError(String method, String operation) {
    String error = 'Failed to ' + operation + ' operation';
    String reason = 'A null record was passed (as the argument, or as an element of the list), which real Database DML rejects before processing any row';
    String action = 'Ensure the record passed to the DML method is not null and, for list DML, that the list contains no null elements';
    ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
  }

  /**
   * Throws the all-or-nothing failure for a registered per-record error,
   * regardless of which failSave variant registered it.
   *
   * @param method calling method signature
   * @param operation DML verb for the error headline (insert / update / upsert / delete)
   * @param recordId Id of the failing record (null for not-yet-created rows)
   * @param failureMessage registered error message
   */
  private void fireAllOrNoneError(String method, String operation, Id recordId, String failureMessage) {
    String error = 'Failed to ' + operation + ' operation';
    String reason = 'DML failed with: ' + failureMessage;
    String action = 'This failure was registered via failSave() / failSaveByExternalId() / failSaveWhen(). With allOrNone = true the whole operation throws.';
    ApexEloquentException.at(CLASS_NAME)
      .method(method)
      .error(error)
      .reason(reason)
      .action(action)
      .param('recordId', recordId)
      .fire();
  }

  /**
   * Resolves a failure registered via failSaveWhen() by comparing the matcher's
   * field value against the record. A matcher whose field belongs to a different
   * SObjectType simply does not match (multi-object tests register matchers for
   * several types on one mock).
   *
   * @param record record about to be saved
   * @return the registered error message, or null when no matcher applies
   */
  private String resolveWhenFailure(SObject record) {
    for (WhenMatcher matcher : this.saveErrorMatchers) {
      Object actual;
      try {
        actual = record.get(matcher.field);
      } catch (SObjectException e) {
        // Field tokens carry their owning SObjectType (measured: "Account.Name does
        // not belong to SObject type Contact"), so a matcher registered for another
        // object lands here and simply does not match. Same-named fields cannot
        // misfire — the token, not the name, is what gets resolved.
        continue;
      }
      if (actual == matcher.value) {
        return matcher.message;
      }
    }
    return null;
  }

  /**
   * Result of reading the external Id value off a record: either the value, or the
   * row-level failure message the platform reports when the field token does not
   * apply to that record's type.
   */
  private class ExternalIdRead {
    private Object value;
    private String failure;
  }

  /**
   * Reads the external Id value, mirroring how the platform treats a field token
   * from another SObject type: measured on API v67.0, that is NOT an exception but
   * a row-level failure — CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, "Expected field
   * from SObject type Account but found Name from Product2". (A token whose flags
   * make it unusable as a key is a different case and throws; see
   * validateExternalIdField.)
   *
   * @param record record being upserted
   * @param externalIdField field token the upsert routes on
   * @return the value, or the row-level failure message when the token does not apply
   */
  private static ExternalIdRead readExternalId(SObject record, Schema.SObjectField externalIdField) {
    ExternalIdRead read = new ExternalIdRead();
    try {
      read.value = record.get(externalIdField);
    } catch (SObjectException e) {
      Schema.DescribeFieldResult fieldDescribe = externalIdField.getDescribe();
      read.failure =
        'Expected field from SObject type ' +
        record.getSObjectType().getDescribe().getName() +
        ' but found ' +
        fieldDescribe.getName() +
        ' from ' +
        fieldDescribe.getSObjectType().getDescribe().getName();
    }
    return read;
  }

  /**
   * Collects the external Id values that appear on more than one row of the same
   * call. Real Database.upsert rejects every row sharing a value (measured:
   * DUPLICATE_VALUE row failures with allOrNone = false, DmlException with true),
   * while rows with unique values still succeed.
   *
   * @param records rows about to be upserted
   * @param externalIdField field token the upsert routes on
   * @return lowercased values that occur more than once (empty when none do)
   */
  private static Set<String> findDuplicateExternalIds(List<SObject> records, Schema.SObjectField externalIdField) {
    Set<String> seen = new Set<String>();
    Set<String> duplicates = new Set<String>();
    for (SObject record : records) {
      ExternalIdRead read = readExternalId(record, externalIdField);
      if (read.failure != null || read.value == null) {
        continue;
      }
      // Matching is case-SENSITIVE: measured on API v67.0, rows named 'R5Case' and
      // 'r5case' both succeed, while two identical values collide. (The platform
      // lowercases the value in the message for external-Id fields only — see
      // duplicateMessage — but that is formatting, not the matching rule.)
      String key = String.valueOf(read.value);
      if (!seen.add(key)) {
        duplicates.add(key);
      }
    }
    return duplicates;
  }

  /**
   * Formats the duplicate-key message the platform reports. Measured on API v67.0:
   * an external-Id field reports the value lowercased ("...: r4-dupx" for 'R4-DUPX'),
   * a standard indexed field reports it as-is ("...: R5MsgA").
   *
   * @param value the duplicated key value
   * @param externalIdField field the upsert routes on
   * @return the platform's message for this row
   */
  private static String duplicateMessage(Object value, Schema.SObjectField externalIdField) {
    String raw = String.valueOf(value);
    String shown = externalIdField.getDescribe().isExternalId() ? raw.toLowerCase() : raw;
    return 'Duplicate external id specified: ' + shown;
  }

  /**
   * Rejects an externalIdField that real Database.upsert cannot route on.
   * Measured on API v67.0: a field that is neither an external Id nor a standard
   * indexed (idLookup) field throws SObjectException "Invalid field for upsert,
   * must be an External Id custom or standard indexed field". Without this guard
   * the mock upserts happily and the test stays green while production rejects
   * the call.
   *
   * @param method calling method signature
   * @param externalIdField field the upsert routes on
   */
  private void validateExternalIdField(String method, Schema.SObjectField externalIdField) {
    Schema.DescribeFieldResult fieldDescribe = externalIdField.getDescribe();
    if (fieldDescribe.isExternalId() || fieldDescribe.isIdLookup()) {
      return;
    }
    String error = 'Failed to upsert operation';
    String reason =
      'Invalid field for upsert, must be an External Id custom or standard indexed field: ' +
      fieldDescribe.getName();
    String action = 'Mark the field as an External Id, or pass one that already is';
    ApexEloquentException.at(CLASS_NAME)
      .method(method)
      .error(error)
      .reason(reason)
      .action(action)
      .param('externalIdField', fieldDescribe.getName())
      .fire();
  }

  /**
   * Resolves the registered failure message for a SaveResult/DeleteResult row:
   * failSave() registrations (record Id) first, then failSaveWhen() matchers.
   *
   * @param record record about to be saved or deleted
   * @return the registered error message, or null when the row should succeed
   */
  private String resolveSaveFailure(SObject record) {
    if (this.isSaveFailure(record)) {
      return this.saveErrorsById.get(record.Id);
    }
    return this.resolveWhenFailure(record);
  }

  /**
   * Resolves the failure message for an external-Id upsert row, in the order the
   * platform itself applies: failSave() registrations (record Id), then the
   * platform-originated rejections (field token from another SObject type, missing
   * key value, duplicate key inside the call), then failSaveByExternalId()
   * registrations (the external Id field's value — the only key a caller has for
   * rows that do not exist yet, issue #89), then failSaveWhen() matchers.
   *
   * @param record record about to be upserted
   * @param externalIdField external Id field the upsert routes on
   * @param duplicateExternalIds key values that occur on more than one row of this call
   * @return the failure message, or null when the row should succeed
   */
  private String resolveUpsertFailure(
    SObject record,
    Schema.SObjectField externalIdField,
    Set<String> duplicateExternalIds
  ) {
    if (this.isSaveFailure(record)) {
      return this.saveErrorsById.get(record.Id);
    }
    ExternalIdRead read = readExternalId(record, externalIdField);
    if (read.failure != null) {
      return read.failure;
    }
    // Measured: a row whose key field is empty fails with MISSING_ARGUMENT
    // "<Field> not specified" — for external-Id fields and standard indexed fields
    // alike. Upserting BY Id is the exception: a null Id is the create path.
    String keyFieldName = externalIdField.getDescribe().getName();
    if (read.value == null && keyFieldName != 'Id') {
      return keyFieldName + ' not specified';
    }
    if (read.value != null && duplicateExternalIds.contains(String.valueOf(read.value))) {
      // Measured: rows sharing a key value inside one call all fail with DUPLICATE_VALUE.
      return duplicateMessage(read.value, externalIdField);
    }
    Object externalIdValue = read.value;
    if (externalIdValue != null && this.saveErrorsByExternalId.containsKey(String.valueOf(externalIdValue))) {
      return this.saveErrorsByExternalId.get(String.valueOf(externalIdValue));
    }
    return this.resolveWhenFailure(record);
  }

  /**
   * Build the failed SaveResult a registered per-record failure produces with
   * allOrNone = false.
   *
   * @param recordId Id of the failing record (null for not-yet-created rows)
   * @param failureMessage registered error message
   * @return failed SaveResult carrying the message
   */
  private static Database.SaveResult buildFailedSaveResult(Id recordId, String failureMessage) {
    Map<String, Object> payload = new Map<String, Object>{
      'success' => false,
      'id' => recordId,
      'errors' => new List<Object>{
        new Map<String, Object>{ 'message' => failureMessage, 'statusCode' => 'FIELD_CUSTOM_VALIDATION_EXCEPTION' }
      }
    };
    return (Database.SaveResult) JSON.deserialize(JSON.serialize(payload), Database.SaveResult.class);
  }

  /**
   * Build the failed SaveResult that real Database.insert returns for a record
   * that already has an Id when allOrNone is false (measured on API v67.0).
   *
   * @return failed SaveResult carrying the INVALID_FIELD_FOR_INSERT_UPDATE error
   */
  private static Database.SaveResult buildInsertWithIdSaveResult() {
    String payload = '{"success":false,"errors":[{"message":"cannot specify Id in an insert call","statusCode":"INVALID_FIELD_FOR_INSERT_UPDATE"}]}';
    return (Database.SaveResult) JSON.deserialize(payload, Database.SaveResult.class);
  }

  /**
   * Build the successful DeleteResult for a deleted row.
   *
   * @param recordId Id of the deleted record
   * @return successful DeleteResult
   */
  private static Database.DeleteResult buildSuccessDeleteResult(Id recordId) {
    String idPart = recordId == null ? '' : '"id":"' + recordId + '",';
    String payload = '{"success":true,' + idPart + '"errors":[]}';
    return (Database.DeleteResult) JSON.deserialize(payload, Database.DeleteResult.class);
  }

  /**
   * Build the failed DeleteResult a registered per-record failure produces with
   * allOrNone = false.
   *
   * @param recordId Id of the failing record
   * @param failureMessage registered error message
   * @return failed DeleteResult carrying the message
   */
  private static Database.DeleteResult buildFailedDeleteResult(Id recordId, String failureMessage) {
    Map<String, Object> payload = new Map<String, Object>{
      'success' => false,
      'id' => recordId,
      'errors' => new List<Object>{
        new Map<String, Object>{ 'message' => failureMessage, 'statusCode' => 'DELETE_FAILED' }
      }
    };
    return (Database.DeleteResult) JSON.deserialize(JSON.serialize(payload), Database.DeleteResult.class);
  }

  private static Database.SaveResult buildSuccessSaveResult(Id recordId) {
    String idPart = recordId == null ? '' : '"id":"' + recordId + '",';
    String payload = '{"success":true,' + idPart + '"errors":[]}';
    return (Database.SaveResult) JSON.deserialize(payload, Database.SaveResult.class);
  }

  /**
   * Build the failed SaveResult that real Database.update returns for a record
   * without an Id when allOrNone is false (row-level MISSING_ARGUMENT error).
   *
   * @return failed SaveResult carrying the MISSING_ARGUMENT error
   */
  private static Database.SaveResult buildMissingIdSaveResult() {
    String payload = '{"success":false,"errors":[{"message":"Id not specified in an update call","statusCode":"MISSING_ARGUMENT"}]}';
    return (Database.SaveResult) JSON.deserialize(payload, Database.SaveResult.class);
  }

  /**
   * Fire the mock counterpart of the platform error thrown when a record that
   * already has an Id is passed to Database.insert (INVALID_FIELD_FOR_INSERT_UPDATE).
   *
   * @param method calling method signature
   * @param recordId Id found on the record
   */
  private void fireInsertWithIdError(String method, Id recordId) {
    String error = 'Failed to insert operation';
    String reason = 'cannot specify Id in an insert call: real Database.insert throws INVALID_FIELD_FOR_INSERT_UPDATE for records that already have an Id';
    String action = 'Remove the Id from the record, or use doUpdate / doUpsert instead';
    ApexEloquentException.at(CLASS_NAME)
      .method(method)
      .error(error)
      .reason(reason)
      .action(action)
      .param('recordId', recordId)
      .fire();
  }

  /**
   * Fire the mock counterpart of the platform error thrown when a record
   * without an Id is passed to Database.update (MISSING_ARGUMENT).
   *
   * @param method calling method signature
   */
  private void fireUpdateWithoutIdError(String method) {
    String error = 'Failed to update operation';
    String reason = 'Id not specified in an update call: real Database.update throws MISSING_ARGUMENT for records without an Id';
    String action = 'Set the Id on the record before updating, or use doInsert / doUpsert instead';
    ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
  }

  /**
   * Fire the mock counterpart of the platform error thrown when a record
   * without an Id is passed to Database.delete (invalid ID: null).
   *
   * @param method calling method signature
   */
  private void fireDeleteWithoutIdError(String method) {
    String error = 'Failed to delete operation';
    String reason = 'invalid Id: null — real Database.delete throws for records without an Id';
    String action = 'Set the Id on the record before deleting';
    ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
  }

  /**
   * @inheritDoc
   */
  public SObject doUpsert(SObject record) {
    String method = 'doUpsert(SObject record)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }

      if (record.Id == null) {
        record.Id = this.generateId(record);
      }
      this.recordUpsert(label, record);
      return record;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpsert(IEntry entry) {
    String method = 'doUpsert(IEntry entry)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }

      // Mirror Eloquent: the caller's entry stays untouched and the Id is carried
      // by the returned Entry, exactly as Database.upsert writes it back to the
      // clone that Eloquent wraps into its return value.
      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'upsert');
      }
      if (record.Id == null) {
        record.Id = this.generateId(record);
      }
      this.recordUpsert(label, record);
      return new Entry(record);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpsert(List<SObject> records) {
    String method = 'doUpsert(List<SObject> records)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }

      // Validate everything BEFORE assigning any Id or recording anything: without
      // an allOrNone argument the operation is all-or-nothing, so a mid-list
      // rejection must leave no trace (real DML rolls the whole call back).
      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'upsert');
        }
      }
      for (SObject record : records) {
        if (record.Id == null) {
          record.Id = this.generateId(record);
        }
      }
      for (SObject record : records) {
        this.recordUpsert(label, record);
      }
      return records;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpsert(List<IEntry> entries) {
    String method = 'doUpsert(List<IEntry> entries)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }

      // Validate everything BEFORE assigning any Id or recording anything: without
      // an allOrNone argument the operation is all-or-nothing, so a mid-list
      // rejection must leave no trace (real DML rolls the whole call back).
      // getRecord() is taken once per entry (MockEntry clones on every call).
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'upsert');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'upsert');
        }
        records.add(record);
      }
      // Mirror Eloquent: return fresh Entry instances carrying the Ids instead of
      // mutating and aliasing the caller's entries.
      for (SObject record : records) {
        if (record.Id == null) {
          record.Id = this.generateId(record);
        }
      }
      List<IEntry> upsertedEntries = new List<IEntry>();
      for (SObject record : records) {
        this.recordUpsert(label, record);
        upsertedEntries.add(new Entry(record));
      }
      return upsertedEntries;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.UpsertResult doUpsert(SObject record, Boolean allOrNone) {
    String method = 'doUpsert(SObject record, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      String failure = this.resolveSaveFailure(record);
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'upsert', record.Id, failure);
        }
        return this.buildFailedUpsertResult(record.Id, failure);
      }
      Boolean isCreated = record.Id == null;
      if (isCreated) {
        record.Id = this.generateId(record);
      }
      this.recordUpsert(label, record);
      return buildSuccessUpsertResult(record.Id, isCreated);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.UpsertResult doUpsert(IEntry entry, Boolean allOrNone) {
    String method = 'doUpsert(IEntry entry, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      // Mirror Eloquent: the caller's entry stays untouched — a generated Id lands
      // on the internal clone and is reported through the UpsertResult.
      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'upsert');
      }
      String failure = this.resolveSaveFailure(record);
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'upsert', record.Id, failure);
        }
        return this.buildFailedUpsertResult(record.Id, failure);
      }
      Boolean isCreated = record.Id == null;
      if (isCreated) {
        record.Id = this.generateId(record);
      }
      this.recordUpsert(label, record);
      return buildSuccessUpsertResult(record.Id, isCreated);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.UpsertResult> doUpsert(List<SObject> records, Boolean allOrNone) {
    String method = 'doUpsert(List<SObject> records, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'upsert');
        }
      }
      if (allOrNone == true) {
        // Pre-pass: real all-or-nothing DML rolls everything back, so the mock
        // must throw BEFORE any Id is assigned or any row is recorded.
        for (SObject record : records) {
          String failure = this.resolveSaveFailure(record);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'upsert', record.Id, failure);
          }
        }
      }
      List<Database.UpsertResult> results = new List<Database.UpsertResult>();
      for (SObject record : records) {
        String failure = this.resolveSaveFailure(record);
        if (failure != null) {
          results.add(this.buildFailedUpsertResult(record.Id, failure));
          continue;
        }
        Boolean isCreated = record.Id == null;
        if (isCreated) {
          record.Id = this.generateId(record);
        }
        this.recordUpsert(label, record);
        results.add(buildSuccessUpsertResult(record.Id, isCreated));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.UpsertResult> doUpsert(List<IEntry> entries, Boolean allOrNone) {
    String method = 'doUpsert(List<IEntry> entries, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      // Mirror Eloquent: the caller's entries stay untouched — Ids land on the clones.
      // getRecord() is taken once per entry (MockEntry clones on every call).
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'upsert');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'upsert');
        }
        records.add(record);
      }
      if (allOrNone == true) {
        // Pre-pass: real all-or-nothing DML rolls everything back, so the mock
        // must throw BEFORE any Id is assigned or any row is recorded.
        for (SObject record : records) {
          String failure = this.resolveSaveFailure(record);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'upsert', record.Id, failure);
          }
        }
      }
      List<Database.UpsertResult> results = new List<Database.UpsertResult>();
      for (SObject record : records) {
        String failure = this.resolveSaveFailure(record);
        if (failure != null) {
          results.add(this.buildFailedUpsertResult(record.Id, failure));
          continue;
        }
        Boolean isCreated = record.Id == null;
        if (isCreated) {
          record.Id = this.generateId(record);
        }
        this.recordUpsert(label, record);
        results.add(buildSuccessUpsertResult(record.Id, isCreated));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.UpsertResult doUpsertByExternalId(
    SObject record,
    Schema.SObjectField externalIdField,
    Boolean allOrNone
  ) {
    String method = 'doUpsertByExternalId(SObject record, Schema.SObjectField externalIdField, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }
      if (externalIdField == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'externalIdField', null).fire();
      }
      this.validateExternalIdField(method, externalIdField);

      String failure = this.resolveUpsertFailure(record, externalIdField, new Set<String>());
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'upsert', record.Id, failure);
        }
        return this.buildFailedUpsertResult(record.Id, failure);
      }
      Boolean isCreated = record.Id == null;
      if (isCreated) {
        record.Id = this.generateId(record);
      }
      this.recordUpsert(label, record);
      return buildSuccessUpsertResult(record.Id, isCreated);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.UpsertResult doUpsertByExternalId(
    IEntry entry,
    Schema.SObjectField externalIdField,
    Boolean allOrNone
  ) {
    String method = 'doUpsertByExternalId(IEntry entry, Schema.SObjectField externalIdField, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }
      if (externalIdField == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'externalIdField', null).fire();
      }
      this.validateExternalIdField(method, externalIdField);

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'upsert');
      }
      String failure = this.resolveUpsertFailure(record, externalIdField, new Set<String>());
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'upsert', record.Id, failure);
        }
        return this.buildFailedUpsertResult(record.Id, failure);
      }
      Boolean isCreated = record.Id == null;
      if (isCreated) {
        // Mirror Eloquent: the Id is reported through the UpsertResult, never
        // written back into the caller's entry (Database.upsert writes to the clone).
        record.Id = this.generateId(record);
      }
      this.recordUpsert(label, record);
      return buildSuccessUpsertResult(record.Id, isCreated);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.UpsertResult> doUpsertByExternalId(
    List<SObject> records,
    Schema.SObjectField externalIdField,
    Boolean allOrNone
  ) {
    String method = 'doUpsertByExternalId(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }
      if (externalIdField == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'externalIdField', null).fire();
      }
      this.validateExternalIdField(method, externalIdField);

      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'upsert');
        }
      }
      Set<String> duplicateExternalIds = findDuplicateExternalIds(records, externalIdField);
      if (allOrNone == true) {
        // Pre-pass: real all-or-nothing DML rolls everything back, so the mock
        // must throw BEFORE any Id is assigned or any row is recorded.
        for (SObject record : records) {
          String failure = this.resolveUpsertFailure(record, externalIdField, duplicateExternalIds);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'upsert', record.Id, failure);
          }
        }
      }
      List<Database.UpsertResult> results = new List<Database.UpsertResult>();
      for (SObject record : records) {
        String failure = this.resolveUpsertFailure(record, externalIdField, duplicateExternalIds);
        if (failure != null) {
          results.add(this.buildFailedUpsertResult(record.Id, failure));
          continue;
        }
        Boolean isCreated = record.Id == null;
        if (isCreated) {
          record.Id = this.generateId(record);
        }
        this.recordUpsert(label, record);
        results.add(buildSuccessUpsertResult(record.Id, isCreated));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.UpsertResult> doUpsertByExternalId(
    List<IEntry> entries,
    Schema.SObjectField externalIdField,
    Boolean allOrNone
  ) {
    String method = 'doUpsertByExternalId(List<IEntry> entries, Schema.SObjectField externalIdField, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }
      if (externalIdField == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'externalIdField', null).fire();
      }
      this.validateExternalIdField(method, externalIdField);

      // Mirror Eloquent: the Id is reported through the UpsertResult, never written
      // back into the caller's entries (Database.upsert writes to the clones).
      // getRecord() is taken once per entry (MockEntry clones on every call).
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'upsert');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'upsert');
        }
        records.add(record);
      }
      Set<String> duplicateExternalIds = findDuplicateExternalIds(records, externalIdField);
      if (allOrNone == true) {
        // Pre-pass: real all-or-nothing DML rolls everything back, so the mock
        // must throw BEFORE any Id is assigned or any row is recorded.
        for (SObject record : records) {
          String failure = this.resolveUpsertFailure(record, externalIdField, duplicateExternalIds);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'upsert', record.Id, failure);
          }
        }
      }
      List<Database.UpsertResult> results = new List<Database.UpsertResult>();
      for (SObject record : records) {
        String failure = this.resolveUpsertFailure(record, externalIdField, duplicateExternalIds);
        if (failure != null) {
          results.add(this.buildFailedUpsertResult(record.Id, failure));
          continue;
        }
        Boolean isCreated = record.Id == null;
        if (isCreated) {
          record.Id = this.generateId(record);
        }
        this.recordUpsert(label, record);
        results.add(buildSuccessUpsertResult(record.Id, isCreated));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  private Database.UpsertResult buildFailedUpsertResult(Id recordId, String failureMessage) {
    Map<String, Object> payload = new Map<String, Object>{
      'success' => false,
      'created' => false,
      'id' => recordId,
      'errors' => new List<Object>{
        new Map<String, Object>{ 'message' => failureMessage, 'statusCode' => upsertStatusCodeFor(failureMessage) }
      }
    };
    return (Database.UpsertResult) JSON.deserialize(JSON.serialize(payload), Database.UpsertResult.class);
  }

  /**
   * Picks the statusCode the platform pairs with a failure message. The three
   * platform-originated rejections the mock reproduces carry their measured codes
   * (API v67.0) so that code branching on getStatusCode() behaves as in production;
   * failures registered through failSave* keep the generic validation code.
   *
   * @param failureMessage message the failed row carries
   * @return matching StatusCode name
   */
  private static String upsertStatusCodeFor(String failureMessage) {
    if (failureMessage != null) {
      if (failureMessage.startsWith('Duplicate external id specified:')) {
        return 'DUPLICATE_VALUE';
      }
      if (failureMessage.startsWith('Expected field from SObject type ')) {
        return 'CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY';
      }
      if (failureMessage.endsWith(' not specified')) {
        return 'MISSING_ARGUMENT';
      }
    }
    return 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
  }

  private static Database.UpsertResult buildSuccessUpsertResult(Id recordId, Boolean isCreated) {
    String idPart = recordId == null ? '' : '"id":"' + recordId + '",';
    String payload = '{"success":true,"created":' + isCreated + ',' + idPart + '"errors":[]}';
    return (Database.UpsertResult) JSON.deserialize(payload, Database.UpsertResult.class);
  }

  /**
   * @inheritDoc
   */
  public void doDelete(SObject record) {
    String method = 'doDelete(SObject record)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (record.Id == null) {
        this.fireDeleteWithoutIdError(method);
      }

      this.recordDelete(label, 1);
      return;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public void doDelete(IEntry entry) {
    String method = 'doDelete(IEntry entry)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      SObject deleteTarget = entry.getRecord();
      if (deleteTarget == null || deleteTarget.Id == null) {
        this.fireDeleteWithoutIdError(method);
      }

      this.recordDelete(label, 1);
      return;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<SObject> records) {
    String method = 'doDelete(List<SObject> records)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
        if (record.Id == null) {
          this.fireDeleteWithoutIdError(method);
        }
      }

      this.recordDelete(label, records.size());
      return;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<IEntry> entries) {
    String method = 'doDelete(List<IEntry> entries)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'delete');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
        if (record.Id == null) {
          this.fireDeleteWithoutIdError(method);
        }
      }

      this.recordDelete(label, entries.size());
      return;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.DeleteResult doDelete(SObject record, Boolean allOrNone) {
    String method = 'doDelete(SObject record, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }
      // Real Database.delete throws for records without an Id even with
      // allOrNone=false (measured: ListException before any row processing).
      if (record.Id == null) {
        this.fireDeleteWithoutIdError(method);
      }

      String failure = this.resolveSaveFailure(record);
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'delete', record.Id, failure);
        }
        return buildFailedDeleteResult(record.Id, failure);
      }
      this.recordDelete(label, 1);
      return buildSuccessDeleteResult(record.Id);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.DeleteResult doDelete(IEntry entry, Boolean allOrNone) {
    String method = 'doDelete(IEntry entry, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }
      SObject record = entry.getRecord();
      if (record == null || record.Id == null) {
        this.fireDeleteWithoutIdError(method);
      }

      String failure = this.resolveSaveFailure(record);
      if (failure != null) {
        if (allOrNone == true) {
          this.fireAllOrNoneError(method, 'delete', record.Id, failure);
        }
        return buildFailedDeleteResult(record.Id, failure);
      }
      this.recordDelete(label, 1);
      return buildSuccessDeleteResult(record.Id);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone) {
    String method = 'doDelete(List<SObject> records, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }
      // Real Database.delete throws for records without an Id even with
      // allOrNone=false (measured: ListException before any row processing).
      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
        if (record.Id == null) {
          this.fireDeleteWithoutIdError(method);
        }
      }

      if (allOrNone == true) {
        for (SObject record : records) {
          String failure = this.resolveSaveFailure(record);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'delete', record.Id, failure);
          }
        }
      }
      List<Database.DeleteResult> results = new List<Database.DeleteResult>();
      for (SObject record : records) {
        String rowFailure = this.resolveSaveFailure(record);
        if (rowFailure != null) {
          results.add(buildFailedDeleteResult(record.Id, rowFailure));
          continue;
        }
        this.recordDelete(label, 1);
        results.add(buildSuccessDeleteResult(record.Id));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.DeleteResult> doDelete(List<IEntry> entries, Boolean allOrNone) {
    String method = 'doDelete(List<IEntry> entries, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      this.handleErrorQueue(method, label);
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }
      // getRecord() is taken once per entry (MockEntry clones on every call).
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'delete');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
        if (record.Id == null) {
          this.fireDeleteWithoutIdError(method);
        }
        records.add(record);
      }

      if (allOrNone == true) {
        for (SObject record : records) {
          String failure = this.resolveSaveFailure(record);
          if (failure != null) {
            this.fireAllOrNoneError(method, 'delete', record.Id, failure);
          }
        }
      }
      List<Database.DeleteResult> results = new List<Database.DeleteResult>();
      for (SObject record : records) {
        String rowFailure = this.resolveSaveFailure(record);
        if (rowFailure != null) {
          results.add(buildFailedDeleteResult(record.Id, rowFailure));
          continue;
        }
        this.recordDelete(label, 1);
        results.add(buildSuccessDeleteResult(record.Id));
      }
      return results;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  public MockEloquent failOnGet() {
    return this.failOnGet(this.testException);
  }

  public MockEloquent failOnGet(Exception e) {
    return this.failOnMethod('get', e);
  }

  public MockEloquent failOnRawSoql() {
    return this.failOnRawSoql(this.testException);
  }

  public MockEloquent failOnRawSoql(Exception e) {
    return this.failOnMethod('rawSoql', e);
  }

  public MockEloquent failOnGetAsSObject() {
    return this.failOnGetAsSObject(this.testException);
  }

  public MockEloquent failOnGetAsSObject(Exception e) {
    return this.failOnMethod('getAsSObject', e);
  }

  public MockEloquent failOnFirst() {
    return this.failOnFirst(this.testException);
  }

  public MockEloquent failOnFirst(Exception e) {
    return this.failOnMethod('first', e);
  }

  public MockEloquent failOnFirstAsSObject() {
    return this.failOnFirstAsSObject(this.testException);
  }

  public MockEloquent failOnFirstAsSObject(Exception e) {
    return this.failOnMethod('firstAsSObject', e);
  }

  public MockEloquent failOnFirstOrFail() {
    return this.failOnFirstOrFail(this.testException);
  }

  public MockEloquent failOnFirstOrFail(Exception e) {
    return this.failOnMethod('firstOrFail', e);
  }

  public MockEloquent failOnFirstOrFailAsSObject() {
    return this.failOnFirstOrFailAsSObject(this.testException);
  }

  public MockEloquent failOnFirstOrFailAsSObject(Exception e) {
    return this.failOnMethod('firstOrFailAsSObject', e);
  }

  public MockEloquent failOnDoInsert() {
    return this.failOnDoInsert(this.testException);
  }

  public MockEloquent failOnDoInsert(Exception e) {
    return this.failOnMethod('doInsert', e);
  }

  public MockEloquent failOnDoUpdate() {
    return this.failOnDoUpdate(this.testException);
  }

  public MockEloquent failOnDoUpdate(Exception e) {
    return this.failOnMethod('doUpdate', e);
  }

  public MockEloquent failOnDoUpsert() {
    return this.failOnDoUpsert(this.testException);
  }

  public MockEloquent failOnDoUpsert(Exception e) {
    return this.failOnMethod('doUpsert', e);
  }

  public MockEloquent failOnDoUpsertByExternalId() {
    return this.failOnDoUpsertByExternalId(this.testException);
  }

  public MockEloquent failOnDoUpsertByExternalId(Exception e) {
    return this.failOnMethod('doUpsertByExternalId', e);
  }

  public MockEloquent failOnDoDelete() {
    return this.failOnDoDelete(this.testException);
  }

  public MockEloquent failOnDoDelete(Exception e) {
    return this.failOnMethod('doDelete', e);
  }

  private MockEloquent failOnMethod(String method, Exception e) {
    MockEloquent newMockEloquent = this.copy();
    ErrorConfig config = new ErrorConfig(e, false);
    if (!newMockEloquent.errorQueueMap.containsKey(method)) {
      newMockEloquent.errorQueueMap.put(method, new List<ErrorConfig>{ config });
    } else {
      newMockEloquent.errorQueueMap.get(method).add(config);
    }
    newMockEloquent.lastConfig = config;

    return newMockEloquent;
  }

  public MockEloquent repeat() {
    String method = 'repeat()';
    MockEloquent newMockEloquent = this.copy();
    if (newMockEloquent.lastConfig == null) {
      String error = 'No method call to repeat';
      String reason = 'repeat() is designed to repeat the last configured exception. It cannot be used without first configuring an exception with a failOnXxx method';
      String action = 'Call a failOnXxx method (e.g., failOnGet()) before calling repeat()';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    newMockEloquent.lastConfig.isRepeat = true;

    return newMockEloquent;
  }

  private void handleErrorQueue(String methodWithArguments, String label) {
    String method = methodWithArguments.split('\\(')[0];
    List<ErrorConfig> queue = this.errorQueueMap.get(method);
    if (queue == null || queue.isEmpty()) {
      return;
    }

    // scan in insertion order — within one label this is naturally FIFO
    Integer hitIndex = -1;
    for (Integer i = 0; i < queue.size(); i++) {
      if (this.effectiveLabel(queue[i]) == label) {
        hitIndex = i;
        break;
      }
    }

    if (hitIndex == -1) {
      this.assertNoUnreachableDefaultConfig(method, label, queue);
      return; // consume nothing — a later matching call may still hit
    }

    ErrorConfig config = queue.remove(hitIndex);
    if (config.isRepeat) {
      queue.add(config);
    }
    if (config.ex instanceof ApexEloquentException) {
      ((ApexEloquentException) config.ex).method(methodWithArguments).fire();
    }
    throw config.ex;
  }

  /**
   * A failOnXxx registered without whenLabel(...) targets the 'default' label —
   * the label every lenient (label-free) operation runs under.
   */
  private String effectiveLabel(ErrorConfig config) {
    return config.label == null ? DEFAULT_LABEL : config.label;
  }

  /**
   * In strict mode no operation ever runs under 'default' (label() is mandatory),
   * so a failOnXxx registered without whenLabel(...) can never fire. Silently
   * ignoring it yields "the exception never came → Assert.fail" with no clue —
   * diagnose the dead config instead.
   */
  private void assertNoUnreachableDefaultConfig(String method, String label, List<ErrorConfig> queue) {
    if (!this.strictMode) {
      return; // lenient: every call runs under 'default', the config is reachable
    }
    for (ErrorConfig config : queue) {
      if (config.label != null) {
        continue;
      }
      String reason =
        'A failOnXxx for \'' +
        method +
        '\' was registered without whenLabel(...), so it targets the \'' +
        DEFAULT_LABEL +
        '\' label. This MockEloquent is in strict mode (labels are in use), where no operation ever runs under \'' +
        DEFAULT_LABEL +
        '\' — the failure can never fire.';
      String action = 'Scope it to the call site you want to fail: .whenLabel(\'' + label + '\')';
      ApexEloquentException.invalidOperation(CLASS_NAME, 'whenLabel(String label) [unreachable config]', reason)
        .action(action)
        .param('label', label)
        .fire();
    }
  }

  /**
   * generate a mock Id for the record
   *
   * @param record SObject to be inserted
   * @return generated Id
   */
  private String generateId(SObject record) {
    String prefix = record.getSObjectType().getDescribe().getKeyPrefix();
    // The '9' marker keeps this sequence disjoint from MockEntry.autoId(n), whose
    // Ids are zero-padded small numbers — without it, insertCount 1 collides with
    // autoId(1) and a failSave registered for the autoId record misfires.
    String generatedId = prefix + '9' + String.valueOf(this.insertCount).leftPad(11, '0');
    this.insertCount++;
    return generatedId;
  }

  private MockEloquent copy() {
    MockEloquent newMockEloquent = new MockEloquent(this.entries);
    newMockEloquent.insertCount = this.insertCount;
    newMockEloquent.scribe = this.scribe;
    // Deep-copy the query spy: sharing the inner lists would let reads on the copy
    // leak into the receiver's records, breaking "the receiver is unmodified".
    newMockEloquent.scribesByLabel = new Map<String, List<Scribe>>();
    for (String bucketLabel : this.scribesByLabel.keySet()) {
      newMockEloquent.scribesByLabel.put(bucketLabel, new List<Scribe>(this.scribesByLabel.get(bucketLabel)));
    }
    newMockEloquent.errorQueueMap = new Map<String, List<ErrorConfig>>();
    newMockEloquent.lastConfig = null;
    for (String method : this.errorQueueMap.keySet()) {
      List<ErrorConfig> configs = this.errorQueueMap.get(method);
      List<ErrorConfig> newConfigs = new List<ErrorConfig>();
      for (ErrorConfig config : configs) {
        ErrorConfig newConfig = new ErrorConfig(config.ex, config.isRepeat);
        newConfig.label = config.label;
        newConfigs.add(newConfig);
        if (this.lastConfig == config) {
          newMockEloquent.lastConfig = newConfig;
        }
      }
      newMockEloquent.errorQueueMap.put(method, newConfigs);
    }
    newMockEloquent.attachedDataByLabel = new Map<String, List<IEntry>>(this.attachedDataByLabel);
    // Deep-copy the spy buckets: sharing the inner lists would let DML on the copy
    // leak into the receiver's records, breaking "the receiver is unmodified".
    newMockEloquent.upsertedByLabel = new Map<String, List<SObject>>();
    for (String bucketLabel : this.upsertedByLabel.keySet()) {
      newMockEloquent.upsertedByLabel.put(bucketLabel, new List<SObject>(this.upsertedByLabel.get(bucketLabel)));
    }
    newMockEloquent.deletedCountByLabel = new Map<String, Integer>(this.deletedCountByLabel);
    newMockEloquent.upsertedRecords = new List<SObject>(this.upsertedRecords);
    newMockEloquent.deletedCount = this.deletedCount;
    newMockEloquent.saveErrorsById = new Map<Id, String>(this.saveErrorsById);
    newMockEloquent.saveErrorsByExternalId = new Map<String, String>(this.saveErrorsByExternalId);
    newMockEloquent.saveErrorMatchers = new List<WhenMatcher>(this.saveErrorMatchers);
    // strict mode state must propagate so failOnXxx-induced copies still enforce
    // consume-once across the original "intent boundary" (issue_39).
    newMockEloquent.strictMode = this.strictMode;
    newMockEloquent.consumedLabelToMethod = new Map<String, String>(this.consumedLabelToMethod);
    newMockEloquent.currentLabel = DEFAULT_LABEL;  // transient
    newMockEloquent.labelSetForNextOp = false;     // transient
    return newMockEloquent;
  }

  private class ErrorConfig {
    public Exception ex;
    public Boolean isRepeat;
    public String label;

    ErrorConfig(Exception ex, Boolean isRepeat) {
      this.ex = ex;
      this.isRepeat = isRepeat;
      this.label = null;
    }
  }
}
