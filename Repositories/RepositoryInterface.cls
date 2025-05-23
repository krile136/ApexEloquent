public interface RepositoryInterface {
  /**
  * Executes SOQL and retrieves the results.
  * If the number of retrieved records is 0, an empty list is returned.
  *
  * @param query: SOQL query
  * @return Retrieved results
  */
  List<SObject> get(Query query);

  /**
  * Executes SOQL and retrieves the results as Evaluator.
  * If the number of retrieved records is 0, an empty list is returned.
  *
  * @param query: SOQL query
  * @return Retrieved results as Evaluator
  */
  List<EvaluatorInterface> getAsEvaluators(Query query);

  /**
  * Executes SOQL and returns the first record.
  * If the number of retrieved records is 0, null is returned.
  *
  * @param query SOQL query
  * @return Retrieved result
  */
  SObject first(Query query);

  /**
  * Executes SOQL and returns the first record as Evaluator.
  * If the number of retrieved records is 0, null is returned.
  *
  * @param query SOQL Query
  * @return Retrieved result as Evaluator
  */
  EvaluatorInterface firstAsEvaluator(Query query);

  /**
  * Executes SOQL and returns the first record.
  * If the number of retrieved records is 0, an exception is thrown.
  *
  * @param query SOQL Query
  * @return Retrieved result
  * @throws QueryException If the number of retrieved records is 0
  */
  SObject firstOrFail(Query query);

  /**
  * Executes SOQL and returns the first record as Evaluator.
  * If the number of retrieved records is 0, an exception is thrown.
  *
  * @param query SOQL Query
  * @return Retrieved result as Evaluator
  * @throws QueryException If the number of retrieved records is 0
  */
  EvaluatorInterface firstOrFailAsEvaluator(Query query);

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
