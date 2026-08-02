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
 * @see IEloquent
 * @see Eloquent
 * @see MockEntry
 */
public with sharing class MockEloquent implements IEloquent {
  private static final String DEFAULT_LABEL = 'default';

  private final List<IEntry> entries;
  private Integer insertCount;
  private Map<String, List<ErrorConfig>> errorQueueMap = new Map<String, List<ErrorConfig>>();
  private ErrorConfig lastConfig;

  @TestVisible
  private Scribe scribe;

  private String currentLabel = DEFAULT_LABEL;
  private Boolean strictMode = false;
  private Boolean labelSetForNextOp = false;
  private Set<String> consumedLabels = new Set<String>();
  private Map<String, List<IEntry>> attachedDataByLabel = new Map<String, List<IEntry>>();
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
   */
  public IEloquent userMode() {
    return this;
  }

  /**
   * @inheritDoc
   * No-op in the mock: there is no real database, so access mode has no effect on captured data.
   */
  public IEloquent systemMode() {
    return this;
  }

  /**
   * Pre-load data for a label. Subsequent read calls tagged with that label
   * will see this data as the query source. Overwrites prior attach.
   */
  public MockEloquent attach(String label, List<IEntry> entries) {
    if (label == null || String.isBlank(label)) {
      ApexEloquentException.required(CLASS_NAME, 'attach(String label, List<IEntry> entries)', 'label', label)
        .fire();
    }
    this.attachedDataByLabel.put(label, entries == null ? new List<IEntry>() : entries);
    return this;
  }

  /**
   * Pre-load a single entry for a label.
   */
  public MockEloquent attach(String label, IEntry entry) {
    return this.attach(label, entry == null ? new List<IEntry>() : new List<IEntry>{ entry });
  }

  /**
   * Returns the records upserted (inserted / updated / upserted) under a given label.
   * Returns empty list if no DML ran under that label.
   */
  public List<SObject> upsertedRecordsAt(String label) {
    return this.upsertedByLabel.containsKey(label) ? this.upsertedByLabel.get(label) : new List<SObject>();
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
   * @throws ApexEloquentException if called without a preceding failOnXxx()
   */
  public MockEloquent whenLabel(String label) {
    if (this.lastConfig == null) {
      String reason = 'No failOnXxx to scope. whenLabel() modifies the most recently configured failure.';
      String action = 'Call failOnGet() / failOnDoInsert() / etc. before calling whenLabel(...).';
      ApexEloquentException.invalidOperation(CLASS_NAME, 'whenLabel(String label)', reason).action(action).fire();
    }
    this.lastConfig.label = label;
    return this;
  }

  /**
   * Captures the current label for routing, resets the transient label state,
   * and enforces strict-mode rules:
   *   (1) once strict mode is active, every operation must be preceded by .label(...)
   *   (2) each label can be consumed at most once per MockEloquent instance
   */
  private String consumeLabel() {
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
    if (this.consumedLabels.contains(label)) {
      String reason = 'Label \'' + label + '\' has already been consumed on this MockEloquent instance.';
      String action = 'Each label can be used at most once per MockEloquent. Use a different label name, or construct a fresh MockEloquent.';
      ApexEloquentException.invalidOperation(CLASS_NAME, 'label(String label) [consume-once]', reason)
        .action(action)
        .param('label', label)
        .fire();
    }
    this.consumedLabels.add(label);
    return label;
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
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.isAggregate()
      ? scribe.buildAggregateFieldStructure()
      : scribe.buildFieldStructure();
    List<IEntry> result = new List<IEntry>();
    for (IEntry entry : this.activeEntries(label)) {
      result.add(entry.setFieldStructure(fieldStructure));
    }
    return result;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> rawSoql(String soql) {
    String method = 'rawSoql(String soql)';
    String label = this.consumeLabel();
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
  }

  /**
   * @inheritDoc
   */
  public List<SObject> getAsSObject(Scribe scribe) {
    String method = 'getAsSObject(Scribe scribe)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    List<SObject> result = new List<SObject>();
    for (IEntry entry : this.activeEntries(label)) {
      result.add(entry.getRecord());
    }
    return result;
  }

  /**
   * @inheritDoc
   */
  public IEntry first(Scribe scribe) {
    String method = 'first(Scribe scribe)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    List<IEntry> source = this.activeEntries(label);
    if (source.isEmpty()) {
      return null;
    }
    return source[0].setFieldStructure(fieldStructure);
  }

  /**
   * @inheritDoc
   */
  public SObject firstAsSObject(Scribe scribe) {
    String method = 'firstAsSObject(Scribe scribe)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    List<IEntry> source = this.activeEntries(label);
    if (source.isEmpty()) {
      return null;
    }
    return source[0].getRecord();
  }

  /**
   * @inheritDoc
   */
  public IEntry firstOrFail(Scribe scribe) {
    String method = 'firstOrFail(Scribe scribe)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.buildFieldStructure();
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
  }

  /**
   * @inheritDoc
   */
  public IEntry firstOrFail(Scribe scribe, Exception orFail) {
    String method = 'firstOrFail(Scribe scribe, Exception orFail)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
    }
    if (orFail == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'orFail', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    List<IEntry> source = this.activeEntries(label);
    if (source.isEmpty()) {
      throw orFail;
    }
    return source[0].setFieldStructure(fieldStructure);
  }

  /**
   * @inheritDoc
   */
  public SObject firstOrFailAsSObject(Scribe scribe) {
    String method = 'firstOrFailAsSObject(Scribe scribe)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
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
  }

  /**
   * @inheritDoc
   */
  public SObject doInsert(SObject record) {
    String method = 'doInsert(SObject record)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', record).fire();
    }

    record.Id = this.generateId(record);
    this.recordUpsert(label, record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doInsert(List<SObject> records) {
    String method = 'doInsert(List<SObject> records)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }
    for (SObject record : records) {
      record.Id = this.generateId(record);
    }
    this.recordUpsertAll(label, records);
    return records;
  }

  /**
   * @inheritDoc
   */
  public SObject doUpdate(SObject record) {
    String method = 'doUpdate(SObject record)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    this.recordUpsert(label, record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpdate(IEntry entry) {
    String method = 'doUpdate(IEntry entry)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    this.recordUpsert(label, entry.getRecord());
    return entry;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpdate(List<SObject> records) {
    String method = 'doUpdate(List<SObject> records)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    this.recordUpsertAll(label, records);
    return records;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpdate(List<IEntry> entries) {
    String method = 'doUpdate(List<IEntry> entries)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    for (IEntry entry : entries) {
      this.recordUpsert(label, entry.getRecord());
    }

    return entries;
  }

  /**
   * @inheritDoc
   */
  public Database.SaveResult doUpdate(SObject record, Boolean allOrNone) {
    String method = 'doUpdate(SObject record, Boolean allOrNone)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    this.recordUpsert(label, record);
    return buildSuccessSaveResult(record.Id);
  }

  /**
   * @inheritDoc
   */
  public Database.SaveResult doUpdate(IEntry entry, Boolean allOrNone) {
    String method = 'doUpdate(IEntry entry, Boolean allOrNone)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    SObject record = entry.getRecord();
    this.recordUpsert(label, record);
    return buildSuccessSaveResult(record.Id);
  }

  /**
   * @inheritDoc
   */
  public List<Database.SaveResult> doUpdate(List<SObject> records, Boolean allOrNone) {
    String method = 'doUpdate(List<SObject> records, Boolean allOrNone)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    this.recordUpsertAll(label, records);
    List<Database.SaveResult> results = new List<Database.SaveResult>();
    for (SObject record : records) {
      results.add(buildSuccessSaveResult(record.Id));
    }
    return results;
  }

  /**
   * @inheritDoc
   */
  public List<Database.SaveResult> doUpdate(List<IEntry> entries, Boolean allOrNone) {
    String method = 'doUpdate(List<IEntry> entries, Boolean allOrNone)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    List<Database.SaveResult> results = new List<Database.SaveResult>();
    for (IEntry entry : entries) {
      SObject record = entry.getRecord();
      this.recordUpsert(label, record);
      results.add(buildSuccessSaveResult(record.Id));
    }
    return results;
  }

  private static Database.SaveResult buildSuccessSaveResult(Id recordId) {
    String idPart = recordId == null ? '' : '"id":"' + recordId + '",';
    String payload = '{"success":true,' + idPart + '"errors":[]}';
    return (Database.SaveResult) JSON.deserialize(payload, Database.SaveResult.class);
  }

  /**
   * @inheritDoc
   */
  public SObject doUpsert(SObject record) {
    String method = 'doUpsert(SObject record)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    if (record.Id == null) {
      record.Id = this.generateId(record);
    }
    this.recordUpsert(label, record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpsert(IEntry entry) {
    String method = 'doUpsert(IEntry entry)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    SObject record = entry.getRecord();
    if (record.Id == null) {
      entry.put('Id', this.generateId(record));
    }
    this.recordUpsert(label, record);
    return entry;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpsert(List<SObject> records) {
    String method = 'doUpsert(List<SObject> records)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    for (SObject record : records) {
      if (record == null) {
        String error = 'Null record found in records list';
        String reason = 'The list of records to upsert contains a null value, which is not allowed';
        String action = 'Ensure that the list of records passed to doUpsert does not contain any null values';
        ApexEloquentException.at(CLASS_NAME)
          .method(method)
          .error(error)
          .reason(reason)
          .action(action)
          .param('records', records)
          .fire();
      }
      if (record.Id == null) {
        record.Id = this.generateId(record);
      }
      this.recordUpsert(label, record);
    }
    return records;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpsert(List<IEntry> entries) {
    String method = 'doUpsert(List<IEntry> entries)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    for (IEntry entry : entries) {
      if (entry == null || entry.getRecord() == null) {
        String error = 'Null entry found in entries list';
        String reason = 'The list of entries to upsert contains a null value, which is not allowed';
        String action = 'Ensure that the list of entries passed to doUpsert does not contain any null values';
        ApexEloquentException.at(CLASS_NAME)
          .method(method)
          .error(error)
          .reason(reason)
          .action(action)
          .param('entries', entries)
          .fire();
      }
      SObject record = entry.getRecord();
      if (record.Id == null) {
        entry.put('Id', this.generateId(record));
      }
      this.recordUpsert(label, record);
    }
    return entries;
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
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    Boolean isCreated = record.Id == null;
    if (isCreated) {
      record.Id = this.generateId(record);
    }
    this.recordUpsert(label, record);
    return buildSuccessUpsertResult(record.Id, isCreated);
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
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    SObject record = entry.getRecord();
    Boolean isCreated = record.Id == null;
    if (isCreated) {
      entry.put('Id', this.generateId(record));
    }
    this.recordUpsert(label, record);
    return buildSuccessUpsertResult(record.Id, isCreated);
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
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    List<Database.UpsertResult> results = new List<Database.UpsertResult>();
    for (SObject record : records) {
      if (record == null) {
        String error = 'Null record found in records list';
        String reason = 'The list of records to upsert contains a null value, which is not allowed';
        String action = 'Ensure that the list of records passed to doUpsertByExternalId does not contain any null values';
        ApexEloquentException.at(CLASS_NAME)
          .method(method)
          .error(error)
          .reason(reason)
          .action(action)
          .param('records', records)
          .fire();
      }
      Boolean isCreated = record.Id == null;
      if (isCreated) {
        record.Id = this.generateId(record);
      }
      this.recordUpsert(label, record);
      results.add(buildSuccessUpsertResult(record.Id, isCreated));
    }
    return results;
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
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    List<Database.UpsertResult> results = new List<Database.UpsertResult>();
    for (IEntry entry : entries) {
      if (entry == null || entry.getRecord() == null) {
        String error = 'Null entry found in entries list';
        String reason = 'The list of entries to upsert contains a null value, which is not allowed';
        String action = 'Ensure that the list of entries passed to doUpsertByExternalId does not contain any null values';
        ApexEloquentException.at(CLASS_NAME)
          .method(method)
          .error(error)
          .reason(reason)
          .action(action)
          .param('entries', entries)
          .fire();
      }
      SObject record = entry.getRecord();
      Boolean isCreated = record.Id == null;
      if (isCreated) {
        entry.put('Id', this.generateId(record));
      }
      this.recordUpsert(label, record);
      results.add(buildSuccessUpsertResult(record.Id, isCreated));
    }
    return results;
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
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    this.recordDelete(label, 1);
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(IEntry entry) {
    String method = 'doDelete(IEntry entry)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    this.recordDelete(label, 1);
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<SObject> records) {
    String method = 'doDelete(List<SObject> records)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    this.recordDelete(label, records.size());
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<IEntry> entries) {
    String method = 'doDelete(List<IEntry> entries)';
    String label = this.consumeLabel();
    this.handleErrorQueue(method, label);
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    this.recordDelete(label, entries.size());
    return;
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
    if (!this.errorQueueMap.containsKey(method) || this.errorQueueMap.get(method).isEmpty()) {
      return;
    }
    ErrorConfig head = this.errorQueueMap.get(method).get(0);
    if (head.label != null && head.label != label) {
      // label-scoped config but the current call's label does not match — skip
      // without dequeue so a later matching call can consume it.
      return;
    }
    ErrorConfig config = this.errorQueueMap.get(method).remove(0);
    if (config.isRepeat) {
      this.errorQueueMap.get(method).add(config);
    }
    if (config.ex instanceof ApexEloquentException) {
      ((ApexEloquentException) config.ex).method(methodWithArguments).fire();
    }
    throw config.ex;
  }

  /**
   * generate a mock Id for the record
   *
   * @param record SObject to be inserted
   * @return generated Id
   */
  private String generateId(SObject record) {
    String prefix = record.getSObjectType().getDescribe().getKeyPrefix();
    String generatedId = prefix + String.valueOf(this.insertCount).leftPad(12, '0');
    this.insertCount++;
    return generatedId;
  }

  private MockEloquent copy() {
    MockEloquent newMockEloquent = new MockEloquent(this.entries);
    newMockEloquent.insertCount = this.insertCount;
    newMockEloquent.scribe = this.scribe;
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
    newMockEloquent.upsertedByLabel = new Map<String, List<SObject>>(this.upsertedByLabel);
    newMockEloquent.deletedCountByLabel = new Map<String, Integer>(this.deletedCountByLabel);
    // strict mode state must propagate so failOnXxx-induced copies still enforce
    // consume-once across the original "intent boundary" (issue_39).
    newMockEloquent.strictMode = this.strictMode;
    newMockEloquent.consumedLabels = new Set<String>(this.consumedLabels);
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
