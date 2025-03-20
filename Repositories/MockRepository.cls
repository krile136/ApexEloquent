public with sharing class MockRepository implements RepositoryInterface {
  private final List<SObject> records;
  private Integer insertCount;

  public MockRepository() {
    this.records = new List<SObject>();
    this.insertCount = 0;
  }

  public MockRepository(SObject record) {
    if (record == null) {
      this.records = new List<SObject>();
    } else {
      this.records = new List<SObject>{ record };
    }
    this.insertCount = 0;
  }

  public MockRepository(List<SObject> records) {
    this.records = records;
    this.insertCount = 0;
  }

  public virtual List<SObject> get(Query query) {
    return this.records;
  }

  public virtual List<SObject> getOrFail(Query query) {
    if (this.records.isEmpty()) {
      throw new QueryException('No records found for query: ' + query.toSoql());
    }
    return this.records;
  }

  public virtual SObject first(Query query) {
    if (this.records.isEmpty()) {
      return null;
    }
    return this.records[0];
  }

  public virtual SObject firstOrFail(Query query) {
    if (this.records.isEmpty()) {
      throw new QueryException('No records found for query: ' + query.toSoql());
    }
    return this.records[0];
  }

  public virtual SObject doInsert(SObject record) {
    record.Id = this.genereteId(record);
    return record;
  }

  public virtual List<SObject> doInsert(List<SObject> records) {
    for (SObject record : records) {
      record.Id = this.genereteId(record);
    }
    return records;
  }

  public virtual SObject doUpdate(SObject record) {
    return record;
  }

  public virtual List<SObject> doUpdate(List<SObject> records) {
    return records;
  }

  public virtual void doDelete(SObject record) {
    return;
  }

  public virtual void doDelete(List<SObject> records) {
    return;
  }

  private String genereteId(SObject record) {
    String prefix = record.getSObjectType().getDescribe().getKeyPrefix();
    String generatedId = prefix + String.valueOf(this.insertCount).leftPad(12, '0');
    this.insertCount++;
    return generatedId;
  }
}
