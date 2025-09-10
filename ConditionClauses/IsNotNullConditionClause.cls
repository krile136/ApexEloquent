public with sharing class IsNotNullConditionClause extends AbstractConditionClause {

  /**
   * Constructor for IsNotNullConditionClause.
   *
   * @param sObjectType The SObject type for the condition.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the not equality to null condition on.
   */
  public IsNotNullConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field
  ) {
    super(sObjectType, fieldMap, field);
  }

  /**
   * @inheritDoc
   */
  public override String build() {
    return String.format('{0} != {1}', new List<String>{ this.field, 'NULL' });
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new IsNotNullConditionClause(sObjectType, fieldMap, this.field);
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideField(String field) {
    return new IsNotNullConditionClause(this.sObjectType, this.fieldMap, field);
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
