public with sharing class MockEvaluator implements EvaluatorInterface {
  private final SObject record;
  private final Map<String, Object> fieldToValue;

  /**
   * constructor
   *
   * @param record SObject
   */
  public MockEvaluator(SObject record) {
    this(record, new Map<String, Object>());
  }

  /**
   * constructor
   *
   * @param record SObject
   * @param fieldToValue Map of field name to value
   */
  public MockEvaluator(SObject record, Map<String, Object> fieldToValue) {
    this.record = record;
    this.fieldToValue = fieldToValue;
  }

  /**
   * @inheritDoc
   */
  public Object get(String fieldName) {
    if (fieldToValue.containsKey(fieldName)) {
      return fieldToValue.get(fieldName);
    }
    Evaluator evaluator = new Evaluator(record);
    return evaluator.get(fieldName);
  }

  /**
   * @inheritDoc
   */
  public Object getRelation(String relationName) {
    if (fieldToValue.containsKey(relationName)) {
      return fieldToValue.get(relationName);
    }
    Evaluator evaluator = new Evaluator(record);
    return evaluator.getRelation(relationName);
  }

  /**
   * @inheritDoc
   */
  public Object getRelationAsEvaluator(String relationName) {
    if(fieldToValue.containsKey(relationName)) {
      return fieldToValue.get(relationName);
    }

    Evaluator evaluator = new Evaluator(record);
    return evaluator.getRelationAsEvaluator(relationName);
  }

  /**
   * @inheritDoc
   */
  public Id getId() {
    return (Id) record.get('Id');
  }

  /**
   * @inheritDoc
   */
  public String getName() {
    return (String) record.get('Name');
  }

  /**
   * @inheritDoc
   */
  public SObject getRecord() {
    return record;
  }

  /**
   * @inheritDoc
   */
  public EvaluatorInterface setRecord(SObject record) {
    return new MockEvaluator(this.record, this.fieldToValue);
  }
}
