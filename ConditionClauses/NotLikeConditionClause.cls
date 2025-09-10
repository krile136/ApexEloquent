public with sharing class NotLikeConditionClause extends AbstractConditionClause {
  private final Object value;

  /**
   * Constructor for NotLikeConditionClause.
   *
   * @param sObjectType The Schema.SObjectType of the object.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the NotLIKE condition on.
   * @param value The value to compare against.
   */
  public NotLikeConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Object value
  ) {
    super(sObjectType, fieldMap, field);
    this.value = value;
  }

  /**
   * @inheritDoc
   */
  public override String build() {
    return String.format('(NOT {0} LIKE {1})', new List<String>{ this.field, this.checkAndCast() });
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new NotLikeConditionClause(sObjectType, fieldMap, this.field, this.value);
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideField(String field) {
    return new NotLikeConditionClause(this.sObjectType, this.fieldMap, field, this.value);
  }

  /**
   * check the value type and cast it to string for SOQL
   *
   * @return The value formatted as a SOQL-compatible string.
   */
  private String checkAndCast() {
    if (value == null) {
      throw new QueryException('Value cannot be null for NOT LIKE condition. field: ' + field);
    }

    Schema.DisplayType fieldType = this.getFieldType(field);
    String valueString = this.formatAndCastToString(value);
    if (this.TYPES_REQUIRING_SINGLE_QUOTES.contains(fieldType)) {
      return '\'' + valueString + '\'';
    }

    return valueString;
  }
}
