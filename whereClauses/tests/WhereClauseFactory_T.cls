@isTest(seeAllData=false)
public with sharing class WhereClauseFactory_T {
  public static testMethod void testCreate() {
    String testTitle;
    WhereClauseInterface whereClause;
    Schema.SObjectType source = Opportunity.SObjectType;

    Query query = new Query();
    whereClause = WhereClauseFactory.create(source, 'field', '=', query);
    System.assert(whereClause instanceof SubQueryWhereClause);

    List<Object> values = new List<Object>{ 'value1', 'value2' };
    whereClause = WhereClauseFactory.create(source, 'field', 'IN', values);
    System.assert(whereClause instanceof ListWhereClause);

    whereClause = WhereClauseFactory.create(source, 'field', '=', 'value');
    System.assert(whereClause instanceof ObjectWhereClause);
  }
}
