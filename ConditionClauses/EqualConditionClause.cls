public with sharing class EqualConditionClause extends AbstractConditionClause {
  private final Object value;

  /**
   * Constructor for EqualConditionClause.
   *
   * @param sObjectType The SObject type for the condition.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the equality condition on.
   * @param value The value to compare against.
   */
  public EqualConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Object value
  ) {
    super(sObjectType, fieldMap, field);
    this.value = value;
  }

  /**
  * @inheritdoc
  */
  public override String build() {
    return String.format('{0} = {1}', new List<String>{ this.field, this.checkAndCast() });
  }

  /**
  * @inheritdoc
  */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new EqualConditionClause(sObjectType, fieldMap, this.field, this.value);
  }

  /**
  * @inheritdoc
  */
  public override IConditionClause overrideField(String field) {
    return new EqualConditionClause(this.sObjectType, this.fieldMap, field, this.value);
  }

  /**
  * check the value type and cast it to string for SOQL
  *
  * @return The value formatted as a SOQL-compatible string.
  */
  private String checkAndCast() {
    Schema.DisplayType fieldType = this.getFieldType(field);

    if (value == null) {
      return 'NULL';
    }

    String valueString = this.formatAndCastToString(value);
    if (this.TYPES_REQUIRING_SINGLE_QUOTES.contains(fieldType)) {
      return '\'' + valueString + '\'';
    }

    return valueString;
  }
}
