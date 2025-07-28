public with sharing class EqualConditionClause extends AbstractConditionClause {
  private final Object value;

  public EqualConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Object value
  ) {
    super(sObjectType, fieldMap, field);
    this.value = value;
  }

  public override String build() {
    return String.format('{0} {1} {2}', new List<String>{ this.field, '=', this.checkAndCast() });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new EqualConditionClause(sObjectType, fieldMap, this.field, this.value);
  }

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
