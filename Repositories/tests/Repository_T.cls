@isTest
public with sharing class Repository_T {

  @isTest
  static void testFirstMethod() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Id oppId = '006000000000000';
    Query query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', oppId);
    RepositoryInterface repository = new Repository();

    // Act
    Opportunity opp = (Opportunity) repository.first(query);

    // Assert
    Assert.isNull(opp);
  }

  @isTest
  static void testFirstAsEvaluatorMethod() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Id oppId = '006000000000000';
    Query query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', oppId);
    RepositoryInterface repository = new Repository();

    // Act
    EvaluatorInterface evaluator = repository.firstAsEvaluator(query);

    // Assert
    Assert.isNull(evaluator);
  }

  @isTest
  static void testFirstOrFailMethod() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Id oppId = '006000000000000';
    Query query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', oppId);
    RepositoryInterface repository = new Repository();

    // Act & Assert
    try {
      Opportunity opp = (Opportunity) repository.firstOrFail(query);
      Assert.fail();
    } catch (QueryException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testFirstOrFailAsEvaluatorMethod() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Id oppId = '006000000000000';
    Query query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', oppId);
    RepositoryInterface repository = new Repository();

    // Act & Assert
    try {
      EvaluatorInterface evaluator = repository.firstOrFailAsEvaluator(query);
      Assert.fail();
    } catch (QueryException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testGetMethod() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Id oppId = '006000000000000';
    Query query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', oppId);
    RepositoryInterface repository = new Repository();

    // Act
    List<Opportunity> opps = (List<Opportunity>) repository.get(query);

    // Assert
    Assert.areEqual(0, opps.size());
  }

  @isTest
  static void testGetAsEvaluatorsMethod() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Id oppId = '006000000000000';
    Query query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', oppId);
    RepositoryInterface repository = new Repository();

    // Act
    List<EvaluatorInterface> evaluators = repository.getAsEvaluators(query);

    // Assert
    Assert.areEqual(0, evaluators.size());
  }

  @isTest
  static void testInsertSingleRecord() {
    // Arrange
    Opportunity opp = new Opportunity();
    opp.Name = 'Test';
    RepositoryInterface repository = new Repository();

    // Act & Assert
    try {
      opp = (Opportunity) repository.doInsert(opp);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testInsertMultipleRecords() {
    // Arrange
    Opportunity opp1 = new Opportunity(Name = 'Test1');
    Opportunity opp2 = new Opportunity(Name = 'Test2');
    List<Opportunity> oppsToInsert = new List<Opportunity>{ opp1, opp2 };
    RepositoryInterface repository = new Repository();

    // Act & Assert
    try {
      List<Opportunity> opps = (List<Opportunity>) repository.doInsert(oppsToInsert);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testUpdateSingleRecord() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Updated Test');
    RepositoryInterface repository = new Repository();

    // Act & Assert
    try {
      opp = (Opportunity) repository.doUpdate(opp);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testUpdateMultipleRecords() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Updated Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Updated Test2');
    List<Opportunity> oppsToUpdate = new List<Opportunity>{ opp1, opp2 };
    RepositoryInterface repository = new Repository();

    // Act & Assert
    try {
      List<Opportunity> opps = (List<Opportunity>) repository.doUpdate(oppsToUpdate);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testDeleteSingleRecord() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000');
    RepositoryInterface repository = new Repository();

    // Act & Assert
    try {
      repository.doDelete(opp);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testDeleteMultipleRecords() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000');
    Opportunity opp2 = new Opportunity(Id = '006000000000001');
    List<Opportunity> oppsToDelete = new List<Opportunity>{ opp1, opp2 };
    RepositoryInterface repository = new Repository();

    // Act & Assert
    try {
      repository.doDelete(oppsToDelete);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }
}
