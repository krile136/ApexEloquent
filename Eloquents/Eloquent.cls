public with sharing class Eloquent implements IEloquent{
  private final Integer MAX_DML_CHUNKING = 10;

  /**
   * @inheritDoc
   */
  public List<IEntry> get(Scribe scribe) {
    List<IEntry> entries = new List<IEntry>();
    for(SObject record : (List<SObject>) Database.query(scribe.toSoql())) {
      entries.add(new Entry(record));
    }

    return entries;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> getAsSObject(Scribe scribe) {
    return (List<SObject>) Database.query(scribe.toSoql());
  }

  /**
   * @inheritDoc
   */
  public IEntry first(Scribe scribe) {
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
    insert record;
    return record;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doInsert(List<SObject> records) {
    sortToPreventChunkingErrors(records);
    insert records;
    return records;
  }

  /**
   * @inheritDoc
   */
  public SObject doUpdate(SObject record) {
    update record;
    return record;
  }

  /**
   * @inheritDoc
   */
  public List<SObject> doUpdate(List<SObject> records) {
    sortToPreventChunkingErrors(records);
    update records;
    return records;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(SObject record) {
    delete record;
  }

  /**
   * @inheritDoc
   */
  public void doDelete(List<SObject> records) {
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
