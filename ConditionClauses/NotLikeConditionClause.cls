public with sharing class NotLikeConditionClause extends AbstractConditionClause {
  private final Object value;

  public NotLikeConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Object value
  ) {
    super(sObjectType, fieldMap, field);
    this.value = value;
  }

  public override String build() {
    return String.format('(NOT {0} LIKE {1})', new List<String>{ this.field, this.checkAndCast() });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new NotLikeConditionClause(sObjectType, fieldMap, this.field, this.value);
  }

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
