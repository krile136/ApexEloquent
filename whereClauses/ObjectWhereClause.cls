public with sharing class ObjectWhereClause extends AbstractWhereClause {
  private final Object value;

  public ObjectWhereClause(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap, String field, String operator, Object value) {
    super(sObjectType, fieldMap, field, operator);
    this.value = value;
  }

  public override WhereClauseInterface overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap) {
    return new ObjectWhereClause(sObjectType, fieldMap, this.field, this.operator, this.value);
  }

  protected override String generate() {
    return this.checkAndCast();
  }

  private String checkAndCast() {
    Schema.DisplayType fieldType = this.getFieldType(field);

    if (value == null) {
      return 'null';
    }

    String valueString = this.formatAndCastToString(value);
    if (this.TYPES_REQUIRING_SINGLE_QUOTES.contains(fieldType)) {
      return '\'' + valueString + '\'';
    }

    return valueString;
  }
}
