@isTest(seeAllData=false)
public with sharing class SubQueryWhereClause_T {
  @isTest
  static void testBuild() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSource.getDescribe().fields.getMap();
    Schema.SObjectType contactSource = Contact.getSObjectType();
    Map<String, Schema.SObjectField> contactFieldMap = contactSource.getDescribe().fields.getMap();
    Schema.SObjectType accountSource = Account.SObjectType;
    Query query = (new Query()).pick('Id').source(Account.getSObjectType()).condition('Name', '=', 'Test');
    WhereClauseInterface whereClause = new SubQueryWhereClause(contactSource, contactFieldMap, 'AccountId', 'IN', query);
    whereClause = whereClause.overrideMetaData(oppSource, oppFieldMap);

    // Act
    String build = whereClause.build();

    // Assert
    String expected = 'AccountId IN (SELECT id FROM Account WHERE (Name = \'Test\'))';
    Assert.areEqual(expected, build);
  }
}
