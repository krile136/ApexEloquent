public with sharing class GreaterThanConditionClause extends AbstractConditionClause {
  private final Object value;

  public GreaterThanConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Object value
  ) {
    super(sObjectType, fieldMap, field);
    this.value = value;
  }

  public override String build() {
    return String.format('{0} > {1}', new List<String>{ this.field,  this.checkAndCast() });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new GreaterThanConditionClause(sObjectType, fieldMap, this.field, this.value);
  }

  public override IConditionClause overrideField(String field) {
    return new GreaterThanConditionClause(this.sObjectType, this.fieldMap, field, this.value);
  }

  private String checkAndCast() {
    if (value == null) {
      throw new QueryException('Value cannot be null for GreaterThan condition. field: ' + field);
    }

    Schema.DisplayType fieldType = this.getFieldType(field);
    String valueString = this.formatAndCastToString(value);
    if (this.TYPES_REQUIRING_SINGLE_QUOTES.contains(fieldType)) {
      return '\'' + valueString + '\'';
    }

    return valueString;
  }
}
