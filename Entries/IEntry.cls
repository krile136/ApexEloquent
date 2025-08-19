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
}
