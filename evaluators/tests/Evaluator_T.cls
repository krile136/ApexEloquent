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
    System.assertEquals('Test Account', name);
  }


  @isTest
  public static void testGetChildren() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Evaluator evaluator = new Evaluator(record);

    // Act
    List<SObject> childEvaluators = (List<SObject>) evaluator.get('Opportunity');

    // Assert
    Assert.isNull(childEvaluators);
  }

  @isTest
  public static void testGetChildrenAsEvaluator() {
    // Arrange
    Evaluator evaluator = new Evaluator(new Account(Name = 'Test Account'));

    // Act
    List<EvaluatorInterface> childEvaluators = evaluator.getChildrenAsEvaluator('Opportunity');

    // Assert
    Assert.isNull(childEvaluators);
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
}
