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
   * This method is provided as an option.
   * Please limit its use to operations such as utilizing SObject methods
   * or performing update, insert, and other operations.
   *
   * @return SObject
   */
  SObject getRecord();

  EvaluatorInterface setRecord(SObject record);
}
