@isTest(seeAllData=false)
public with sharing class SubQueryWhereClause_T {
  public static testMethod void testBuild() {
    String testtitle;
    WhereClauseInterface whereClause;
    String build;
    String expected;

    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSource.getDescribe().fields.getMap();
    Schema.SObjectType contactSource = Contact.getSObjectType();
    Map<String, Schema.SObjectField> contactFieldMap = contactSource.getDescribe().fields.getMap();
    Schema.SObjectType accountSource = Account.SObjectType;

    testTitle = '正常系: Where句が組み立てられる';
    Query query = (new Query()).pick('Id').source(accountSource).condition('Name', '=', 'Test');
    whereClause = new SubQueryWhereClause(contactSource, contactFieldMap, 'AccountId', 'IN', query);
    whereClause = whereClause.overrideMetaData(oppSource, oppFieldMap);
    build = whereClause.build();
    expected = 'AccountId IN (SELECT Id FROM Account WHERE (Name = \'Test\'))';
    Assert.areEqual(expected, build, testTitle);
  }
}
