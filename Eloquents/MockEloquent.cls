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
  private Boolean shouldThrowException = false;

  @TestVisible
  private Scribe scribe;

  @TestVisible
  private List<SObject> upsertedRecords = new List<SObject>();

  /**
   * constructor
   */
  public MockEloquent() {
    this.entries = new List<IEntry>();
    this.insertCount = 0;
    this.scribe = null;
    this.shouldThrowException = false;
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
    this.shouldThrowException = false;
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
    this.shouldThrowException = false;
  }

  /**
   * Constructor for forcing an exception
   *
   * @param shouldThrow Set to true to make methods throw an exception
   */
  public MockEloquent(Boolean shouldThrow) {
    this.entries = new List<IEntry>();
    this.insertCount = 0;
    this.scribe = null;
    this.shouldThrowException = shouldThrow;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> get(Scribe scribe) {
    if (this.shouldThrowException) {
      throw new QueryException('Test Exception from MockEloquent.get()');
    }
    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    List<IEntry> result = new List<IEntry>();
    for (IEntry entry : this.entries) {
      result.add(entry.setFieldStructure(fieldStructure));
    }
    return result;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> getAggregate(Scribe scribe) {
    if (this.shouldThrowException) {
      throw new QueryException('Test Exception from MockEloquent.getAggregate()');
    }

    if (!scribe.isAggregate()) {
      throw new QueryException(
        'The provided Scribe instance does not represent an aggregate query: ' + scribe.toSoql()
      );
    }

    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    List<IEntry> result = new List<IEntry>();
    for (IEntry entry : this.entries) {
      result.add(entry.setFieldStructure(fieldStructure));
    }
    return result;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> getAsSObject(Scribe scribe) {
    if (this.shouldThrowException) {
      throw new QueryException('Test Exception from MockEloquent.getAsSObject()');
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
    if (this.shouldThrowException) {
      throw new QueryException('Test Exception from MockEloquent.first()');
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
    if (this.shouldThrowException) {
      throw new QueryException('Test Exception from MockEloquent.firstAsSObject()');
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
    if (this.shouldThrowException) {
      throw new QueryException('Test Exception from MockEloquent.firstOrFail()');
    }
    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    if (this.entries.isEmpty()) {
      throw new QueryException('No records found for query: ' + scribe.toSoql());
    }
    return this.entries[0].setFieldStructure(fieldStructure);
  }

  /**
   * @inheritDoc
   */
  public SObject firstOrFailAsSObject(Scribe scribe) {
    if (this.shouldThrowException) {
      throw new QueryException('Test Exception from MockEloquent.firstOrFailAsSObject()');
    }
    this.scribe = scribe;
    String soql = scribe.toSoql(); // for showing and validate SOQL
    if (this.entries.isEmpty()) {
      throw new QueryException('No records found for query: ' + scribe.toSoql());
    }
    return this.entries[0].getRecord();
  }

  /**
   * @inheritDoc
   */
  public SObject doInsert(SObject record) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doInsert()');
    }
    if (record == null) {
      throw new DmlException('Cannot insert null record');
    }
    record.Id = this.generateId(record);
    this.upsertedRecords.add(record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doInsert(List<SObject> records) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doInsert()');
    }
    if (records == null || records.isEmpty()) {
      throw new DmlException('Cannot insert null or empty records');
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
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doUpdate()');
    }
    if (record == null) {
      throw new DmlException('Cannot update null record');
    }
    this.upsertedRecords.add(record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public IEntry doUpdate(IEntry entry) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doUpdate()');
    }
    if (entry == null) {
      throw new DmlException('Cannot update null entry');
    }
    this.upsertedRecords.add(entry.getRecord());
    return entry;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpdate(List<SObject> records) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doUpdate()');
    }
    if (records == null || records.isEmpty()) {
      throw new DmlException('Cannot update null or empty records');
    }
    this.upsertedRecords.addAll(records);
    return records;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> doUpdate(List<IEntry> entries) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doUpdate()');
    }
    if (entries == null || entries.isEmpty()) {
      return new List<IEntry>();
    }
    
    for (IEntry entry : entries) {
      this.upsertedRecords.add(entry.getRecord());
    }

    return entries;
  }

  /**
   * @inheritDoc
   */
  public SObject doUpsert(SObject record) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doUpsert()');
    }
    if (record == null) {
      throw new DmlException('Cannot upsert null record');
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
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doUpsert()');
    }
    if (entry == null || entry.getRecord() == null) {
      throw new DmlException('Cannot upsert null entry');
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
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doUpsert()');
    }
    if (records == null || records.isEmpty()) {
      throw new DmlException('Cannot upsert null or empty records');
    }
    for (SObject record : records) {
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
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doUpsert()');
    }
    if (entries == null || entries.isEmpty()) {
      throw new DmlException('Cannot upsert null or empty entries');
    }
    for (IEntry entry : entries) {
      if (entry == null || entry.getRecord() == null) {
        throw new DmlException('Cannot upsert null entry or record');
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
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doDelete()');
    }
    if (record == null) {
      throw new DmlException('Cannot delete null record');
    }
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(IEntry entry) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doDelete()');
    }
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<SObject> records) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doDelete()');
    }
    if (records == null || records.isEmpty()) {
      throw new DmlException('Cannot delete null or empty records');
    }
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<IEntry> entries) {
    if (this.shouldThrowException) {
      throw new DmlException('Test Exception from MockEloquent.doDelete()');
    }
    return;
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
}
