public with sharing class ListWhereClause  extends AbstractWhereClause {
  private final List<Object> values;

  public ListWhereClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    String operator,
    List<Object> values
  ) {
    super(sObjectType, fieldMap, field, operator);
    this.values = values;
  }

  public override WhereClauseInterface overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap) {
    return new ListWhereClause(sObjectType, fieldMap, this.field, this.operator, this.values);
  }

  protected override String generate() {
    return '(' + this.checkAndCast() + ')';
  }

  private String checkAndCast() {
    Schema.DisplayType fieldType = this.getFieldType(field);

    List<String> castedValues = new List<String>();
    for (Object value : this.values) {
      String valueString = this.formatAndCastToString(value);
      if (this.TYPES_REQUIRING_SINGLE_QUOTES.contains(fieldType)) {
        castedValues.add('\'' + valueString + '\'');
      } else {
        castedValues.add(valueString);
      }
    }

    return String.join(castedValues, ', ');
  }
}
