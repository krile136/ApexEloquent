public interface EvaluatorInterface {
  /**
   * get SObject field value.
   *
   * @param fieldName field name
   * @return field value
   */
  Object get(String fieldName);

  /**
   * **Description**
   * Get relation Object.
   *
   * If you want to get `child SObject`, `relationName` should be `child SObject name`.
   * Example: Account has Opportunity as child. In this case, `relationName` should be `Opportunity`.
   *
   * If you want to get `parent SObject`, `relationName` should be parent `relationId field name`.
   * Example: Opportunity has Account as Parent via `accountId`. In this case, `relationName` should be `accountId`.
   *
   * **Note**
   * @param relationName (child Object Name or parent relationId field name)
   * @return relation Object as `Evaluator`
   */
  Object getRelation(String relationName);

  /**
   * get relation Object as Evaluator.
   *
   * if you want to get child SObject, relationName should be child SObject name.
   * example: Account has Opportunity as child, in this case, relationName should be `Opportunity`.
   *
   * if you want to get parent SObject, relationName should be parent relationId field name.
   * example: Opportunity has Account as Parent via accountId, in this case, relationName should be `accountId`.
   *
   * @param relationName (child Object Name or parent relationId field name)
   * @return relation Object as Evaluator
   */
  Object getRelationAsEvaluator(String fieldName);

  /**
   * get parent Object.
   *
   * @param parentFieldName parent relationId field name
   * @return parent Object
   */
  Object getParent(String parentFieldName);

  /**
   * get parent SObject as Evaluator.
   *
   * @param parentFieldName parent relationId field name
   * @return parent SObject as Evaluator
   */
  EvaluatorInterface getParentAsEvaluator(String parentFieldName);

  /**
   * get child SObject list.
   *
   * @param childObjectName child SObject name
   * @return child SObject list
   */
  List<Object> getChildren(String childObjectName);

  /**
   * get child SObject list as Evaluator.
   *
   * @param childObjectName child SObject name
   * @return child SObject list as Evaluator
   */
  List<EvaluatorInterface> getChildrenAsEvaluators(String childObjectName);

  /**
   * get Id
   *
   * @return Id
   */
  Id getId();

  /**
   * get Name
   *
   * @return Name
   */
  String getName();

  /**
   * get SObject
   *
   * @return SObject
   */
  SObject getRecord();

  /**
   * set Evaluatot SObject property
   *
   * @param record SObject
   * @return EvaluatorInterface
   */
  EvaluatorInterface setRecord(SObject record);

  /**
   * set picked fields and relation fields.
   *
   * @param pickedFields List of field names to be picked
   * @param pickedRelationFields Map of relation names to be picked
   * @return EvaluatorInterface
   */
  EvaluatorInterface setPickedFields(List<String> pickedFields, Map<String, Object> pickedRelationFields);
}
