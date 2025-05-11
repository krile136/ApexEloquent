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
    Assert.areEqual('Test Account', name);
  }

  @isTest
  public static void testGetChildrenAsEvaluator() {
    // Arrange
    MockEvaluator evaluator = new MockEvaluator(
      new Account(Name = 'Test Account'),
      new Map<String, Object> {
        'Opportunity' => new List<EvaluatorInterface> {
          new MockEvaluator(new Opportunity(Name = 'TestOpp1')),
          new MockEvaluator(new Opportunity(Name = 'TestOpp2'))
        }
      }
    );

    // Act
    List<EvaluatorInterface> childEvaluators = evaluator.getChildrenAsEvaluator('Opportunity');

    // Assert
    Assert.areEqual(2, childEvaluators.size());
  }

  @isTest
  public static void testGetChildrenAsEvaluatorWithoutMock() {
    // Arrange
    MockEvaluator evaluator = new MockEvaluator(
      new Account(Name = 'Test Account'),
      new Map<String, Object> () 
    );

    // Act
    List<EvaluatorInterface> childEvaluators = evaluator.getChildrenAsEvaluator('Opportunity');

    // Assert
    Assert.isNull(childEvaluators);
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
    Assert.areEqual('Mocked Account', name);
  }

  @isTest
  public static void testGetId() {
    // Arrange
    SObject record = new Account(Id = '001000000000000');
    MockEvaluator evaluator = new MockEvaluator(record);
    
    // Act
    Id accId = evaluator.getId();
    
    // Assert
    Assert.areEqual('001000000000000', accId);
  }

  @isTest
  public static void testGetName() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    MockEvaluator evaluator = new MockEvaluator(record);

    // Act
    String name = evaluator.getName();

    // Assert
    Assert.areEqual('Test Account', name);
  }

  @isTest
  public static void testGetRecord() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    MockEvaluator evaluator = new MockEvaluator(record);

    // Act
    SObject returnedRecord = evaluator.getRecord();

    // Assert
    Assert.areEqual(record, returnedRecord);
  }
}
