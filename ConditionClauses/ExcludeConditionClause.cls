public with sharing class ExcludeConditionClause extends AbstractConditionClause {
  private final List<String> values;

  public ExcludeConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    List<String> values
  ) {
    super(sObjectType, fieldMap, field);
    this.values = values;
  }

  public override String build() {
    return String.format('{0} EXCLUDES ({1})', new List<String>{ this.field, this.checkAndCast() });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new ExcludeConditionClause(sObjectType, fieldMap, this.field, this.values);
  }

  private String checkAndCast() {
    List<String> castedValues = new List<String>();
    for (Object value : this.values) {
      castedValues.add('\'' + value + '\'');
    }

    return String.join(castedValues, ', ');
  }
}
