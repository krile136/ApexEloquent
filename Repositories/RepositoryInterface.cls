public interface RepositoryInterface {
  List<SObject> get(Query query);
  List<EvaluatorInterface> getAsEvaluators(Query query);
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
