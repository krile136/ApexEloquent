public with sharing class IsNullConditionClause extends AbstractConditionClause {
  public IsNullConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field
  ) {
    super(sObjectType, fieldMap, field);
  }

  public override String build() {
    return String.format('{0} = {1}', new List<String>{ this.field, 'NULL' });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new IsNullConditionClause(sObjectType, fieldMap, this.field);
  }

  public override IConditionClause overrideField(String field) {
    return new IsNullConditionClause(this.sObjectType, this.fieldMap, field);
  }

  private String checkAndCast() {
    return '';
  }
}
