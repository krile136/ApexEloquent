public with sharing abstract class AbstractEvaluator implements EvaluatorInterface {
  protected final SObject record;
  protected final FieldStructure fieldStructure;

  /**
   * constructoor
   *
   * @param record SObject
   */
  protected AbstractEvaluator(SObject record) {
    this.record = record;
    this.fieldStructure = null;
  }

  /**
   * constructor with picked fields and relation fields
   *
   * @param record SObject
   * @param pickedFields List of field names to be picked
   * @param pickedRelationFields Map of relation names to be picked
   */
  protected AbstractEvaluator(SObject record, FieldStructure fieldStructure) {
    this.record = record;
    this.fieldStructure = fieldStructure;
  }

  /**
    * validate the field name.
    *
    * @param fieldName field name to be validated
    * @throws QueryException if the field is not picked in SOQL builder
    */
  protected void validateFieldName(String fieldName) {
    if(this.fieldStructure == null) {
      return;
    }

    String lowerCaseFieldName = fieldName.toLowerCase();
    if (fieldStructure.hasField(lowerCaseFieldName)) {
      return;
    }

    throw new QueryException(
      'The specified field is not picked in SOQL builder. object name: ' +
        this.record.getSObjectType().getDescribe().getName() +
        ', field name: ' +
        fieldName
    );
  }

  /**
    * validate the relation name.
    *
    * @param relationName relation name to be validated
    * @throws QueryException if the relation is not exist in SOQL builder
    */
  protected void validateRelationName(String relationName) {
    if(this.fieldStructure == null) {
      return;
    }

    if (fieldStructure.hasRelation(relationName)) {
      return;
    }

    throw new QueryException(
      'The specified relation is not exist in SOQL builder. object name: ' +
        this.record.getSObjectType().getDescribe().getName() +
        ', relation name: ' +
        relationName
    );
  }

  /**
   * @inheritDoc
   */
  public Id getId() {
    this.validateFieldName('id');
    return (Id) record.get('Id');
  }

  /**
   * @inheritDoc
   */
  public String getName() {
    this.validateFieldName('name');
    return (String) record.get('Name');
  }

  /**
   * @inheritDoc
   */
  public SObject getRecord() {
    return record;
  }

  // abstract methods to be implemented by subclasses
  public abstract Object get(String fieldName);
  public abstract Object getRelation(String relationName);
  public abstract Object getRelationAsEvaluator(String relationName);
  public abstract Object getParent(String parentFieldName);
  public abstract EvaluatorInterface getParentAsEvaluator(String parentFieldName);
  public abstract List<Object> getChildren(String childObjectName);
  public abstract List<EvaluatorInterface> getChildrenAsEvaluators(String childObjectName);
  public abstract EvaluatorInterface setRecord(SObject record);
  public abstract EvaluatorInterface setFieldStructure(FieldStructure fieldStructure);
}
