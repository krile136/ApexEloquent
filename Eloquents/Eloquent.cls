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
 */
public with sharing class Eloquent implements IEloquent {
  private final Integer MAX_DML_CHUNKING = 10;

  private static final String CLASS_NAME = 'Scribe';

  /**
   * @inheritDoc
   */
  public List<IEntry> get(Scribe scribe) {
    String method = ('get(Scribe scribe)');
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'sctibe', null).fire();
    }

    if (scribe.isAggregate()) {
      return this.getAggregate(scribe);
    }

    List<IEntry> entries = new List<IEntry>();
    for (SObject record : (List<SObject>) Database.query(scribe.toSoql())) {
      entries.add(new Entry(record));
    }

    return entries;
  }

  private List<IEntry> getAggregate(Scribe scribe) {
    FieldStructure fieldStructure = null;
    List<IEntry> entries = new List<IEntry>();
    for (AggregateResult aggregateResult : (List<AggregateResult>) Database.query(scribe.toSoql())) {
      fieldStructure = fieldStructure == null ? scribe.buildAggregateFieldStructure() : fieldStructure;
      entries.add(new Entry(aggregateResult, fieldStructure));
    }
    return entries;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> getAsSObject(Scribe scribe) {
    String method = ('getAsSObject(Scribe scribe)');
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
    }

    return (List<SObject>) Database.query(scribe.toSoql());
  }

  /**
   * @inheritDoc
   */
  public IEntry first(Scribe scribe) {
    String method = ('first(Scribe scribe)');
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
    }

    List<SObject> records = (List<SObject>) Database.query(scribe.toSoql());
    if (records.isEmpty()) {
      return null;
    }
    return new Entry(records[0]);
  }

  /**
   * @inheritDoc
   */
  public SObject firstAsSObject(Scribe scribe) {
    String method = ('firstAsSObject(Scribe scribe)');
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
    }

    List<SObject> records = (List<SObject>) Database.query(scribe.toSoql());
    if (records.isEmpty()) {
      return null;
    }
    return records[0];
  }

  /**
   * @inheritDoc
   */
  public IEntry firstOrFail(Scribe scribe) {
    String method = ('firstOrFail(Scribe scribe)');
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
    }

    List<SObject> records = (List<SObject>) Database.query(scribe.toSoql());

    if (records.isEmpty()) {
      throw new QueryException('No records found for query: ' + scribe.toSoql());
    }
    return new Entry(records[0]);
  }

  /**
   * @inheritDoc
   */
  public SObject firstOrFailAsSObject(Scribe scribe) {
    String method = ('firstOrFailAsSObject(Scribe scribe)');
    if (scribe == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'scribe', null).fire();
    }

    List<SObject> records = (List<SObject>) Database.query(scribe.toSoql());
    if (records.isEmpty()) {
      throw new QueryException('No records found for query: ' + scribe.toSoql());
    }
    return records[0];
  }

  /**
   * @inheritDoc
   */
  public SObject doInsert(SObject record) {
    String method = ('doInsert(SObject record)');
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', record).fire();
    }

    insert record;
    return record;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doInsert(List<SObject> records) {
    String method = ('doInsert(List<SObject> records)');
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }
    sortToPreventChunkingErrors(records);
    insert records;
    return records;
  }

  /**
   * @inheritDoc
   */
  public SObject doUpdate(SObject record) {
    String method = ('doUpdate(SObject record)');
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    update record;
    return record;
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpdate(IEntry entry) {
    String method = ('doUpdate(IEntry entry)');
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }
    SObject record = entry.getRecord();
    update record;
    return new Entry(record);
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpdate(List<SObject> records) {
    String method = ('doUpdate(List<SObject> records)');
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }
    sortToPreventChunkingErrors(records);
    update records;
    return records;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpdate(List<IEntry> entries) {
    String method = ('doUpdate(List<IEntry> entries)');
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    if (entries.isEmpty()) {
      return new List<IEntry>();
    }
    List<SObject> records = new List<SObject>();
    for (IEntry entry : entries) {
      records.add(entry.getRecord());
    }
    sortToPreventChunkingErrors(records);
    update records;
    List<IEntry> updatedEntries = new List<IEntry>();
    for (SObject record : records) {
      updatedEntries.add(new Entry(record));
    }
    return updatedEntries;
  }

  /**
   * @inheritDoc
   */
  public SObject doUpsert(SObject record) {
    String method = ('doUpsert(SObject record)');
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    upsert record;
    return record;
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpsert(IEntry entry) {
    String method = ('doUpsert(IEntry entry)');
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    SObject record = entry.getRecord();
    upsert record;
    return new Entry(record);
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpsert(List<SObject> records) {
    String method = ('doUpsert(List<SObject> records)');
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    sortToPreventChunkingErrors(records);
    upsert records;
    return records;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpsert(List<IEntry> entries) {
    String method = ('doUpsert(List<IEntry> entries)');
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    if (entries.isEmpty()) {
      return new List<IEntry>();
    }
    List<SObject> records = new List<SObject>();
    for (IEntry entry : entries) {
      records.add(entry.getRecord());
    }
    sortToPreventChunkingErrors(records);
    upsert records;
    List<IEntry> upsertedEntries = new List<IEntry>();
    for (SObject record : records) {
      upsertedEntries.add(new Entry(record));
    }
    return upsertedEntries;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(SObject record) {
    String method = ('doDelete(SObject record)');
    if (record == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'record', null).fire();
    }

    delete record;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(IEntry entry) {
    String method = ('doDelete(IEntry entry)');
    if (entry == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entry', null).fire();
    }

    delete entry.getRecord();
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<SObject> records) {
    String method = ('doDelete(List<SObject> records)');
    if (records == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'records', null).fire();
    }

    delete records;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<IEntry> entries) {
    String method = ('doDelete(List<IEntry> entries)');
    if (entries == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'entries', null).fire();
    }

    if (entries.isEmpty()) {
      System.debug('No entries to delete.');
      return;
    }
    List<SObject> records = new List<SObject>();
    for (IEntry entry : entries) {
      records.add(entry.getRecord());
    }
    delete records;
  }

  /**
   * @inheritDoc
   */
  private void sortToPreventChunkingErrors(List<SObject> records) {
    if (records.size() >= MAX_DML_CHUNKING) {
      records.sort();
    }
  }
}
