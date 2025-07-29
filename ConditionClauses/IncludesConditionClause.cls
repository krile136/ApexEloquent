public with sharing class IncludesConditionClause extends AbstractConditionClause {
  private final List<String> values;

  public IncludesConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    List<String> values
  ) {
    super(sObjectType, fieldMap, field);
    this.values = values;
  }

  public override String build() {
    return String.format('{0} INCLUDES ({1})', new List<String>{ this.field, this.checkAndCast() });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new IncludesConditionClause(sObjectType, fieldMap, this.field, this.values);
  }

  private String checkAndCast() {
    List<String> castedValues = new List<String>();
    for (Object value : this.values) {
      castedValues.add('\'' + value + '\'');
    }

    return String.join(castedValues, ', ');
  }
}
