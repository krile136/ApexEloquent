@isTest(seeAllData=false)
public with sharing class ParentClause_T {
  @isTest
  static void testParentClauseBuild() {
    // Arrange
    ParentClause parentClause = new ParentClause('OwnerId', (new Query()).pick('Id').pick('Name'));
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    String actual = parentClause.buildSelectClause(oppFieldMap, null);

    // Assert
    String expected = 'Owner.Id, Owner.Name';
    Assert.areEqual(expected, actual);
  }

  @isTest
  static void testNestedParentClauseBuild() {
    // Arrange
    ParentClause parentClause = new ParentClause(
      'ContractId',
      (new Query()).pick('Id').pick('Name').withParents(new parentClause('AccountId', (new Query()).pick('Id').pick('Name')))
    );
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    String actual = parentClause.buildSelectClause(oppFieldMap, null);

    // Assert
    String expected = 'Contract.Id, Contract.Name, Contract.Account.Id, Contract.Account.Name';
    Assert.areEqual(expected, actual);
  }

  @isTest
  static void testFailWhenRelationIdFieldNotExists() {
    // Arrange
    ParentClause parentClause = new ParentClause('nonExistRelationId', (new Query()).pick('Id').pick('Name'));
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act / Assert
    try {
      String actual = parentClause.buildSelectClause(oppFieldMap, null);
      Assert.fail();
    } catch (QueryException e) {
      String expectedMessage = 'The specified relation ID field does not exist in the object\'s fields';
      Assert.isTrue(e.getMessage().contains(expectedMessage));
    }
  }

  @isTest
  static void testFailWhenRelationIdFieldNotReferenceType() {
    // Arrange
    ParentClause parentClause = new ParentClause('Name', (new Query()).pick('Id').pick('Name'));
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act / Assert
    try {
      String actual = parentClause.buildSelectClause(oppFieldMap, null);
      Assert.fail();
    } catch (QueryException e) {
      String expectedMessage = 'The specified relation ID field is not of reference type';
      Assert.isTrue(e.getMessage().contains(expectedMessage));
    }
  }

  @isTest
  static void testFailWhenRelationIdFieldNotHaveRelationshipName() {
    // Arrange
    ParentClause parentClause = new ParentClause('ContactId', (new Query()).pick('Id').pick('Name'));
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act / Assert
    try {
      String actual = parentClause.buildSelectClause(oppFieldMap, null);
      Assert.fail();
    } catch (QueryException e) {
      String expectedMessage = 'The specified relation ID field does not have a relationship name';
      Assert.isTrue(e.getMessage().contains(expectedMessage));
    }
  }

  @isTest
  static void testBuildAndWhereClause() {
    // Arrange
    ParentClause parentClause = new ParentClause(
      'OwnerId',
      (new Query()).pick('Id').pick('Name').condition('Id', '=', '001000000000000').condition('Name', '=', 'Test')
    );
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    String actual = parentClause.buildWhereClause(oppFieldMap, null);

    // Assert
    String expected = 'Owner.Id = \'001000000000000\' AND Owner.Name = \'Test\'';
    Assert.areEqual(expected, actual);
  }

  @isTest
  static void testNestedParentClauseBuildAndWhere() {
    // Arrange
    ParentClause parentClause = new ParentClause(
      'ContractId',
      (new Query())
        .pick('Id')
        .pick('Name')
        .condition('Id', '=', '001000000000000')
        .condition('Name', '=', 'Test')
        .withParents(
          new ParentClause('AccountId', (new Query()).pick('Id').pick('Name').condition('Id', '=', '001000000000001').condition('Name', '=', 'Test2'))
        )
    );
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    String actual = parentClause.buildWhereClause(oppFieldMap, null);

    // Assert
    String expected = 'Contract.Id = \'001000000000000\' AND Contract.Name = \'Test\' AND Contract.Account.Id = \'001000000000001\' AND Contract.Account.Name = \'Test2\'';
    Assert.areEqual(expected, actual);
  }

  @isTest
  static void testBuildOrWhereClause() {
    // Arrange
    ParentClause parentClause = new ParentClause(
      'OwnerId',
      (new Query()).pick('Id').pick('Name').orCondition('Id', '=', '001000000000000').orCondition('Name', '=', 'Test')
    );
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    String actual = parentClause.buildOrWhereClause(oppFieldMap, null);

    // Assert
    String expected = 'Owner.Id = \'001000000000000\' OR Owner.Name = \'Test\'';
    Assert.areEqual(expected, actual);
  }

  @isTest
  static void testNestedParentClauseBuildOrWhere() {
    // Arrange
    ParentClause parentClause = new ParentClause(
      'ContractId',
      (new Query())
        .pick('Id')
        .pick('Name')
        .orCondition('Id', '=', '001000000000000')
        .orCondition('Name', '=', 'Test')
        .withParents(
          new ParentClause('AccountId', (new Query()).pick('Id').pick('Name').orCondition('Id', '=', '001000000000001').orCondition('Name', '=', 'Test2'))
        )
    );
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    String actual = parentClause.buildOrWhereClause(oppFieldMap, null);

    // Assert
    String expected = 'Contract.Id = \'001000000000000\' OR Contract.Name = \'Test\' OR Contract.Account.Id = \'001000000000001\' OR Contract.Account.Name = \'Test2\'';
    Assert.areEqual(expected, actual);
  }
}
