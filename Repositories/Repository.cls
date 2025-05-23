public with sharing class Repository implements RepositoryInterface {
  private final Integer MAX_DML_CHUNKING = 10;

  /**
   * @inheritDoc
   */
  public List<SObject> get(Query query) {
    String soql = query.toSoql();
    return (List<SObject>) Database.query(soql);
  }

  /**
   * @inheritDoc
   */
  public List<EvaluatorInterface> getAsEvaluators(Query query) {
    List<SObject> records = get(query);
    List<EvaluatorInterface> evaluators = new List<EvaluatorInterface>();
    for (SObject record : records) {
      evaluators.add(new Evaluator(record));
    }
    return evaluators;
  }

  /**
   * @inheritDoc
   */
  public SObject first(Query query) {
    List<SObject> records = get(query);
    if (records.isEmpty()) {
      return null;
    }
    return records[0];
  }

  /**
   * @inheritDoc
   */
  public Evaluator firstAsEvaluator(Query query) {
    List<SObject> records = get(query);
    if (records.isEmpty()) {
      return null;
    }
    return new Evaluator(records[0]);
  }

  /**
   * @inheritDoc
   */
  public SObject firstOrFail(Query query) {
    List<SObject> records = get(query);
    if (records.isEmpty()) {
      throw new QueryException('No records found for query: ' + query.toSoql());
    }
    return records[0];
  }

  /**
   * @inheritDoc
   */
  public Evaluator firstOrFailAsEvaluator(Query query) {
    List<SObject> records = get(query);
    if (records.isEmpty()) {
      throw new QueryException('No records found for query: ' + query.toSoql());
    }
    return new Evaluator(records[0]);
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
