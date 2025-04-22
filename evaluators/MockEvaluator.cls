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
   * get field value
   *
   * @param fieldName field Name
   * @return field value
   */
  public Object get(String fieldName) {
    if (fieldToValue.containsKey(fieldName)) {
      return fieldToValue.get(fieldName);
    }
    return record.get(fieldName);
  }

  /**
   * get field value
   *
   * @param field sObjectField
   * @return field value
   */
  public Object get(Schema.sObjectField field) {
    String fieldName = field.getDescribe().getName();
    return this.get(fieldName);
  }

  /**
   * get Id
   *
   * @return Id
   */
  public Id getId() {
    return (Id) record.get('Id');
  }

  /**
   * get Name
   *
   * @return Name
   */
  public String getName() {
    return (String) record.get('Name');
  }

  /**
   * get SObject
   *
   * This method is provided as an option.
   * Please limit its use to operations such as utilizing SObject methods
   * or performing update, insert, and other operations.
   */
  public SObject getRecord() {
    return record;
  }
}
