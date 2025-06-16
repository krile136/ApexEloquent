@isTest(seeAllData=false)
private class MockRepository_T {
  @isTest
  static void testFirstMethod() {
    // Arrange
    Opportunity mockOpp = new Opportunity(Id = '006000000000009');
    RepositoryInterface repository = new MockRepository(mockOpp);
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000');

    // Act
    Opportunity opp = (Opportunity) repository.first(query);

    // Assert
    Assert.areEqual(mockOpp.Id, opp.Id);
  }

  @isTest
  static void testFirstAsEvaluatorMethod() {
    // Arrange
    Opportunity mockOpp = new Opportunity(Name = 'TestOpp');
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'Name' => 'MockOpp' };
    MockEvaluator mockEvaluator = new MockEvaluator(mockOpp, fieldToValue);
    RepositoryInterface repository = new MockRepository(mockEvaluator);
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .pick('Name')
      .condition('Id', '=', '006000000000000');

    // Act
    EvaluatorInterface evaluator = repository.firstAsEvaluator(query);

    // Assert
    Assert.areEqual('MockOpp', evaluator.get('Name'));
  }

  @isTest
  static void testFirstOrFailMethod() {
    // Arrange
    Opportunity mockOpp = new Opportunity(Id = '006000000000009');
    RepositoryInterface repository = new MockRepository(mockOpp);
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000');

    // Act
    Opportunity opp = (Opportunity) repository.firstOrFail(query);

    // Assert
    Assert.areEqual(mockOpp.Id, opp.Id);
  }

  @isTest
  static void testFirstOrFailAsEvaluatorMethod() {
    // Arrange
    Opportunity mockOpp = new Opportunity(Name = 'TestOpp');
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'Name' => 'MockOpp' };
    MockEvaluator mockEvaluator = new MockEvaluator(mockOpp, fieldToValue);
    RepositoryInterface repository = new MockRepository(mockEvaluator);
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .pick('Name')
      .condition('Id', '=', '006000000000000');

    // Act
    EvaluatorInterface evaluator = repository.firstOrFailAsEvaluator(query);

    // Assert
    Assert.areEqual('MockOpp', evaluator.get('Name'));
  }

  @isTest
  static void testGetMethod() {
    // Arrange
    Opportunity mockOpp = new Opportunity(Id = '006000000000009');
    RepositoryInterface repository = new MockRepository(new List<SObject>{ mockOpp });
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000');

    // Act
    List<Opportunity> opps = (List<Opportunity>) repository.get(query);

    // Assert
    Assert.areEqual(1, opps.size());
    Assert.areEqual(mockOpp.Id, opps[0].Id);
  }

  @isTest
  static void testGetAsEvaluatorsMethod() {
    // Arrange
    Opportunity mockOpp1 = new Opportunity(Name = 'TestOpp1');
    Map<String, Object> fieldToValue1 = new Map<String, Object>{ 'Name' => 'MockOpp1' };
    MockEvaluator mockEvaluator1 = new MockEvaluator(mockOpp1, fieldToValue1);
    Opportunity mockOpp2 = new Opportunity(Name = 'TestOpp2');
    Map<String, Object> fieldToValue2 = new Map<String, Object>{ 'Name' => 'MockOpp2' };
    MockEvaluator mockEvaluator2 = new MockEvaluator(mockOpp2, fieldToValue2);
    RepositoryInterface repository = new MockRepository(
      new List<EvaluatorInterface>{ mockEvaluator1, mockEvaluator2 }
    );
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .pick('Name')
      .condition('Id', '=', '006000000000000');

    // Act
    List<EvaluatorInterface> evaluators = repository.getAsEvaluators(query);

    // Assert
    Assert.areEqual(2, evaluators.size());
    Assert.areEqual('MockOpp1', evaluators[0].get('Name'));
    Assert.areEqual('MockOpp2', evaluators[1].get('Name'));
  }

  @isTest
  static void testInsertSingleRecord() {
    // Arrange
    Opportunity mockOpp = new Opportunity();
    RepositoryInterface repository = new MockRepository();

    // Act
    Opportunity insertedOpp = (Opportunity) repository.doInsert(mockOpp);

    // Assert
    Assert.areEqual('006000000000000', insertedOpp.Id);
  }

  @isTest
  static void testInsertMultipleRecords() {
    // Arrange
    Opportunity mockOpp1 = new Opportunity();
    Opportunity mockOpp2 = new Opportunity();
    List<Opportunity> mockOpps = new List<Opportunity>{ mockOpp1, mockOpp2 };
    RepositoryInterface repository = new MockRepository();

    // Act
    List<Opportunity> insertedOpps = (List<Opportunity>) repository.doInsert(mockOpps);

    // Assert
    Assert.areEqual('006000000000000', insertedOpps[0].Id);
    Assert.areEqual('006000000000001', insertedOpps[1].Id);
  }

  @isTest
  static void testUpdateSingleRecord() {
    // Arrange
    Opportunity mockOpp = new Opportunity(Id = '006000000000009');
    RepositoryInterface repository = new MockRepository();

    // Act
    Opportunity updatedOpp = (Opportunity) repository.doUpdate(mockOpp);

    // Assert
    Assert.areEqual(mockOpp.Id, updatedOpp.Id);
  }

  @isTest
  static void testUpdateMultipleRecords() {
    // Arrange
    Opportunity mockOpp1 = new Opportunity(Id = '006000000000009');
    Opportunity mockOpp2 = new Opportunity(Id = '006000000000010');
    List<Opportunity> mockOpps = new List<Opportunity>{ mockOpp1, mockOpp2 };
    RepositoryInterface repository = new MockRepository();

    // Act
    List<Opportunity> updatedOpps = (List<Opportunity>) repository.doUpdate(mockOpps);

    // Assert
    Assert.areEqual(mockOpp1.Id, updatedOpps[0].Id);
    Assert.areEqual(mockOpp2.Id, updatedOpps[1].Id);
  }

  @isTest
  static void testDeleteSingleRecord() {
    // Arrange
    Opportunity mockOpp = new Opportunity(Id = '006000000000009');
    RepositoryInterface repository = new MockRepository();

    // Act
    repository.doDelete(mockOpp);

    // Assert
    // No exception should be thrown
  }

  @isTest
  static void testDeleteMultipleRecords() {
    // Arrange
    Opportunity mockOpp1 = new Opportunity(Id = '006000000000009');
    Opportunity mockOpp2 = new Opportunity(Id = '006000000000010');
    List<Opportunity> mockOpps = new List<Opportunity>{ mockOpp1, mockOpp2 };
    RepositoryInterface repository = new MockRepository();

    // Act
    repository.doDelete(mockOpps);

    // Assert
    // No exception should be thrown
  }

  @isTest
  static void testGet_WhenFieldIsNotPick_ThenErrorThrown() {
    // Arrange
    Opportunity mockOpp = new Opportunity(Id = '006000000000009');
    RepositoryInterface repository = new MockRepository(mockOpp);
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000');

    // Act
    EvaluatorInterface opp = repository.firstAsEvaluator(query);

    // Assert
    try {
      String oppName = (String) opp.get('Name');
      Assert.fail('Expected an exception due to unpicked field');
    } catch (Exception e) {
      String expected = 'The specified field is not picked in SOQL builder. object name: Opportunity, field name: Name';
      Assert.areEqual(expected, e.getMessage());
    }
  }

  @isTest
  static void testGet_WhenChildrenFieldIsNotPickUsingGetRelation_ThenErrorThrown() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .withChildren((new Query()).source(UW_Quote__c.getSObjectType()).pick('Id'));
    MockEvaluator mockOpp = new MockEvaluator(
      new Opportunity(Id = '006000000000009'),
      new Map<String, Object>{
        'UW_Quote__c' => new List<EvaluatorInterface>{ new MockEvaluator(new UW_Quote__c(Id = 'a05000000000001')) }
      }
    );
    RepositoryInterface repository = new MockRepository(mockOpp);

    // Act
    EvaluatorInterface opp = repository.firstAsEvaluator(query);

    // Assert
    try {
      List<EvaluatorInterface> quotes = (List<EvaluatorInterface>) opp.getRelationAsEvaluator('UW_Quote__c');
      for (EvaluatorInterface quote : quotes) {
        String quoteName = quote.getName(); // This field is not picked
      }
      Assert.fail('Expected an exception due to unpicked relation field');
    } catch (Exception e) {
      String expected = 'The specified field is not picked in SOQL builder. object name: UW_Quote__c, field name: name';
      Assert.areEqual(expected, e.getMessage());
    }
  }

  @isTest
  static void testGet_WhenChildrenFieldIsNotPickUsingGetChildren_ThenErrorThrown() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .withChildren((new Query()).source(UW_Quote__c.getSObjectType()).pick('Id'));
    MockEvaluator mockOpp = new MockEvaluator(
      new Opportunity(Id = '006000000000009'),
      new Map<String, Object>{
        'UW_Quote__c' => new List<EvaluatorInterface>{ new MockEvaluator(new UW_Quote__c(Id = 'a05000000000001')) }
      }
    );
    RepositoryInterface repository = new MockRepository(mockOpp);

    // Act
    EvaluatorInterface opp = repository.firstAsEvaluator(query);

    // Assert
    try {
      List<EvaluatorInterface> quotes = opp.getChildrenAsEvaluators('UW_Quote__c');
      for (EvaluatorInterface quote : quotes) {
        String quoteName = quote.getName(); // This field is not picked
      }
      Assert.fail('Expected an exception due to unpicked relation field');
    } catch (Exception e) {
      String expected = 'The specified field is not picked in SOQL builder. object name: UW_Quote__c, field name: name';
      Assert.areEqual(expected, e.getMessage());
    }
  }

  @isTest
  static void testGet_WhenParentFieldIsNotPickUsingGetRelation_ThenErrorThrown() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .withParents('AccountId', (new Query()).pick('Id'));
    MockEvaluator mockOpp = new MockEvaluator(
      new Opportunity(Id = '006000000000009'),
      new Map<String, Object>{
        'AccountId' => new MockEvaluator(new Account(Id = '001000000000001'))
      }
    );
    RepositoryInterface repository = new MockRepository(mockOpp);

    // Act
    EvaluatorInterface opp = repository.firstAsEvaluator(query);

    // Assert
    try {
      EvaluatorInterface parent = (EvaluatorINterface) opp.getRelationAsEvaluator('AccountId');
      String parentName = parent.getName(); // This field is not picked
      Assert.fail('Expected an exception due to unpicked parent field');
    } catch (Exception e) {
      String expected = 'The specified field is not picked in SOQL builder. object name: Account, field name: name';
      Assert.areEqual(expected, e.getMessage());
    }
  }

  @isTest
  static void testGet_WhenParentFieldIsNotPickUsingGetParent_ThenErrorThrown() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .withParents('AccountId', (new Query()).pick('Id'));
    MockEvaluator mockOpp = new MockEvaluator(
      new Opportunity(Id = '006000000000009'),
      new Map<String, Object>{
        'AccountId' => new MockEvaluator(new Account(Id = '001000000000001'))
      }
    );
    RepositoryInterface repository = new MockRepository(mockOpp);

    // Act
    EvaluatorInterface opp = repository.firstAsEvaluator(query);

    // Assert
    try {
      EvaluatorInterface parent = opp.getParentAsEvaluator('AccountId');
      String parentName = parent.getName(); // This field is not picked
      Assert.fail('Expected an exception due to unpicked parent field');
    } catch (Exception e) {
      String expected = 'The specified field is not picked in SOQL builder. object name: Account, field name: name';
      Assert.areEqual(expected, e.getMessage());
    }
  }
}
