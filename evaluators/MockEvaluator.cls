public with sharing class MockEvaluator extends AbstractEvaluator {
  private final Map<String, Object> fieldToValue;

  /**
   * constructor
   *
   * @param record SObject
   */
  @TestVisible
  public MockEvaluator(SObject record) {
    super(record);
    this.fieldToValue = new Map<String, Object>();
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
   * @param fieldStructure FieldStructure containing picked fields and relations
   */
  @TestVisible
  public MockEvaluator(SObject record, FieldStructure fieldStructure) {
    super(record, fieldStructure);
    this.fieldToValue = new Map<String, Object>();
  }

  /**
   * constructor with picked fields and relation fields
   *
   * @param record SObject
   * @param pickedFields List of field names to be picked
   * @param pickedRelationFields Map of relation names to be picked
   * @param fieldToValue Map of field name to value
   */
  @TestVisible
  private MockEvaluator(SObject record, FieldStructure fieldStructure, Map<String, Object> fieldToValue) {
    super(record, fieldStructure);
    this.fieldToValue = fieldToValue;
  }

  /**
   * @inheritDoc
   */
  public override Object get(String fieldName) {
    this.validateFieldName(fieldName);

    if (fieldToValue.containsKey(fieldName)) {
      return fieldToValue.get(fieldName);
    }
    Evaluator evaluator = new Evaluator(this.record, this.fieldStructure);
    return evaluator.get(fieldName);
  }

  /**
   * @inheritDoc
   */
  public override Object getRelation(String relationName) {
    this.validateRelationName(relationName);

    if (fieldToValue.containsKey(relationName)) {
      return fieldToValue.get(relationName);
    }
    Evaluator evaluator = new Evaluator(this.record, this.fieldStructure);
    return evaluator.getRelation(relationName);
  }

  /**
   * @inheritDoc
   */
  public override Object getRelationAsEvaluator(String relationName) {
    this.validateRelationName(relationName);

    if (fieldToValue.containsKey(relationName)) {
      Object result = fieldToValue.get(relationName);
        FieldStructure relationFieldStructure = this.fieldStructure == null
          ? null
          : this.fieldStructure.getRelationFieldStructure(relationName);
      if(result instanceof EvaluatorInterface) {
        EvaluatorInterface resultEvaluator = (EvaluatorInterface) result;
        return resultEvaluator.setFieldStructure(relationFieldStructure);
      }else if(result instanceof List<EvaluatorInterface>) {
        List<EvaluatorInterface> evaluators = (List<EvaluatorInterface>) result;
        List<EvaluatorInterface> resultEvaluators = new List<EvaluatorInterface>();
        for (EvaluatorInterface evaluator : evaluators) {
          resultEvaluators.add(evaluator.setFieldStructure(relationFieldStructure));
        }
        return resultEvaluators;
      }
    }

    Evaluator evaluator = new Evaluator(this.record, this.fieldStructure);
    return evaluator.getRelationAsEvaluator(relationName);
  }

  /**
   * @inheritDoc
   */
  public override Object getParent(String parentFieldName) {
    this.validateRelationName(parentFieldName);

    if (fieldToValue.containsKey(parentFieldName)) {
      return fieldToValue.get(parentFieldName);
    }
    Evaluator evaluator = new Evaluator(this.record, this.fieldStructure);
    return evaluator.getParent(parentFieldName);
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface getParentAsEvaluator(String parentFieldName) {
    this.validateRelationName(parentFieldName);

    if (fieldToValue.containsKey(parentFieldName)) {
      EvaluatorInterface resultEvaluator = (EvaluatorInterface) fieldToValue.get(parentFieldName);
      FieldStructure parentFieldStructure = this.fieldStructure == null
        ? null
        : this.fieldStructure.getRelationFieldStructure(parentFieldName);
      return resultEvaluator.setFieldStructure(parentFieldStructure);
    }
    Evaluator evaluator = new Evaluator(this.record, this.fieldStructure);
    return evaluator.getParentAsEvaluator(parentFieldName);
  }

  /**
   * @inheritDoc
   */
  public override List<Object> getChildren(String childObjectName) {
    this.validateRelationName(childObjectName);

    if (fieldToValue.containsKey(childObjectName)) {
      return (List<Object>) fieldToValue.get(childObjectName);
    }
    Evaluator evaluator = new Evaluator(this.record, this.fieldStructure);
    return evaluator.getChildren(childObjectName);
  }

  /**
   * @inheritDoc
   */
  public override List<EvaluatorInterface> getChildrenAsEvaluators(String childObjectName) {
    this.validateRelationName(childObjectName);

    if (fieldToValue.containsKey(childObjectName)) {
      List<EvaluatorInterface> evaluators = (List<EvaluatorInterface>) fieldToValue.get(childObjectName);
      List<EvaluatorInterface> resultEvaluators = new List<EvaluatorInterface>();
      FieldStructure childFieldStructure = this.fieldStructure == null
        ? null
        : this.fieldStructure.getRelationFieldStructure(childObjectName);
      for (EvaluatorInterface evaluator : evaluators) {
        resultEvaluators.add(evaluator.setFieldStructure(childFieldStructure));
      }
      return resultEvaluators;
    }
    Evaluator evaluator = new Evaluator(this.record, this.fieldStructure);
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
  public override EvaluatorInterface setFieldStructure(FieldStructure fieldStructure) {
    return new MockEvaluator(this.record, fieldStructure, this.fieldToValue);
  }
}
