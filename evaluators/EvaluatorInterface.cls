public interface EvaluatorInterface {
  /**
   * get SObject field value.
   *
   * if you want to get child SObject, field name should be child SObject name.
   * example: Account has Opportunity as child, in this case, fieldName should be Opportunity.
   *
   * if you want to get parent SObject, field name should be parent relationId field name.
   * example: Opportunity has Account as Parent via accountId, in this case, fieldName should be accountId.
   *
   * @param fieldName field name
   * @return field value
   */
  Object get(String fieldName);

  /**
   * get relation Object as Evaluator.
   *
   * if you want to get child SObject, field name should be child SObject name.
   * example: Account has Opportunity as child, in this case, fieldName should be Opportunity.
   *
   * if you want to get parent SObject, field name should be parent relationId field name.
   * example: Opportunity has Account as Parent via accountId, in this case, fieldName should be accountId.
   *
   * @param relationName (child Object Name or parent relationId field name)
   * @return relation Object as Evaluator
   */
  Object getRelationAsEvaluator(String fieldName);

  /**
   * @deprecated
   * use getRelationAsEvaluator instead.
   *
   * if you want to get child SObject, field name should be child SObject name.
   * example: Account has Opportunity as child, in this case, fieldName should be Opportunity.
   *
   * @param fieldName field Name
   * @return field value
   */
  List<EvaluatorInterface> getChildrenAsEvaluator(String fieldName);

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
}
