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
  EvaluatorInterface firstAsEvaluator(Query query);
  SObject firstOrFail(Query query);
  EvaluatorInterface firstOrFailAsEvaluator(Query query);
  SObject doInsert(SObject record);
  List<SObject> doInsert(List<SObject> records);
  SObject doUpdate(SObject record);
  List<SObject> doUpdate(List<SObject> records);
  void doDelete(SObject record);
  void doDelete(List<SObject> records);
}
