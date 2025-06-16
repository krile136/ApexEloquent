@isTest
public with sharing class MockEvaluator_T {
  @isTest
  public static void testGet() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'name' });
    MockEvaluator evaluator = new MockEvaluator(record, fieldStructure);

    // Act
    String name = (String) evaluator.get('Name');

    // Assert
    Assert.areEqual('Test Account', name);
  }

  @isTest
  public static void testGetUsingEvaluator() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'Name' => 'Mocked Account' };
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'name' });
    MockEvaluator evaluator = new MockEvaluator(record, fieldStructure, fieldToValue);

    // Act
    String name = (String) evaluator.get('Name');

    // Assert
    Assert.areEqual('Mocked Account', name);
  }

  @isTest
  static void testGetRelation_WhenChildren_ThenReturnChildren() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'Opportunity' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(
      new Account(Name = 'Test Account'),
      fieldStructure,
      new Map<String, Object>{
        'Opportunity' => new List<Opportunity>{
          new Opportunity(Name = 'TestOpp1'),
          new Opportunity(Name = 'TestOpp2')
        }
      }
    );


    // Act
    List<Opportunity> children = (List<Opportunity>) evaluator.getRelation('Opportunity');

    // Assert
    Assert.areEqual(2, children.size());
  }

  @isTest
  static void testGetRelation_WhenChildrenIsNull_ThenReturnEmptyList() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'Opportunity' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(new Account(Name = 'Test Account'), fieldStructure);

    // Act
    List<Opportunity> children = (List<Opportunity>) evaluator.getRelation('Opportunity');

    // Assert
    Assert.areEqual(0, children.size());
  }

  @isTest
  static void testGetRelation_WhenParent_ThenReturnParent() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'AccountId' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    Account parent = new Account(Name = 'Parent Account');
    MockEvaluator evaluator = new MockEvaluator(
      new Opportunity(Name = 'Test Opportunity'),
      fieldStructure,
      new Map<String, Object>{ 'AccountId' => parent }
    );

    // Act
    Account parentAccount = (Account) evaluator.getRelation('AccountId');

    // Assert
    Assert.areEqual(parent, parentAccount);
  }

  @isTest
  static void testGetRelation_WhenParentIsNull_ThenReturnNull() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'AccountId' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(new Opportunity(Name = 'Test Opportunity'), fieldStructure);

    // Act
    Account parentAccount = (Account) evaluator.getRelation('AccountId');

    // Assert
    System.assertEquals(null, parentAccount);
  }

  @isTest
  static void testGetRelationAsEvaluator_WhenChildren_ThenReturnChildrenEvaluator() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'Opportunity' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(
      new Account(Name = 'Test Account'),
      fieldStructure,
      new Map<String, Object>{
        'Opportunity' => new List<MockEvaluator>{
          new MockEvaluator(new Opportunity(Name = 'TestOpp1')),
          new MockEvaluator(new Opportunity(Name = 'TestOpp2'))
        }
      }
    );

    // Act
    List<EvaluatorInterface> childrenEvaluators = (List<EvaluatorInterface>) evaluator.getRelationAsEvaluator(
      'Opportunity'
    );

    // Assert
    Assert.areEqual(2, childrenEvaluators.size());
  }

  @isTest
  static void testGetRelationAsEvaluator_WhenChildrenIsNull_ThenReturnEmptyList() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'Opportunity' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(new Account(Name = 'Test Account'), fieldStructure);

    // Act
    List<EvaluatorInterface> childrenEvaluators = (List<EvaluatorInterface>) evaluator.getRelationAsEvaluator(
      'Opportunity'
    );

    // Assert
    Assert.areEqual(0, childrenEvaluators.size());
  }

  @isTest
  static void testGetRelationAsEvaluator_WhenParent_ThenReturnParentEvaluator() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'AccountId' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    Account parent = new Account(Name = 'Parent Account');
    MockEvaluator evaluator = new MockEvaluator(
      new Opportunity(Name = 'Test Opportunity'),
      fieldStructure,
      new Map<String, Object>{ 'AccountId' => new MockEvaluator(parent) }
    );

    // Act
    EvaluatorInterface parentEvaluator = (EvaluatorInterface) evaluator.getRelationAsEvaluator('AccountId');

    // Assert
    Assert.areEqual(parent, parentEvaluator.getRecord());
  }

  @isTest
  static void testGetRelationAsEvaluator_WhenParentIsNull_ThenReturnNull() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'AccountId' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(new Opportunity(Name = 'Test Opportunity'), fieldStructure);

    // Act
    EvaluatorInterface parentEvaluator = (EvaluatorInterface) evaluator.getRelationAsEvaluator('AccountId');

    // Assert
    System.assertEquals(null, parentEvaluator);
  }

  @isTest
  public static void testGetId() {
    // Arrange
    SObject record = new Account(Id = '001000000000000');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id' });
    MockEvaluator evaluator = new MockEvaluator(record, fieldStructure);

    // Act
    Id accId = evaluator.getId();

    // Assert
    Assert.areEqual('001000000000000', accId);
  }

  @isTest
  public static void testGetName() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'name' });
    MockEvaluator evaluator = new MockEvaluator(record, fieldStructure);

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

  @isTest
  static void testGetParent_WhenParentExists_ThenReturnParentObject() {
    // Arrange
    Account parent = new Account(Name = 'Parent Account');
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'AccountId' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(
      new Opportunity(Name = 'Test Opportunity'),
      fieldStructure,
      new Map<String, Object>{ 'AccountId' => parent }
    );

    // Act
    Account parentAccount = (Account) evaluator.getParent('AccountId');

    // Assert
    Assert.areEqual(parent, parentAccount);
  }

  @isTest
  static void testGetParent_WhenParentIsNull_ThenReturnNull() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'AccountId' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(new Opportunity(Name = 'Test Opportunity'), fieldStructure);

    // Act
    Account parentAccount = (Account) evaluator.getParent('AccountId');

    // Assert
    System.assertEquals(null, parentAccount);
  }

  @isTest
  static void testGetParentAsEvaluator_WhenParentExists_ThenReturnParentEvaluator() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'AccountId' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    Account parent = new Account(Name = 'Parent Account');
    MockEvaluator evaluator = new MockEvaluator(
      new Opportunity(Name = 'Test Opportunity'),
      fieldStructure,
      new Map<String, Object>{ 'AccountId' => new MockEvaluator(parent) }
    );

    // Act
    EvaluatorInterface parentEvaluator = evaluator.getParentAsEvaluator('AccountId');

    // Assert
    Assert.areEqual(parent, parentEvaluator.getRecord());
  }

  @isTest
  static void testGetParentAsEvaluator_WhenParentIsNull_ThenReturnNull() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'AccountId' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(new Opportunity(Name = 'Test Opportunity'), fieldStructure);

    // Act
    EvaluatorInterface parentEvaluator = evaluator.getParentAsEvaluator('AccountId');

    // Assert
    System.assertEquals(null, parentEvaluator);
  }

  @isTest
  static void testGetChildren_WhenChildrenExist_ThenReturnChildrenList() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'Opportunity' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(
      new Account(Name = 'Test Account'),
      fieldStructure,
      new Map<String, Object>{ 'Opportunity' => new List<Opportunity>{ new Opportunity() } }
    );

    // Act
    List<Object> children = evaluator.getChildren('Opportunity');

    // Assert
    Assert.areEqual(1, children.size());
  }

  @isTest
  static void testGetChildren_WhenChildrenAreNull_ThenReturnEmptyList() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'Contact' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(new Account(Name = 'Test Account'), fieldStructure);

    // Act
    List<Object> children = evaluator.getChildren('Contact');

    // Assert
    Assert.areEqual(0, children.size());
  }

  @isTest
  static void testGetChildrenAsEvaluators_WhenChildrenExist_ThenReturnChildrenEvaluatorList() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'Opportunity' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(
      new Account(Name = 'Test Account'),
      fieldStructure,
      new Map<String, Object>{
        'Opportunity' => new List<EvaluatorInterface>{ new MockEvaluator(new Opportunity()) }
      }
    );

    // Act
    List<EvaluatorInterface> childrenEvaluators = evaluator.getChildrenAsEvaluators('Opportunity');

    // Assert
    Assert.areEqual(1, childrenEvaluators.size());
  }

  @isTest
  static void testGetChildrenAsEvaluators_WhenChildrenAreNull_ThenReturnEmptyList() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>(),
      new Map<String, FieldStructure>{ 'Contact' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    MockEvaluator evaluator = new MockEvaluator(new Account(Name = 'Test Account'), fieldStructure);

    // Act
    List<EvaluatorInterface> childrenEvaluators = evaluator.getChildrenAsEvaluators('Contact');

    // Assert
    Assert.areEqual(0, childrenEvaluators.size());
  }
}
