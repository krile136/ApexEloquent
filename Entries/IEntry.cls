public Interface IEntry {
  /**
   * get SObject field value.
   *
   * @param fieldName field name
   * @return field value
   */
  Object get(String fieldName);

  /**
   * get parent SObject as Evaluator.
   *
   * @param parentFieldName parent relationId field name
   * @return parent SObject as Entry 
   */
  IEntry getParent(String parentIdFieldName);

  /**
   * get child SObject list.
   *
   * @param childObjectName child SObject name
   * @return child SObject list
   */
  List<IEntry> getChildren(String childObjectName);

  /**
  * get related SObject list through a junction object.
  *
  * @param junctionObjectName junction object Name
  * @param relatedKey related SObject key field name in the junction object
  * @return related SObject list
  */
  List<IEntry> getThrough(String junctionObjectName, String relatedKey);

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
  IEntry setRecord(SObject record);

  /**
   * set picked fields and relation fields.
   *
   * @param FieldStructure fieldStructure
   * @return EvaluatorInterface
   */
  IEntry setFieldStructure(FieldStructure fieldStructure);

  /**
   * set DescribeSObjectResult for relation query
   *
   * @param describeResult Schema.DescribeSObjectResult
   */
  void setDescribeResult(Schema.DescribeSObjectResult describeResult);
}
