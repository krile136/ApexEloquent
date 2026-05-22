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
  private final List<IEntry> entries;
  private Integer insertCount;
  private Map<String, List<ErrorConfig>> errorQueueMap = new Map<String, List<ErrorConfig>>();
  private ErrorConfig lastConfig;

  @TestVisible
  private Scribe scribe;

  public List<SObject> upsertedRecords = new List<SObject>();
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

  /**
   * @inheritDoc
   */
  public List<IEntry> get(Scribe scribe) {
    String method = 'get(Scribe scribe)';
    this.handleErrorQueue(method);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.isAggregate()
      ? scribe.buildAggregateFieldStructure()
      : scribe.buildFieldStructure();
    List<IEntry> result = new List<IEntry>();
    for (IEntry entry : this.entries) {
      result.add(entry.setFieldStructure(fieldStructure));
    }
    return result;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> rawSoql(String soql) {
    String method = 'rawSoql(String soql)';
    this.handleErrorQueue(method);
    if (String.isBlank(soql)) {
      ApexEloquentException.required(CLASS_NAME, method, 'soql', soql).fire();
    }
    // Raw SOQL bypasses the Scribe FieldStructure pipeline, so we cannot apply
    // "select-forgotten detection" to the mocked rows. For MockEntry instances,
    // turn off skipFieldValidation so callers can read any field; non-MockEntry
    // entries pass through unchanged.
    List<IEntry> result = new List<IEntry>();
    for (IEntry entry : this.entries) {
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
    this.handleErrorQueue(method);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    List<SObject> result = new List<SObject>();
    for (IEntry entry : this.entries) {
      result.add(entry.getRecord());
    }
    return result;
  }

  /**
   * @inheritDoc
   */
  public IEntry first(Scribe scribe) {
    String method = 'first(Scribe scribe)';
    this.handleErrorQueue(method);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    if (this.entries.isEmpty()) {
      return null;
    }
    return this.entries[0].setFieldStructure(fieldStructure);
  }

  /**
   * @inheritDoc
   */
  public SObject firstAsSObject(Scribe scribe) {
    String method = 'firstAsSObject(Scribe scribe)';
    this.handleErrorQueue(method);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    if (this.entries.isEmpty()) {
      return null;
    }
    return this.entries[0].getRecord();
  }

  /**
   * @inheritDoc
   */
  public IEntry firstOrFail(Scribe scribe) {
    String method = 'firstOrFail(Scribe scribe)';
    this.handleErrorQueue(method);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    if (this.entries.isEmpty()) {
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
    return this.entries[0].setFieldStructure(fieldStructure);
  }

  /**
   * @inheritDoc
   */
  public SObject firstOrFailAsSObject(Scribe scribe) {
    String method = 'firstOrFailAsSObject(Scribe scribe)';
    this.handleErrorQueue(method);
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    if (this.entries.isEmpty()) {
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
    return this.entries[0].getRecord();
  }

  /**
   * @inheritDoc
   */
  public SObject doInsert(SObject record) {
    String method = 'doInsert(SObject record)';
    this.handleErrorQueue(method);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', record).fire();
    }

    record.Id = this.generateId(record);
    this.upsertedRecords.add(record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doInsert(List<SObject> records) {
    String method = 'doInsert(List<SObject> records)';
    this.handleErrorQueue(method);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }
    for (SObject record : records) {
      record.Id = this.generateId(record);
    }
    this.upsertedRecords.addAll(records);
    return records;
  }

  /**
   * @inheritDoc
   */
  public SObject doUpdate(SObject record) {
    String method = 'doUpdate(SObject record)';
    this.handleErrorQueue(method);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    this.upsertedRecords.add(record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpdate(IEntry entry) {
    String method = 'doUpdate(IEntry entry)';
    this.handleErrorQueue(method);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    this.upsertedRecords.add(entry.getRecord());
    return entry;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpdate(List<SObject> records) {
    String method = 'doUpdate(List<SObject> records)';
    this.handleErrorQueue(method);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    this.upsertedRecords.addAll(records);
    return records;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpdate(List<IEntry> entries) {
    String method = 'doUpdate(List<IEntry> entries)';
    this.handleErrorQueue(method);
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    for (IEntry entry : entries) {
      this.upsertedRecords.add(entry.getRecord());
    }

    return entries;
  }

  /**
   * @inheritDoc
   */
  public Database.SaveResult doUpdate(SObject record, Boolean allOrNone) {
    String method = 'doUpdate(SObject record, Boolean allOrNone)';
    this.handleErrorQueue(method);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    this.upsertedRecords.add(record);
    return buildSuccessSaveResult(record.Id);
  }

  /**
   * @inheritDoc
   */
  public Database.SaveResult doUpdate(IEntry entry, Boolean allOrNone) {
    String method = 'doUpdate(IEntry entry, Boolean allOrNone)';
    this.handleErrorQueue(method);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    SObject record = entry.getRecord();
    this.upsertedRecords.add(record);
    return buildSuccessSaveResult(record.Id);
  }

  /**
   * @inheritDoc
   */
  public List<Database.SaveResult> doUpdate(List<SObject> records, Boolean allOrNone) {
    String method = 'doUpdate(List<SObject> records, Boolean allOrNone)';
    this.handleErrorQueue(method);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    this.upsertedRecords.addAll(records);
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
    this.handleErrorQueue(method);
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    List<Database.SaveResult> results = new List<Database.SaveResult>();
    for (IEntry entry : entries) {
      SObject record = entry.getRecord();
      this.upsertedRecords.add(record);
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
    this.handleErrorQueue(method);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    if (record.Id == null) {
      record.Id = this.generateId(record);
    }
    this.upsertedRecords.add(record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpsert(IEntry entry) {
    String method = 'doUpsert(IEntry entry)';
    this.handleErrorQueue(method);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    SObject record = entry.getRecord();
    if (record.Id == null) {
      entry.put('Id', this.generateId(record));
    }
    this.upsertedRecords.add(record);
    return entry;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpsert(List<SObject> records) {
    String method = 'doUpsert(List<SObject> records)';
    this.handleErrorQueue(method);
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
      this.upsertedRecords.add(record);
    }
    return records;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpsert(List<IEntry> entries) {
    String method = 'doUpsert(List<IEntry> entries)';
    this.handleErrorQueue(method);
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
      this.upsertedRecords.add(record);
    }
    return entries;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(SObject record) {
    String method = 'doDelete(SObject record)';
    this.handleErrorQueue(method);
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    this.deletedCount++;
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(IEntry entry) {
    String method = 'doDelete(IEntry entry)';
    this.handleErrorQueue(method);
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    this.deletedCount++;
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<SObject> records) {
    String method = 'doDelete(List<SObject> records)';
    this.handleErrorQueue(method);
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    this.deletedCount += records.size();
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<IEntry> entries) {
    String method = 'doDelete(List<IEntry> entries)';
    this.handleErrorQueue(method);
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    this.deletedCount += entries.size();
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

  private void handleErrorQueue(String methodWithArguments) {
    String method = methodWithArguments.split('\\(')[0];
    if (this.errorQueueMap.containsKey(method) && !this.errorQueueMap.get(method).isEmpty()) {
      ErrorConfig config = this.errorQueueMap.get(method).remove(0);
      if (config.isRepeat) {
        this.errorQueueMap.get(method).add(config);
      }
      if (config.ex instanceof ApexEloquentException) {
        ((ApexEloquentException) config.ex).method(methodWithArguments).fire();
      }
      throw config.ex;
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
        newConfigs.add(newConfig);
        if (this.lastConfig == config) {
          newMockEloquent.lastConfig = newConfig;
        }
      }
      newMockEloquent.errorQueueMap.put(method, newConfigs);
    }
    return newMockEloquent;
  }

  private class ErrorConfig {
    public Exception ex;
    public Boolean isRepeat;

    ErrorConfig(Exception ex, Boolean isRepeat) {
      this.ex = ex;
      this.isRepeat = isRepeat;
    }
  }
}
