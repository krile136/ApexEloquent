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
    String expected = 'Owner.id, Owner.name';
    Assert.areEqual(expected, actual);
  }

  @isTest
  static void testNestedParentClauseBuild() {
    // Arrange
    ParentClause parentClause = new ParentClause(
      'ContractId',
      (new Query())
        .pick('Id')
        .pick('Name')
        .withParents(new parentClause('AccountId', (new Query()).pick('Id').pick('Name')))
    );
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    String actual = parentClause.buildSelectClause(oppFieldMap, null);

    // Assert
    String expected = 'Contract.id, Contract.name, Contract.Account.id, Contract.Account.name';
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
          new ParentClause(
            'AccountId',
            (new Query())
              .pick('Id')
              .pick('Name')
              .condition('Id', '=', '001000000000001')
              .condition('Name', '=', 'Test2')
          )
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
      (new Query())
        .pick('Id')
        .pick('Name')
        .orCondition('Id', '=', '001000000000000')
        .orCondition('Name', '=', 'Test')
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
          new ParentClause(
            'AccountId',
            (new Query())
              .pick('Id')
              .pick('Name')
              .orCondition('Id', '=', '001000000000001')
              .orCondition('Name', '=', 'Test2')
          )
        )
    );
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    String actual = parentClause.buildOrWhereClause(oppFieldMap, null);

    // Assert
    String expected = 'Contract.Id = \'001000000000000\' OR Contract.Name = \'Test\' OR Contract.Account.Id = \'001000000000001\' OR Contract.Account.Name = \'Test2\'';
    Assert.areEqual(expected, actual);
  }

  @isTest
  static void testGetFieldStructure_WhenSelectAllFields_ThenGetAllFields() {
    // Arrange
    ParentClause parentClause = new ParentClause(
      'ContractId',
      (new Query()).pickAll().condition('Id', '=', '001000000000000')
    );
    Map<String, Schema.SObjectField> childrenFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    FieldStructure actual = parentClause.getFieldStructure(childrenFieldMap);

    // Assert
    List<String> expectedFields = new List<String>{ 'id', 'name', 'startdate', 'enddate', 'status' };
    for (String field : expectedFields) {
      Assert.isTrue(actual.hasField(field), 'Expected field ' + field + ' not found in picked fields');
    }
  }

  @isTest
  static void testGetFieldStructure_WhenSelectSpecificFields_ThenGetOnlyThoseFields() {
    // Arrange
    List<String> expectedFields = new List<String>{ 'Id', 'Name' };
    ParentClause parentClause = new ParentClause(
      'ContractId',
      (new Query()).pick(expectedFields).condition('Id', '=', '001000000000000')
    );
    Map<String, Schema.SObjectField> childrenFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    FieldStructure actual = parentClause.getFieldStructure(childrenFieldMap);

    // Assert
    Assert.isTrue(
      actual.getFieldCount() == expectedFields.size(),
      'Expected ' + expectedFields.size() + ' fields, but got ' + actual.getFieldCount()
    );
    for (String field : expectedFields) {
      field = field.toLowerCase();
      Assert.isTrue(actual.hasField(field), 'Expected field ' + field + ' not found in picked fields');
    }
  }

  @isTest
  static void testGetPickedFieldStructure_WhenParentNest_ThenGetNestedParentFields() {
    // Arrange
    List<String> contractFields = new List<String>{ 'Id', 'Name', 'ContractNumber', 'ContractTerm' };
    List<String> accountFields = new List<String>{ 'Id', 'Name', 'BillingAddress', 'Phone', 'Fax' };
    ParentClause parentClause = new ParentClause(
      'ContractId',
      (new Query())
        .pick(contractFields)
        .withParents(new ParentClause('AccountId', (new Query()).pick(accountFields)))
    );
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();

    // Act
    FieldStructure actual = parentClause.getFieldStructure(oppFieldMap);
    System.debug(actual);

    // Assert
    for(String contractField : contractFields) {
      contractField = contractField.toLowerCase();
      Assert.isTrue(actual.hasField(contractField), 'Expected contract field ' + contractField + ' not found in picked fields');
    }
    FieldStructure accountFieldStructure = actual.getRelationFieldStructure('AccountId');
    Assert.isNotNull(accountFieldStructure, 'Expected AccountId relation field structure not found');
    for(String accountField : accountFields) {
      accountField = accountField.toLowerCase();
      Assert.isTrue(accountFieldStructure.hasField(accountField), 'Expected account field ' + accountField + ' not found in picked fields');
    }
  }
}
