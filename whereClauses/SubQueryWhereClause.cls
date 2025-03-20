public with sharing class SubQueryWhereClause extends AbstractWhereClause {
  private final Query subQuery;

  public SubQueryWhereClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    String operator,
    Query subQuery
  ) {
    super(sObjectType, fieldMap, field, operator);
    this.subQuery = subQuery;
  }

  public override WhereClauseInterface overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap) {
    return new SubQueryWhereClause(sObjectType, fieldMap, this.field, this.operator, this.subQuery);
  }

  protected override String generate() {
    return '(' + this.subQuery.toSoql() + ')';
  }

  private String checkAndCast() {
    return null;
  }
}
