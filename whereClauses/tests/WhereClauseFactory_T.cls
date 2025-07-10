@isTest(seeAllData=false)
public with sharing class WhereClauseFactory_T {
  @isTest
  static void testCreate_WhenSubQueryCondition_ThenReturnsSubQueryWhereClause() {
    // Arrange
    Schema.SObjectType source = Opportunity.SObjectType;
    Query query = new Query();

    // Act
    WhereClauseInterface whereClause = WhereClauseFactory.create(source, 'field', '=', query);

    // Assert
    Assert.isTrue(whereClause instanceof SubQueryWhereClause);
  }

  @isTest
  static void testCreate_WhenListConditionWithValues_ThenReturnsListWhereClause() {
    // Arrange
    Schema.SObjectType source = Opportunity.SObjectType;
    List<Object> values = new List<Object>{ 'value1', 'value2' };

    // Act
    WhereClauseInterface whereClause = WhereClauseFactory.create(source, 'field', 'IN', values);

    // Assert
    Assert.isTrue(whereClause instanceof ListWhereClause);
  }

  @isTest
  static void testCreate_WhenListConditionWithIds_ThenReturnsListWhereClause() {
    // Arrange
    Schema.SObjectType source = Opportunity.SObjectType;
    Set<Id> ids = new Set<Id>{ '006000000000000', '006000000000001' };

    // Act
    WhereClauseInterface whereClause = WhereClauseFactory.create(source, 'field', 'IN', ids);

    // Assert
    Assert.isTrue(whereClause instanceof ListWhereClause);
  }

  @isTest
  static void testCreate_WhenObjectCondition_ThenReturnsObjectWhereClause() {
    // Arrange
    Schema.SObjectType source = Opportunity.SObjectType;

    // Act
    WhereClauseInterface whereClause = WhereClauseFactory.create(source, 'field', '=', 'value');

    // Assert
    Assert.isTrue(whereClause instanceof ObjectWhereClause);
  }
}
