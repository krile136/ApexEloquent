@isTest(seeAllData=false)
public with sharing class ListWhereClause_T {
  @isTest(seeAllData=false)
  public static void testBuild() {
    String testtitle;
    WhereClauseInterface whereClause;
    String build;
    String expected;

    testTitle = '正常系: Where句が組み立てられる';
    Schema.SObjectType sObjectType = Opportunity.SObjectType;
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<Id> ids = new List<Id>{ '006000000000000', '006000000000001' };
    Schema.SObjectType source = Opportunity.SObjectType;
    whereClause = new ListWhereClause(source, null, 'Id', 'IN', ids);
    whereClause = whereClause.overrideMetaData(source, fieldMap);
    build = whereClause.build();
    expected = 'Id IN (\'006000000000000AAA\', \'006000000000001AAA\')';
    System.assertEquals(expected, build, testTitle);
  }
}
