public with sharing class IsNotNullConditionClause extends AbstractConditionClause {
  public IsNotNullConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field
  ) {
    super(sObjectType, fieldMap, field);
  }

  public override String build() {
    return String.format('{0} != {1}', new List<String>{ this.field, 'NULL' });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new IsNotNullConditionClause(sObjectType, fieldMap, this.field);
  }

  private String checkAndCast() {
    return '';
  }
}
