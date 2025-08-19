public with sharing class MockEloquent implements IEloquent {
  private final List<IEntry> entries;
  private Integer insertCount;

  /**
   * constructor
   */
  public MockEloquent() {
    this.entries = new List<IEntry>();
    this.insertCount = 0;
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
  }

  /**
   * constructor with a list of SObjects
   *
   * @param records List<SObject> to be added
   */
  public MockEloquent(List<IEntry> entries) {
    this.entries = entries;
    this.insertCount = 0;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> get(Scribe scribe) {
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
  public IEntry first(Scribe scribe) {
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
  public IEntry firstOrFail(Scribe scribe) {
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
  public SObject doInsert(SObject record) {
    record.Id = this.genereteId(record);
    return record;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doInsert(List<SObject> records) {
    for (SObject record : records) {
      record.Id = this.genereteId(record);
    }
    return records;
  }

  /**
   * @inheritDoc
   */
  public SObject doUpdate(SObject record) {
    return record;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpdate(List<SObject> records) {
    return records;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(SObject record) {
    return;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<SObject> records) {
    return;
  }

  /**
   * generate a mock Id for the record
   *
   * @param record SObject to be inserted
   * @return generated Id
   */
  private String genereteId(SObject record) {
    String prefix = record.getSObjectType().getDescribe().getKeyPrefix();
    String generatedId = prefix + String.valueOf(this.insertCount).leftPad(12, '0');
    this.insertCount++;
    return generatedId;
  }
}
