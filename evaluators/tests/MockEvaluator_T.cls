@isTest
public with sharing class MockEvaluator_T {
  
  @isTest
  public static void testGet() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    MockEvaluator evaluator = new MockEvaluator(record);
    
    // Act
    String name = (String) evaluator.get('Name');
    
    // Assert
    System.assertEquals('Test Account', name);
  }

  @isTest
  public static void testGetWithSchemaField() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    MockEvaluator evaluator = new MockEvaluator(record);
    
    // Act
    String name = (String) evaluator.get(Account.Name);
    
    // Assert
    System.assertEquals('Test Account', name);
  }

  @isTest
  public static void testGetUsingEvaluator() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Name' => 'Mocked Account'
    };
    MockEvaluator evaluator = new MockEvaluator(record, fieldToValue);
    
    // Act
    String name = (String) evaluator.get('Name');
    
    // Assert
    System.assertEquals('Mocked Account', name);
  }
  
  @isTest
  public static void testGetWithSchemaFieldUsingEvaluator() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Name' => 'Mocked Account'
    };
    MockEvaluator evaluator = new MockEvaluator(record, fieldToValue);
    
    // Act
    String name = (String) evaluator.get(Account.Name);
    
    // Assert
    System.assertEquals('Mocked Account', name);
  }

  @isTest
  public static void testGetId() {
    // Arrange
    SObject record = new Account(Id = '001000000000000');
    MockEvaluator evaluator = new MockEvaluator(record);
    
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

}
