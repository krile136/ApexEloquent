@isTest(seeAllData=false)
public with sharing class ScribeTest {
  @isTest
  public static void testScribeIsImmutableTest() {
    // Arrange
    Scribe scribeOriginal = Scribe.source(Account.getSObjectType());

    // Act
    Scribe scribeAfterAddingId = scribeOriginal.field('Id');

    // Assert
    Assert.areEqual(0, scribeOriginal.selectFields.size());
    Assert.areEqual(1, scribeAfterAddingId.selectFields.size());

    // Additional Act
    Scribe scribeAfterAddingName = scribeAfterAddingId.field('Name');
    scribeOriginal = scribeOriginal.fields(new List<String>{ 'Name', 'StageName', 'CloseDate' });

    // Additional Assert
    Assert.areEqual(3, scribeOriginal.selectFields.size());
    Assert.areEqual(1, scribeAfterAddingId.selectFields.size());
    Assert.areEqual(2, scribeAfterAddingName.selectFields.size());
  }

  @isTest
  public static void testEqual_WhenValueIsNotNull_ThenAddEqualCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name = \'Test Account\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testEqual_WhenValueIsNull_ThenAddIsNullCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('Name', null);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name = NULL)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testNotEqual_WhenValueIsNotNull_ThenAddEqualCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name != \'Test Account\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testNotEqual_WhenValueIsNull_ThenAddIsNotNullCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotEqual('Name', null);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name != NULL)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testGreaterThan_WhenValueIsNotNull_ThenAddGreaterThanCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereGreaterThan('TotalOpportunityQuantity', 1000);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE (TotalOpportunityQuantity > 1000)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testGreaterThan_WhenValueIsNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereGreaterThan('TotalOpportunityQuantity', null);

    // Act & Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      // Assert that the exception message is as expected
      String expectedMessage = 'Value cannot be null for GreaterThan condition. field: TotalOpportunityQuantity';
      Assert.areEqual(expectedMessage, e.getMessage());
    }
  }

  @isTest
  public static void testGreaterThanOrEqual_WhenValueIsNotNull_ThenAddGreaterThanCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereGreaterThanOrEqual('TotalOpportunityQuantity', 1000);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE (TotalOpportunityQuantity >= 1000)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testGreaterThanOrEqual_WhenValueIsNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereGreaterThanOrEqual('TotalOpportunityQuantity', null);

    // Act & Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      // Assert that the exception message is as expected
      String expectedMessage = 'Value cannot be null for GreaterThanOrEqual condition. field: TotalOpportunityQuantity';
      Assert.areEqual(expectedMessage, e.getMessage());
    }
  }

  @isTest
  public static void testLessThan_WhenValueIsNotNull_ThenAddLessThanCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereLessThan('TotalOpportunityQuantity', 1000);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE (TotalOpportunityQuantity < 1000)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testLessThan_WhenValueIsNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereLessThan('TotalOpportunityQuantity', null);

    // Act & Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      // Assert that the exception message is as expected
      String expectedMessage = 'Value cannot be null for LessThan condition. field: TotalOpportunityQuantity';
      Assert.areEqual(expectedMessage, e.getMessage());
    }
  }

  @isTest
  public static void testLessThanOrEqual_WhenValueIsNotNull_ThenAddLessThanOrEqualCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereLessThanOrEqual('TotalOpportunityQuantity', 1000);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE (TotalOpportunityQuantity <= 1000)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testLessThanOrEqual_WhenValueIsNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereLessThanOrEqual('TotalOpportunityQuantity', null);

    // Act & Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      // Assert that the exception message is as expected
      String expectedMessage = 'Value cannot be null for LessThanOrEqual condition. field: TotalOpportunityQuantity';
      Assert.areEqual(expectedMessage, e.getMessage());
    }
  }

  @isTest
  public static void testLike_WhenValueIsNotNull_ThenAddLikeCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereLike('Name', '%Test%');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name LIKE \'%Test%\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testLike_WhenValueIsNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereLike('Name', null);

    // Act & Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      // Assert that the exception message is as expected
      String expectedMessage = 'Value cannot be null for LIKE condition. field: Name';
      Assert.areEqual(expectedMessage, e.getMessage());
    }
  }

  @isTest
  public static void testNotLike_WhenValueIsNotNull_ThenAddNotLikeCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotLike('Name', '%Test%');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE ((NOT Name LIKE \'%Test%\'))';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testNotLike_WhenValueIsNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotLike('Name', null);

    // Act & Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      // Assert that the exception message is as expected
      String expectedMessage = 'Value cannot be null for NOT LIKE condition. field: Name';
      Assert.areEqual(expectedMessage, e.getMessage());
    }
  }

  @isTest
  public static void testIn_WhenValueIsList_ThenAddInCondition() {
    // Arrange
    List<String> values = new List<String>{ 'Test Account 1', 'Test Account 2' };
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name IN (\'Test Account 1\', \'Test Account 2\'))';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testIn_WhenValueIsIdSet_ThenAddInCondition() {
    // Arrange
    Set<Id> values = new Set<Id>{ '001000000000000AAA', '001000000000000AAB' };
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereIn('Id', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Id IN (\'001000000000000AAA\', \'001000000000000AAB\'))';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testIn_WhenValueIncludeNull_ThenAddInConditionWithNull() {
    // Arrange
    List<String> values = new List<String>{ 'Test Account 1', null };
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name IN (\'Test Account 1\', NULL))';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testNotIn_WhenValueIsList_ThenAddNotInCondition() {
    // Arrange
    List<String> values = new List<String>{ 'Test Account 1', 'Test Account 2' };
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name NOT IN (\'Test Account 1\', \'Test Account 2\'))';
    Assert.areEqual(expectedSoql, soql); 
  } 

  @isTest
  public static void testNotIn_WhenValueIsIdSet_ThenAddNotInCondition() {
    // Arrange
    Set<Id> values = new Set<Id>{ '001000000000000AAA', '001000000000000AAB' };
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotIn('Id', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Id NOT IN (\'001000000000000AAA\', \'001000000000000AAB\'))';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testNotIn_WhenValueIncludeNull_ThenAddNotInConditionWithNull() {
    // Arrange
    List<String> values = new List<String>{ 'Test Account 1', null };
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name NOT IN (\'Test Account 1\', NULL))';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testIncludes_WhenValueIsList_ThenAddIncludesCondition() {
    // Arrange
    List<String> values = new List<String>{ 'Type1', 'Type2' };
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereIncludes('Type', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    // Note: this test assert soql building with INCUDES condition is success.
    // If you execute below expected soql, Type field is not multi picklist field, so it will throw exception.
    String expectedSoql = 'SELECT id FROM Account WHERE (Type INCLUDES (\'Type1\', \'Type2\'))';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testExcudes_WhenValueIsList_ThenAddExcludesCondition() {
    // Arrange
    List<String> values = new List<String>{ 'Type1', 'Type2' };
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereExcludes('Type', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    // Note: this test assert soql building with EXCLUDES condition is success.
    // If you execute below expected soql, Type field is not multi picklist field, so it will throw exception.
    String expectedSoql = 'SELECT id FROM Account WHERE (Type EXCLUDES (\'Type1\', \'Type2\'))';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testIsNull_WhenFieldIsNotNull_ThenAddIsNullCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNull('Name');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name = NULL)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testIsNotNull_WhenFieldIsNotNull_ThenAddIsNotNullCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotNull('Name');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (Name != NULL)';
    Assert.areEqual(expectedSoql, soql);
  }
}
