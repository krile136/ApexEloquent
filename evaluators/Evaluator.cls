public with sharing class Evaluator implements EvaluatorInterface {
  private final SObject record;

  /**
   * constructor
   *
   * @param record SObject
   */
  public Evaluator(SObject record) {
    this.record = record;
  }

  /**
   * get field value
   *
   * @param fieldName field Name
   * @return field value
   */
  public Object get(String fieldName) {
    return record.get(fieldName);
  }

  /**
   * get field value
   *
   * @param field sObjectField
   * @return field value
   */
  public Object get(Schema.sObjectField field) {
    return record.get(field);
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
