public with sharing class WhereClauseFactory {
  public static WhereClauseInterface create(Schema.SObjectType sObjectType, String field, String operator, Object value) {
    if (value instanceof Query) {
      return new SubQueryWhereClause(sObjectType, null, field, operator, (Query) value);
    }
    return new ObjectWhereClause(sObjectType, null, field, operator, value);
  }

  public static WhereClauseInterface create(Schema.SObjectType sObjectType, String field, String operator, List<Object> values) {
    return new ListWhereClause(sObjectType, null, field, operator, values);
  }

}
