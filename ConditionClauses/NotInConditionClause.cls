public with sharing class NotInConditionClause extends AbstractConditionClause {
  private final List<Object> values;

  public NotInConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Object values
  ) {
    super(sObjectType, fieldMap, field);
    if (values instanceof Set<Id>) {
      this.values = new List<Id>((Set<Id>) values);
    } else {
      this.values = (List<Object>) values;
    }
  }

  public override String build() {
    return String.format('{0} NOT IN ({1})', new List<String>{ this.field, this.checkAndCast() });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new NotInConditionClause(sObjectType, fieldMap, this.field, this.values);
  }

  private String checkAndCast() {
    Schema.DisplayType fieldType = this.getFieldType(field);
    List<String> castedValues = new List<String>();
    for (Object value : this.values) {
      if (value == null) {
        castedValues.add('NULL');
        continue;
      }
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
