@isTest(seeAllData=false)
public with sharing class WhereClauseFactory_T {

  @isTest(seeAllData=false)
  public static void testCreate() {
    String testTitle;
    WhereClauseInterface whereClause;
    Schema.SObjectType source = Opportunity.SObjectType;

    Query query = new Query();
    whereClause = WhereClauseFactory.create(source, 'field', '=', query);
    System.assert(whereClause instanceof SubQueryWhereClause);

    List<Object> values = new List<Object>{ 'value1', 'value2' };
    whereClause = WhereClauseFactory.create(source, 'field', 'IN', values);
    System.assert(whereClause instanceof ListWhereClause);

    Set<Id> ids = new Set<Id>{ '006000000000000', '006000000000001' };
    whereClause = WhereClauseFactory.create(source, 'field', 'IN', ids);
    System.assert(whereClause instanceof ListWhereClause);

    whereClause = WhereClauseFactory.create(source, 'field', '=', 'value');
    System.assert(whereClause instanceof ObjectWhereClause);
  }
}
