public with sharing class MockRepository implements RepositoryInterface {
  private final List<SObject> records;
  private final List<EvaluatorInterface> evaluators;
  private Integer insertCount;

  public MockRepository() {
    this.records = new List<SObject>();
    this.insertCount = 0;
  }

  public MockRepository(SObject record) {
    if (record == null) {
      this.records = new List<SObject>();
      this.evaluators = new List<EvaluatorInterface>();
    } else {
      this.records = new List<SObject>{ record };
      this.evaluators = new List<EvaluatorInterface>{ new MockEvaluator(record) };
    }
    this.insertCount = 0;
  }

  public MockRepository(List<SObject> records) {
    this.records = records;
    List<EvaluatorInterface> evaluators = new List<EvaluatorInterface>();
    for(SObject record : records) {
      evaluators.add(new MockEvaluator(record));
    }
    this.evaluators = evaluators;
    this.insertCount = 0;
  }

  public MockRepository(EvaluatorInterface evaluator){
    if (evaluator == null) {
      this.records = new List<SObject>();
      this.evaluators = new List<EvaluatorInterface>();
    } else {
      this.records = new List<SObject>{ evaluator.getRecord() };
      this.evaluators = new List<EvaluatorInterface>{ evaluator };
    }
    this.insertCount = 0;
  }

  public MockRepository(List<EvaluatorInterface> evaluators) {
    this.evaluators = evaluators;
    List<SObject> records = new List<SObject>();
    for(EvaluatorInterface evaluator : evaluators) {
      records.add(evaluator.getRecord());
    }
    this.records = records;
    this.insertCount = 0;
  }

  public List<SObject> get(Query query) {
    return this.records;
  }

  public List<EvaluatorInterface> getAsEvaluators(Query query) {
    return this.evaluators;
  }

  public SObject first(Query query) {
    if (this.records.isEmpty()) {
      return null;
    }
    return this.records[0];
  }

  public EvaluatorInterface firstAsEvaluator(Query query) {
    if (this.evaluators.isEmpty()) {
      return null;
    }
    return this.evaluators[0];
  }

  public SObject firstOrFail(Query query) {
    if (this.records.isEmpty()) {
      throw new QueryException('No records found for query: ' + query.toSoql());
    }
    return this.records[0];
  }

  public EvaluatorInterface firstOrFailAsEvaluator(Query query) {
    if (this.evaluators.isEmpty()) {
      throw new QueryException('No records found for query: ' + query.toSoql());
    }
    return this.evaluators[0];
  }

  public SObject doInsert(SObject record) {
    record.Id = this.genereteId(record);
    return record;
  }

  public List<SObject> doInsert(List<SObject> records) {
    for (SObject record : records) {
      record.Id = this.genereteId(record);
    }
    return records;
  }

  public SObject doUpdate(SObject record) {
    return record;
  }

  public List<SObject> doUpdate(List<SObject> records) {
    return records;
  }

  public void doDelete(SObject record) {
    return;
  }

  public void doDelete(List<SObject> records) {
    return;
  }

  private String genereteId(SObject record) {
    String prefix = record.getSObjectType().getDescribe().getKeyPrefix();
    String generatedId = prefix + String.valueOf(this.insertCount).leftPad(12, '0');
    this.insertCount++;
    return generatedId;
  }
}
