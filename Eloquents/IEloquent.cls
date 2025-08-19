public interface IEloquent {
  /**
  * Executes SOQL and retrieves the results.
  * If the number of retrieved records is 0, an empty list is returned.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved results as a list of Entry objects
  */
  List<IEntry> get(Scribe scribe);

  /**
  * Executes SOQL and returns the first record.
  * If the number of retrieved records is 0, null is returned.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved result as an Entry object
  */
  IEntry first(Scribe scribe);

  /**
  * Executes SOQL and returns the first record.
  * If the number of retrieved records is 0, an exception is thrown.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved result as an Entry object
  * @throws QueryException If the number of retrieved records is 0
  */
  IEntry firstOrFail(Scribe scribe);

  /**
  * Inserts a record and returns the inserted record.
  *
  * @param record SObject to be inserted
  * @return Inserted SObject
  */
  SObject doInsert(SObject record);

  /**
  * Inserts a list of records and returns the inserted records.
  *
  * @param records List of SObjects to be inserted
  * @return List of inserted SObjects
  */
  List<SObject> doInsert(List<SObject> records);

  /**
  * Updates a record and returns the updated record.
  *
  * @param record SObject to be updated
  * @return Updated SObject
  */
  SObject doUpdate(SObject record);

  /**
  * Updates a list of records and returns the updated records.
  *
  * @param records List of SObjects to be updated
  * @return List of updated SObjects
  */
  List<SObject> doUpdate(List<SObject> records);

  /**
  * Deletes a record.
  *
  * @param record SObject to be deleted
  */
  void doDelete(SObject record);

  /**
  * Deletes a list of records.
  *
  * @param records List of SObjects to be deleted
  */
  void doDelete(List<SObject> records);
}
