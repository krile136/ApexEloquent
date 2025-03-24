public with sharing class Repository implements RepositoryInterface {
  private final Integer MAX_DML_CHUNKING = 10;

  /**
  * Executes SOQL and retrieves the results.
  *
  * @param query: SOQL query
  * @return Retrieved results
  */
  public List<SObject> get(Query query) {
    String soql = query.toSoql();
    return (List<SObject>) Database.query(soql);
  }

  /**
  * Executes SOQL and retrieves the results.
  * Throws an exception if the number of retrieved records is 0.
  *
  * @param query: SOQL query
  * @return Retrieved results
  * @throws QueryException If the number of retrieved records is 0
  */
  public List<SObject> getOrFail(Query query) {
    String soql = query.toSoql();
    List<SObject> objects = (List<SObject>) Database.query(soql);
    if (objects.isEmpty()) {
      throw new QueryException('No records found for query: ' + soql);
    }
    return objects;
  }

  /**
  * Executes SOQL and returns the first record.
  * Returns null if the number of retrieved records is 0.
  *
  * @param query SOQL query
  * @return Retrieved result
  */
  public SObject first(Query query) {
    List<SObject> records = get(query);
    if (records.isEmpty()) {
      return null;
    }
    return records[0];
  }


  /**
  * Executes SOQL and returns the first record.
  * Throws an exception if the number of retrieved records is 0.
  *
  * @param query SOQL query
  * @return Retrieved result
  * @throws QueryException If the number of retrieved records is 0
  */
  public SObject firstOrFail(Query query) {
    List<SObject> records = get(query);
    if (records.isEmpty()) {
      throw new QueryException('No records found for query: ' + query.toSoql());
    }
    return records[0];
  }

  /**
  * Inserts a record.
  *
  * @param record The record to insert
  * @return Inserted record
  */
  public SObject doInsert(SObject record) {
    insert record;
    return record;
  }

  /**
  * Inserts a list of records.
  *
  * @param records The list of records to insert
  * @return List of inserted records
  */
  public List<SObject> doInsert(List<SObject> records) {
    sortToPreventChunkingErrors(records);
    insert records;
    return records;
  }

  /**
  * Updates a record.
  *
  * @param record The record to update
  * @return Updated record
  */
  public SObject doUpdate(SObject record) {
    update record;
    return record;
  }

  /**
  * Updates a list of records.
  *
  * @param records The list of records to update
  * @return List of updated records
  */
  public List<SObject> doUpdate(List<SObject> records) {
    sortToPreventChunkingErrors(records);
    update records;
    return records;
  }

  /**
  * Deletes a record.
  *
  * @param record The record to delete
  */
  public void doDelete(SObject record) {
    delete record;
  }

  /**
  * Deletes a list of records.
  *
  * @param records The list of records to delete
  */
  public void doDelete(List<SObject> records) {
    delete records;
  }

  /**
  * Sorts to prevent chunking errors.
  *
  * @param records The list of records to sort
  */
  private void sortToPreventChunkingErrors(List<SObject> records) {
    if (records.size() >= MAX_DML_CHUNKING) {
      records.sort();
    }
  }
}
