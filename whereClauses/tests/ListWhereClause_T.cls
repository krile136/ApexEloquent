@isTest
public with sharing class ListWhereClause_T {
  @isTest
  static void testBuild() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = oppSource.getDescribe().fields.getMap();
    List<Id> ids = new List<Id>{ '006000000000000', '006000000000001' };
    WhereClauseInterface whereClause = new ListWhereClause(oppSource, null, 'Id', 'IN', ids);
    whereClause = whereClause.overrideMetaData(oppSource, fieldMap);

    // Act
    String build = whereClause.build();

    // Assert
    String expected = 'Id IN (\'006000000000000AAA\', \'006000000000001AAA\')';
    System.assertEquals(expected, build);
  }
}
