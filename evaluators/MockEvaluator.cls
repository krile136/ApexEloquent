public with sharing class MockEvaluator extends AbstractEvaluator {
  private final Map<String, Object> fieldToValue;

  /**
   * constructor
   *
   * @param record SObject
   */
  @TestVisible
  public MockEvaluator(SObject record) {
    this(record, new Map<String, Object>());
  }

  /**
   * constructor
   *
   * @param record SObject
   * @param fieldToValue Map of field name to value
   */
  @TestVisible
  public MockEvaluator(SObject record, Map<String, Object> fieldToValue) {
    super(record);
    this.fieldToValue = fieldToValue;
  }

  /**
   * constructor with picked fields and relation fields
   *
   * @param record SObject
   * @param pickedFields List of field names to be picked
   * @param pickedRelationFields Map of relation names to be picked
   * @param fieldToValue Map of field name to value
   */
  private MockEvaluator(
    SObject record,
    List<String> pickedFields,
    Map<String, Object> pickedRelationFields,
    Map<String, Object> fieldToValue
  ) {
    super(record, pickedFields, pickedRelationFields);
    this.fieldToValue = fieldToValue;
  }

  /**
   * @inheritDoc
   */
  public override Object get(String fieldName) {
    if (fieldToValue.containsKey(fieldName)) {
      return fieldToValue.get(fieldName);
    }
    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.get(fieldName);
  }

  /**
   * @inheritDoc
   */
  public override Object getRelation(String relationName) {
    if (fieldToValue.containsKey(relationName)) {
      return fieldToValue.get(relationName);
    }
    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.getRelation(relationName);
  }

  /**
   * @inheritDoc
   */
  public override Object getRelationAsEvaluator(String relationName) {
    if (fieldToValue.containsKey(relationName)) {
      return fieldToValue.get(relationName);
    }

    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.getRelationAsEvaluator(relationName);
  }

  /**
   * @inheritDoc
   */
  public override Object getParent(String parentFieldName) {
    if (fieldToValue.containsKey(parentFieldName)) {
      return fieldToValue.get(parentFieldName);
    }
    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.getParent(parentFieldName);
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface getParentAsEvaluator(String parentFieldName) {
    if (fieldToValue.containsKey(parentFieldName)) {
      return (EvaluatorInterface) fieldToValue.get(parentFieldName);
    }
    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.getParentAsEvaluator(parentFieldName);
  }

  /**
   * @inheritDoc
   */
<<<<<<< Updated upstream
  public override List<Object> getChildren(String childObjectName) {
    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.getChildren(childObjectName);
||||||| Stash base
  public SObject getRecord() {
    return record;
=======
  public override List<Object> getChildren(String childObjectName) {
    if (fieldToValue.containsKey(childObjectName)) {
      return (List<Object>) fieldToValue.get(childObjectName);
    }
    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.getChildren(childObjectName);
>>>>>>> Stashed changes
  }

  /**
   * @inheritDoc
   */
<<<<<<< Updated upstream
  public override List<EvaluatorInterface> getChildrenAsEvaluators(String childObjectName) {
    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.getChildrenAsEvaluators(childObjectName);
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface setRecord(SObject record) {
    return new MockEvaluator(record, this.fieldToValue);
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface setPickedFields(
    List<String> pickedFields,
    Map<String, Object> pickedRelationFields
  ) {
    return new MockEvaluator(this.record, pickedFields, pickedRelationFields, this.fieldToValue);
||||||| Stash base
  public EvaluatorInterface setRecord(SObject record) {
    return new MockEvaluator(this.record, this.fieldToValue);
=======
  public override List<EvaluatorInterface> getChildrenAsEvaluators(String childObjectName) {
    if (fieldToValue.containsKey(childObjectName)) {
      return (List<EvaluatorInterface>) fieldToValue.get(childObjectName);
    }
    Evaluator evaluator = new Evaluator(this.record);
    return evaluator.getChildrenAsEvaluators(childObjectName);
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface setRecord(SObject record) {
    return new MockEvaluator(record, this.fieldToValue);
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface setPickedFields(
    List<String> pickedFields,
    Map<String, Object> pickedRelationFields
  ) {
    return new MockEvaluator(this.record, pickedFields, pickedRelationFields, this.fieldToValue);
>>>>>>> Stashed changes
  }
}
