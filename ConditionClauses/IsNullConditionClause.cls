public with sharing class IsNullConditionClause extends AbstractConditionClause {

  /**
   * Constructor for IsNullConditionClause.
   *
   * @param sObjectType The SObject type for the condition.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the equality to null condition on.
   */
  public IsNullConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field
  ) {
    super(sObjectType, fieldMap, field);
  }

  /**
   * @inheritdoc
   */
  public override String build() {
    return String.format('{0} = {1}', new List<String>{ this.field, 'NULL' });
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new IsNullConditionClause(sObjectType, fieldMap, this.field);
  }

  /**
   * @inheritdoc
   */

  public override IConditionClause overrideField(String field) {
    return new IsNullConditionClause(this.sObjectType, this.fieldMap, field);
  }

  /**
   * check the value type and cast it to string for SOQL
   *
   * @return The value formatted as a SOQL-compatible string.
   */
  private String checkAndCast() {
    return '';
  }
}
