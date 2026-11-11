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
 * @description The concrete production implementation of the `IEloquent` interface.
 *
 * This class is responsible for interacting with the live Salesforce database. It takes a
 * `Scribe` instance, converts it into an executable SOQL string, and performs the
 * query or DML operation using the standard `Database` methods. Query results are wrapped
 * in `Entry` instances to provide a consistent data access experience.
 * @see IEloquent
 * @see Scribe
 * @see Entry
 * @see MockEloquent
 * @directory ApexEloquent/Eloquents
 */
public inherited sharing class Eloquent implements IEloquent {
  private static final String CLASS_NAME = 'Eloquent';
  private static final String DEFAULT_LABEL = 'default';

  private String currentLabel = DEFAULT_LABEL;
  private Boolean strictMode = false;
  private Boolean labelSetForNextOp = false;
  private Map<String, String> consumedLabelToMethod = new Map<String, String>();

  // FLS/CRUD access mode for SOQL/DML. Defaults to USER_MODE (secure-by-default); opt out via systemMode().
  // Note: record-level sharing is NOT controlled here — it follows this class's sharing declaration
  // (inherited sharing -> the caller's context).
  @TestVisible
  private System.AccessLevel accessLevel = System.AccessLevel.USER_MODE;

  /**
   * @inheritDoc
   */
  public IEloquent label(String label) {
    if (label == null || String.isBlank(label)) {
      ApexEloquentException.required(CLASS_NAME, 'label(String label)', 'label', label).fire();
    }
    this.currentLabel = label;
    this.labelSetForNextOp = true;
    this.strictMode = true; // sticky — once on, stays on for this IEloquent instance
    return this;
  }

  /**
   * constructor
   */
  public Eloquent() {
  }

  /**
   * Copy constructor used by userMode()/systemMode(): carries the label
   * bookkeeping over so the returned instance behaves as the same logical
   * pipeline with only the access mode changed.
   *
   * The consumed-label map is shared BY REFERENCE on purpose — consume-once
   * must keep guarding the whole family of copies as one pipeline, otherwise
   * switching modes would silently reset the guard.
   *
   * @param source instance being copied
   * @param accessLevel access mode for the copy
   */
  private Eloquent(Eloquent source, System.AccessLevel accessLevel) {
    this.accessLevel = accessLevel;
    this.strictMode = source.strictMode;
    this.currentLabel = source.currentLabel;
    this.labelSetForNextOp = source.labelSetForNextOp;
    this.consumedLabelToMethod = source.consumedLabelToMethod;
  }

  /**
   * @inheritDoc
   */
  public IEloquent userMode() {
    return this.copyWithAccessLevel(System.AccessLevel.USER_MODE);
  }

  /**
   * @inheritDoc
   */
  public IEloquent systemMode() {
    return this.copyWithAccessLevel(System.AccessLevel.SYSTEM_MODE);
  }

  /**
   * Builds the mode-switched copy and hands the pending label off to it:
   * a label set just before the switch is meant for the next operation on
   * the returned instance, so the receiver's transient label state is
   * cleared to keep `label('x').systemMode().doX()` working unchanged.
   *
   * @param accessLevel access mode for the copy
   * @return mode-switched copy; the receiver keeps its own access mode
   */
  private IEloquent copyWithAccessLevel(System.AccessLevel accessLevel) {
    Eloquent copied = new Eloquent(this, accessLevel);
    this.currentLabel = DEFAULT_LABEL;
    this.labelSetForNextOp = false;
    return copied;
  }

  /**
   * Captures the current label for routing/logging, resets the transient
   * label state, and enforces strict-mode rules:
   *   (1) once strict mode is active, every operation must be preceded by .label(...)
   *   (2) each label allows at most one SUCCESSFUL operation per IEloquent instance
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
      String reason = 'Strict mode is active on this IEloquent: every operation must be preceded by .label(...).';
      String action = 'Call .label(X) before this read/DML, or use a fresh IEloquent instance if you want lenient mode.';
      ApexEloquentException.invalidOperation(CLASS_NAME, 'label(String label) [strict mode required]', reason).action(action).fire();
    }
    if (this.consumedLabelToMethod.containsKey(label)) {
      String reason =
        'Label \'' +
        label +
        '\' was already consumed by ' +
        this.consumedLabelToMethod.get(label) +
        ' on this IEloquent instance.';
      String action = 'A label allows at most one successful operation per IEloquent (failed attempts may be retried). Use a different label name, or construct a fresh IEloquent.';
      ApexEloquentException.invalidOperation(CLASS_NAME, 'label(String label) [consume-once]', reason)
        .action(action)
        .param('label', label)
        .fire();
    }
    this.consumedLabelToMethod.put(label, method);
    if (label != DEFAULT_LABEL) {
      System.debug('[Eloquent:' + label + ']');
    }
    return label;
  }

  /**
   * Releases a label whose operation failed. consume-once guards one
   * SUCCESSFUL operation per label — a failed attempt did not fulfill the
   * label's intent, so the same label may be retried.
   *
   */
  private void releaseLabel(String label) {
    this.consumedLabelToMethod.remove(label);
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> get(Scribe scribe) {
    String method = 'get(Scribe scribe)';
    String label = this.consumeLabel(method);
    try {
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
      }

      if (scribe.isAggregate()) {
        return this.getAggregate(scribe);
      }

      List<IEntry> entries = new List<IEntry>();
      for (SObject record : (List<SObject>) this.runQuery(scribe)) {
        entries.add(new Entry(record));
      }

      return entries;
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  private List<IEntry> getAggregate(Scribe scribe) {
    FieldStructure fieldStructure = null;
    List<IEntry> entries = new List<IEntry>();
    for (AggregateResult aggregateResult : (List<AggregateResult>) this.runQuery(scribe)) {
      fieldStructure = fieldStructure == null ? scribe.buildAggregateFieldStructure() : fieldStructure;
      entries.add(new Entry(aggregateResult, fieldStructure));
    }
    return entries;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> rawSoql(String soql) {
    String method = 'rawSoql(String soql)';
    String label = this.consumeLabel(method);
    try {
      if (String.isBlank(soql)) {
        ApexEloquentException.required(CLASS_NAME, method, 'soql', soql).fire();
      }
      List<IEntry> entries = new List<IEntry>();
      for (SObject record : (List<SObject>) Database.query(soql, this.accessLevel)) {
        entries.add(new Entry(record));
      }
      return entries;
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
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
      }

      return (List<SObject>) this.runQuery(scribe);
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
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
      }

      return this.queryFirstEntry(scribe);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * Executes the query and wraps the first row as an IEntry, or returns null
   * when the query matches nothing. Aggregate Scribes get the aggregate
   * FieldStructure so aliases resolve, exactly as get() does — without this
   * shared branch, an AggregateResult row would be wrapped as a plain Entry
   * and alias reads would fail with a misleading "field does not exist"
   * error (issue #85).
   *
   * @param scribe query definition
   * @return the first row as an IEntry, or null when the query matches nothing
   */
  private IEntry queryFirstEntry(Scribe scribe) {
    if (scribe.isAggregate()) {
      List<AggregateResult> aggregateResults = (List<AggregateResult>) this.runQuery(scribe);
      return aggregateResults.isEmpty() ? null : new Entry(aggregateResults[0], scribe.buildAggregateFieldStructure());
    }
    List<SObject> records = (List<SObject>) this.runQuery(scribe);
    return records.isEmpty() ? null : new Entry(records[0]);
  }

  /**
   * @inheritDoc
   */
  public SObject firstAsSObject(Scribe scribe) {
    String method = 'firstAsSObject(Scribe scribe)';
    String label = this.consumeLabel(method);
    try {
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
      }

      List<SObject> records = (List<SObject>) this.runQuery(scribe);
      if (records.isEmpty()) {
        return null;
      }
      return records[0];
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
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
      }

      IEntry entry = this.queryFirstEntry(scribe);

      if (entry == null) {
        String error = 'No records were found for the given criteria';
        String reason = 'The query execution returned zero records';
        String action = 'Ensure that the query criteria are correct and that relevant records exist in the database';
        // The SOQL is deliberately left out of the message. Callers often pass the message to
        // the UI (AuraHandledException), which would show field names and filter values to
        // every user, including guest users of a public site. The query is still in the
        // debug log (Scribe.toBoundQuery writes it there) for anyone investigating.
        ApexEloquentException.at(CLASS_NAME)
          .method(method)
          .error(error)
          .reason(reason)
          .action(action)
          .fire();
      }
      return entry;
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
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
      }
      if (orFail == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'orFail', null).fire();
      }

      IEntry entry = this.queryFirstEntry(scribe);

      if (entry == null) {
        throw orFail;
      }
      return entry;
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
      if (scribe == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
      }

      List<SObject> records = (List<SObject>) this.runQuery(scribe);
      if (records.isEmpty()) {
        String error = 'No records were found for the given criteria';
        String reason = 'The query execution returned zero records';
        String action = 'Ensure that the query criteria are correct and that relevant records exist in the database';
        // The SOQL is deliberately left out of the message. Callers often pass the message to
        // the UI (AuraHandledException), which would show field names and filter values to
        // every user, including guest users of a public site. The query is still in the
        // debug log (Scribe.toBoundQuery writes it there) for anyone investigating.
        ApexEloquentException.at(CLASS_NAME)
          .method(method)
          .error(error)
          .reason(reason)
          .action(action)
          .fire();
      }
      return records[0];
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
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', record).fire();
      }
      Database.insert(record, this.accessLevel);
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
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'insert');
        }
      }
      Database.insert(records, this.accessLevel);
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
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      return Database.insert(record, allOrNone, this.accessLevel);
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
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'insert');
      }
      return Database.insert(record, allOrNone, this.accessLevel);
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
      return Database.insert(records, allOrNone, this.accessLevel);
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
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      if (entries.isEmpty()) {
        return new List<Database.SaveResult>();
      }
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
      return Database.insert(records, allOrNone, this.accessLevel);
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
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'insert');
      }
      Database.insert(record, this.accessLevel);
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
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }

      if (entries.isEmpty()) {
        return new List<IEntry>();
      }
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
      Database.insert(records, this.accessLevel);
      List<IEntry> insertedEntries = new List<IEntry>();
      for (SObject record : records) {
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
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }

      Database.update(record, this.accessLevel);
      return record;
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
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      return Database.update(record, allOrNone, this.accessLevel);
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
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'update');
      }
      Database.update(record, this.accessLevel);
      return new Entry(record);
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
      return Database.update(record, allOrNone, this.accessLevel);
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
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'update');
        }
      }
      Database.update(records, this.accessLevel);
      return records;
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
      return Database.update(records, allOrNone, this.accessLevel);
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
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }

      if (entries.isEmpty()) {
        return new List<IEntry>();
      }
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
      Database.update(records, this.accessLevel);
      List<IEntry> updatedEntries = new List<IEntry>();
      for (SObject record : records) {
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
  public List<Database.SaveResult> doUpdate(List<IEntry> entries, Boolean allOrNone) {
    String method = 'doUpdate(List<IEntry> entries, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      if (entries.isEmpty()) {
        return new List<Database.SaveResult>();
      }
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
      return Database.update(records, allOrNone, this.accessLevel);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public SObject doUpsert(SObject record) {
    String method = 'doUpsert(SObject record)';
    String label = this.consumeLabel(method);
    try {
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }

      Database.upsert(record, this.accessLevel);
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
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'upsert');
      }
      Database.upsert(record, this.accessLevel);
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
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }

      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'upsert');
        }
      }
      Database.upsert(records, this.accessLevel);
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
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }

      if (entries.isEmpty()) {
        return new List<IEntry>();
      }
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
      Database.upsert(records, this.accessLevel);
      List<IEntry> upsertedEntries = new List<IEntry>();
      for (SObject record : records) {
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
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      return Database.upsert(record, allOrNone, this.accessLevel);
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
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'upsert');
      }
      return Database.upsert(record, allOrNone, this.accessLevel);
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
      return Database.upsert(records, allOrNone, this.accessLevel);
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
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      if (entries.isEmpty()) {
        return new List<Database.UpsertResult>();
      }
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
      return Database.upsert(records, allOrNone, this.accessLevel);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.UpsertResult doUpsertByExternalId(SObject record, Schema.SObjectField externalIdField, Boolean allOrNone) {
    String method = 'doUpsertByExternalId(SObject record, Schema.SObjectField externalIdField, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
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

      return Database.upsert(record, externalIdField, allOrNone, this.accessLevel);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public Database.UpsertResult doUpsertByExternalId(IEntry entry, Schema.SObjectField externalIdField, Boolean allOrNone) {
    String method = 'doUpsertByExternalId(IEntry entry, Schema.SObjectField externalIdField, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
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
      return Database.upsert(record, externalIdField, allOrNone, this.accessLevel);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.UpsertResult> doUpsertByExternalId(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone) {
    String method = 'doUpsertByExternalId(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
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
      return Database.upsert(records, externalIdField, allOrNone, this.accessLevel);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public List<Database.UpsertResult> doUpsertByExternalId(List<IEntry> entries, Schema.SObjectField externalIdField, Boolean allOrNone) {
    String method = 'doUpsertByExternalId(List<IEntry> entries, Schema.SObjectField externalIdField, Boolean allOrNone)';
    String label = this.consumeLabel(method);
    try {
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

      if (entries.isEmpty()) {
        return new List<Database.UpsertResult>();
      }
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
      return Database.upsert(records, externalIdField, allOrNone, this.accessLevel);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }

  /**
   * @inheritDoc
   */
  public void doDelete(SObject record) {
    String method = 'doDelete(SObject record)';
    String label = this.consumeLabel(method);
    try {
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }

      Database.delete(record, this.accessLevel);
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
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'delete');
      }
      Database.delete(record, this.accessLevel);
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
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }

      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
      }
      Database.delete(records, this.accessLevel);
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
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }

      if (entries.isEmpty()) {
        System.debug('No entries to delete.');
        return;
      }
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'delete');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
        records.add(record);
      }

      Database.delete(records, this.accessLevel);
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
      if (record == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      return Database.delete(record, allOrNone, this.accessLevel);
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
      if (entry == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      SObject record = entry.getRecord();
      if (record == null) {
        this.fireNullElementError(method, 'delete');
      }
      return Database.delete(record, allOrNone, this.accessLevel);
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
      if (records == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
      }
      for (SObject record : records) {
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
      }
      return Database.delete(records, allOrNone, this.accessLevel);
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
      if (entries == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
      }
      if (allOrNone == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'allOrNone', null).fire();
      }

      if (entries.isEmpty()) {
        return new List<Database.DeleteResult>();
      }
      List<SObject> records = new List<SObject>();
      for (IEntry entry : entries) {
        if (entry == null) {
          this.fireNullElementError(method, 'delete');
        }
        SObject record = entry.getRecord();
        if (record == null) {
          this.fireNullElementError(method, 'delete');
        }
        records.add(record);
      }
      return Database.delete(records, allOrNone, this.accessLevel);
    } catch (Exception e) {
      this.releaseLabel(label);
      throw e;
    }
  }


  /**
   * Runs a Scribe query with its values bound (Database.queryWithBinds) under this
   * IEloquent's access level. Values are no longer pasted into the SOQL text; the debug log
   * still shows the query with the values written in (Scribe.toBoundQuery).
   *
   * @param scribe The query to run.
   * @return The rows (SObjects, or AggregateResults for an aggregate query).
   */
  private List<SObject> runQuery(Scribe scribe) {
    SoqlBinds.BoundQuery query = scribe.toBoundQuery();
    return Database.queryWithBinds(query.soql, query.binds, this.accessLevel);
  }

  /**
   * Rejects an externalIdField that real Database.upsert cannot route on. Passing
   * such a field is a usage error decided by the code, not by the data, so it is
   * reported as an ApexEloquentException (a rule violation) rather than the raw
   * SObjectException the platform would throw. Measured on API v67.0: a field that is
   * neither an external Id nor a standard indexed (idLookup) field throws
   * "Invalid field for upsert, must be an External Id custom or standard indexed
   * field". MockEloquent applies the identical rule.
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
   * Fires the unified null-element error for list DML. Real Database DML rejects
   * lists containing null elements with a ListException before processing any row
   * (measured on API v67.0). A null element is a usage error, so it is reported
   * as an ApexEloquentException (a rule violation) before any row is sent; this
   * also avoids an NPE while unwrapping entries. MockEloquent applies the same rule.
   *
   * @param method calling method signature
   * @param dmlType DML verb for the error headline
   */
  private void fireNullElementError(String method, String dmlType) {
    String error = 'Failed to ' + dmlType + ' operation';
    String reason = 'A null record was passed (as the argument, or as an element of the list), which real Database DML rejects before processing any row';
    String action = 'Ensure the record passed to the DML method is not null and, for list DML, that the list contains no null elements';
    ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
  }
}
