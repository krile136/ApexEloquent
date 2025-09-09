@isTest
public with sharing class EloquentTest {
  @isTest
  static void testGet() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000');

    // Act
    List<IEntry> oppEntries = (new Eloquent()).get(scribe);

    // Assert
    Assert.isTrue(oppEntries.isEmpty(), 'Expected no records to be returned');
  }

  @isTest
  static void testGet_WhenScribeIsNotAggregate_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000');

    // Act & Assert
    try {
      List<IEntry> oppEntries = (new Eloquent()).getAggregate(scribe);
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.isTrue(
        e.getMessage().startsWith('The provided Scribe instance does not represent an aggregate query: ')
      );
    }
  }

  @isTest
  static void testGetAggregate_WhenScriveIsAggregate() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'AvgAmount')
      .groupByField('StageName');

    // Act
    List<IEntry> oppEntries = (new Eloquent()).getAggregate(scribe);

    // Assert
    Assert.isTrue(oppEntries.isEmpty(), 'Expected no records to be returned');
  }

  @isTest
  static void testFirst() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000');

    // Act
    IEntry oppEntry = (new Eloquent()).first(scribe);

    // Assert
    Assert.isNull(oppEntry, 'Expected no record to be returned');
  }

  @isTest
  static void testFirstOrFail() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000');

    // Act & Assert
    try {
      IEntry oppEntry = (new Eloquent()).firstOrFail(scribe);
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.isTrue(
        e.getMessage().contains('No records found for query'),
        'Expected QueryException with specific message'
      );
    }
  }

  @isTest
  static void testInsertSingleRecord() {
    // Arrange
    Opportunity opp = new Opportunity();
    opp.Name = 'Test';

    // Act & Assert
    try {
      opp = (Opportunity) (new Eloquent()).doInsert(opp);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testInsertMultipleRecords() {
    // Arrange
    Opportunity opp1 = new Opportunity(Name = 'Test1');
    Opportunity opp2 = new Opportunity(Name = 'Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act & Assert
    try {
      opps = (List<Opportunity>) (new Eloquent()).doInsert(opps);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testUpdateSingleRecord() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Updated Test');

    // Act & Assert
    try {
      opp = (Opportunity) (new Eloquent()).doUpdate(opp);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testUpdateMultipleRecords() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Updated Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Updated Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act & Assert
    try {
      opps = (List<Opportunity>) (new Repository()).doUpdate(opps);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testDeleteSingleRecord() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000');

    // Act & Assert
    try {
      (new Repository()).doDelete(opp);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }

  @isTest
  static void testDeleteMultipleRecords() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000');
    Opportunity opp2 = new Opportunity(Id = '006000000000001');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act & Assert
    try {
      (new Repository()).doDelete(opps);
    } catch (DmlException e) {
      System.debug(e.getMessage());
    }
  }
}
