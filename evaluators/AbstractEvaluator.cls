public with sharing abstract class AbstractEvaluator implements EvaluatorInterface {
  protected final SObject record;
  protected final List<String> pickedFields;
  protected final Map<String, Object> pickedRelationFields;

  /**
   * constructoor
   *
   * @param record SObject
   */
  protected AbstractEvaluator(SObject record) {
    this.record = record;
  }

  /**
   * constructor with picked fields and relation fields
   *
   * @param record SObject
   * @param pickedFields List of field names to be picked
   * @param pickedRelationFields Map of relation names to be picked
   */
  protected AbstractEvaluator(SObject record, List<String> pickedFields, Map<String, Object> pickedRelationFields) {
    this.record = record;
    this.pickedFields = pickedFields;
    this.pickedRelationFields = pickedRelationFields;
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

  // abstract methods to be implemented by subclasses
  public abstract Object get(String fieldName);
  public abstract Object getRelation(String relationName);
  public abstract Object getRelationAsEvaluator(String relationName);
  public abstract Object getParent(String parentFieldName);
  public abstract EvaluatorInterface getParentAsEvaluator(String parentFieldName);
  public abstract List<Object> getChildren(String childObjectName);
  public abstract List<EvaluatorInterface> getChildrenAsEvaluators(String childObjectName);
  public abstract EvaluatorInterface setRecord(SObject record);
  public abstract EvaluatorInterface setPickedFields(List<String> pickedFields, Map<String, Object> pickedRelationFields);
}
