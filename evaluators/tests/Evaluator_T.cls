@isTest
public with sharing class Evaluator_T {
  @isTest
  public static void testGet() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act
    String name = (String) evaluator.get('Name');

    // Assert
    Assert.areEqual('Test Account', name);
  }

  @isTest
  static void testGet_WhenFieldNameIsNotExist_ThenErrorOccured() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act / Assert
    try {
      Object nonExistField = evaluator.get('NonExistField');
      Assert.fail('Expected an exception to be thrown');
    } catch (Exception e) {
      Assert.areEqual('The specified field does not exist in the object\'s fields. object name: Account, field name: NonExistField', e.getMessage());
    }
  }

  @isTest
  static void testGet_WhenFieldValueIsNull_ThenReturnNull() {
    // Arrange
    SObject record = new Account();
    Evaluator evaluator = new Evaluator(record);

    // Act
    Object fieldValue = evaluator.get('Name');

    // Assert
    Assert.isNull(fieldValue, 'Expected field value to be null');
  }

  @isTest
  static void testGetRelation_WhenChildrenIsNull_ThenReturnChildObjectIsEmpty() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act
    List<SObject> childRecords = (List<SObject>) evaluator.getRelation('Opportunity');

    // Assert
    Assert.isTrue(childRecords.isEmpty(), 'Expected child records to be empty');
  }

  @isTest 
  static void testGetRelation_WhenParentIsNull_ThenReturnParentObjectIsNull() {
    // Arrange
    SObject record = new Opportunity(Name = 'Test Opportunity');
    Evaluator evaluator = new Evaluator(record);

    // Act
    SObject parentRecord = (SObject) evaluator.getRelation('AccountId');

    // Assert
    Assert.isNull(parentRecord, 'Expected parent record to be null');
  }

  @isTest
  static void testGetRelation_WhenRelationNameIsNotChildrenOrParent_ThenErrorOccured() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act / Assert
    try {
      Object nonExistRelation = evaluator.getRelation('NonExistRelation');
      Assert.fail('Expected an exception to be thrown');
    } catch (Exception e) {
      System.debug(e.getStackTraceString());
      Assert.areEqual('The relationName is not children Object Name or Parent relationId field Name. object name: Account, relation name NonExistRelation', e.getMessage());
    }
  }

  @isTest
  static void testGetRelationAsEvaluator_WhenChildrenIsNull_ThenReturnChildObjectIsEmpty() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act
    List<EvaluatorInterface> childRecords = (List<EvaluatorInterface>) evaluator.getRelationAsEvaluator('Opportunity');

    // Assert
    Assert.isTrue(childRecords.isEmpty(), 'Expected child records to be empty');
  }

  @isTest
  static void testRelationAsEvalutor_WhenParentIsNull_ThenReturnParentObjectIsNull() {
    // Arrange
    SObject record = new Opportunity(Name = 'Test Opportunity');
    Evaluator evaluator = new Evaluator(record);

    // Act
    EvaluatorInterface parentRecord = (EvaluatorInterface) evaluator.getRelationAsEvaluator('AccountId');

    // Assert
    Assert.isNull(parentRecord, 'Expected parent record to be null');
  }

  @isTest
  static void testGetRelationAsEvaluator_WhenRelationNameIsNotChildrenOrParent_ThenErrorOccured() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act / Assert
    try {
      Object nonExistRelation = evaluator.getRelationAsEvaluator('NonExistRelation');
      Assert.fail('Expected an exception to be thrown');
    } catch (Exception e) {
      System.debug(e.getStackTraceString());
      Assert.areEqual('The relationName is not children Object Name or Parent relationId field Name. object name: Account, relation name NonExistRelation', e.getMessage());
    }
  }

  @isTest
  public static void testGetId() {
    // Arrange
    SObject record = new Account(Id = '001000000000000');
    Evaluator evaluator = new Evaluator(record);

    // Act
    Id accId = evaluator.getId();

    // Assert
    System.assertEquals('001000000000000', accId);
  }

  @isTest
  public static void testGetName() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act
    String name = evaluator.getName();

    // Assert
    System.assertEquals('Test Account', name);
  }

  @isTest
  public static void testGetRecord() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act
    SObject returnedRecord = evaluator.getRecord();

    // Assert
    System.assertEquals(record, returnedRecord);
  }

  @isTest
  static void testGetParent_WhenParentIsNull_ThenReturnNull() {
    // Arrange
    SObject record = new Opportunity(Name = 'Test Opportunity');
    Evaluator evaluator = new Evaluator(record);

    // Act
    Account parentAccount = (Account) evaluator.getParent('AccountId');

    // Assert
    Assert.isNull(parentAccount, 'Expected parent account to be null');
  }

  @isTest
  static void testGetParentAsEvaluator_WhenParentIsNull_ThenReturnNull() {
    // Arrange
    SObject record = new Opportunity(Name = 'Test Opportunity');
    Evaluator evaluator = new Evaluator(record);

    // Act
    EvaluatorInterface parentEvaluator = evaluator.getParentAsEvaluator('AccountId');

    // Assert
    Assert.isNull(parentEvaluator, 'Expected parent evaluator to be null');
  }

  @isTest
  static void testGetChildren_WhenChildrenAreNull_ThenReturnEmptyList() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act
    List<Object> children = evaluator.getChildren('Contact');

    // Assert
    Assert.isTrue(children.isEmpty(), 'Expected children list to be empty');
  }

  @isTest
  static void testGetChildrenAsEvaluators_WhenChildrenAreNull_ThenReturnEmptyList() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act
    List<EvaluatorInterface> childrenEvaluators = evaluator.getChildrenAsEvaluators('Contact');

    // Assert
    Assert.isTrue(childrenEvaluators.isEmpty(), 'Expected children evaluators list to be empty');
  }

  @isTest
  static void testGetParent_WhenFieldNameDoesNotExist_ThenErrorOccurred() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act / Assert
    try {
      Object parent = evaluator.getParent('NonExistentField');
      Assert.fail('Expected an exception to be thrown');
    } catch (Exception e) {
      Assert.areEqual('The specified parentFieldName does not exist in the object\'s fields. object name: Account, field name: NonExistentField', e.getMessage());
    }
  }

  @isTest
  static void testGetParent_WhenFieldIsNotReferenceType_ThenErrorOccurred() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act / Assert
    try {
      Object parent = evaluator.getParent('Name');
      Assert.fail('Expected an exception to be thrown');
    } catch (Exception e) {
      Assert.areEqual('The specified parentFieldName is not a reference type. object name: Account, field name: Name', e.getMessage());
    }
  }

  @isTest
  static void testGetParentAsEvaluator_WhenFieldNameDoesNotExist_ThenErrorOccurred() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act / Assert
    try {
      EvaluatorInterface parentEvaluator = evaluator.getParentAsEvaluator('NonExistentField');
      Assert.fail('Expected an exception to be thrown');
    } catch (Exception e) {
      Assert.areEqual('The specified parentFieldName does not exist in the object\'s fields. object name: Account, field name: NonExistentField', e.getMessage());
    }
  }

  @isTest
  static void testGetChildren_WhenChildObjectNameDoesNotExist_ThenErrorOccurred() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act / Assert
    try {
      List<Object> children = evaluator.getChildren('NonExistentChildObject');
      Assert.fail('Expected an exception to be thrown');
    } catch (Exception e) {
      Assert.areEqual('The specified childObjectName does not exist in the object\'s child relationships. object name: Account, child name: NonExistentChildObject', e.getMessage());
    }
  }

  @isTest
  static void testGetChildrenAsEvaluators_WhenChildObjectNameDoesNotExist_ThenErrorOccurred() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act / Assert
    try {
      List<EvaluatorInterface> childrenEvaluators = evaluator.getChildrenAsEvaluators('NonExistentChildObject');
      Assert.fail('Expected an exception to be thrown');
    } catch (Exception e) {
      Assert.areEqual('The specified childObjectName does not exist in the object\'s child relationships. object name: Account, child name: NonExistentChildObject', e.getMessage());
    }
  }

}
