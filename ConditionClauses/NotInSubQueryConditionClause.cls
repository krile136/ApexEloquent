public with sharing class NotInSubQueryConditionClause extends AbstractConditionClause {
  private final Scribe subQueryScribe;

  public NotInSubQueryConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Scribe subQueryScribe
  ) {
    super(sObjectType, fieldMap, field);
    this.subQueryScribe = subQueryScribe;
  }

  public override String build() {
    return String.format('{0} NOT IN ({1})', new List<String>{ this.field, this.subQueryScribe.toSoql() });
  }

  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new NotInSubQueryConditionClause(sObjectType, fieldMap, this.field, this.subQueryScribe);
  }

  public override IConditionClause overrideField(String field) {
    return new NotInSubQueryConditionClause(this.sObjectType, this.fieldMap, field, this.subQueryScribe);
  }

  private String checkAndCast() {
    return '';
  }
}
