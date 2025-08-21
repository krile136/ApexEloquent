public with sharing class InSubQueryConditionClause extends AbstractConditionClause {
  private final Scribe subQueryScribe;

  public InSubQueryConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Scribe subQueryScribe
  ) {
    super(sObjectType, fieldMap, field);
    this.subQueryScribe = subQueryScribe;
  }

  public override String build() {
    return String.format('{0} IN ({1})', new List<String>{ this.field, this.subQueryScribe.toSoql() });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new InSubQueryConditionClause(sObjectType, fieldMap, this.field, this.subQueryScribe);
  }

  public override IConditionClause overrideField(String field) {
    return new InSubQueryConditionClause(this.sObjectType, this.fieldMap, field, this.subQueryScribe);
  }

  private String checkAndCast() {
    return '';
  }
}
