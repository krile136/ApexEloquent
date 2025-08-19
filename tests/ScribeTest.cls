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
    String expectedSoql = 'SELECT id FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testEqual_WhenValueIsNull_ThenAddIsNullCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('Name', null);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = NULL';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testNotEqual_WhenValueIsNotNull_ThenAddEqualCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name != \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testNotEqual_WhenValueIsNull_ThenAddIsNotNullCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotEqual('Name', null);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name != NULL';
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
    String expectedSoql = 'SELECT id FROM Opportunity WHERE TotalOpportunityQuantity > 1000';
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
    String expectedSoql = 'SELECT id FROM Opportunity WHERE TotalOpportunityQuantity >= 1000';
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
    String expectedSoql = 'SELECT id FROM Opportunity WHERE TotalOpportunityQuantity < 1000';
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
    String expectedSoql = 'SELECT id FROM Opportunity WHERE TotalOpportunityQuantity <= 1000';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Name LIKE \'%Test%\'';
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
    String expectedSoql = 'SELECT id FROM Account WHERE (NOT Name LIKE \'%Test%\')';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Name IN (\'Test Account 1\', \'Test Account 2\')';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Id IN (\'001000000000000AAA\', \'001000000000000AAB\')';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Name IN (\'Test Account 1\', NULL)';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Name NOT IN (\'Test Account 1\', \'Test Account 2\')';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Id NOT IN (\'001000000000000AAA\', \'001000000000000AAB\')';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Name NOT IN (\'Test Account 1\', NULL)';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Type INCLUDES (\'Type1\', \'Type2\')';
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
    String expectedSoql = 'SELECT id FROM Account WHERE Type EXCLUDES (\'Type1\', \'Type2\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testIsNull_WhenFieldIsNotNull_ThenAddIsNullCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNull('Name');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = NULL';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testIsNotNull_WhenFieldIsNotNull_ThenAddIsNotNullCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereNotNull('Name');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name != NULL';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testOrCondition_WhenAddOrConditionAtFirst_ThenThrownException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Account.getSObjectType())
        .field('Id')
        .orCondition()
        .whereEqual('Name', 'Test Account');

      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'OR条件を最初に設定することはできません。where系メソッドを使用してAND条件を追加してください。parentCondition内でエラーが起きている場合は引数のScribeクラスをScribe.asParent()から始めてください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testEqual_WhenAddAndConditionAfterOrCondition_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Account.getSObjectType())
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .orCondition()
        .whereEqual('Name', 'Or Account Name')
        .whereEqual('Name', 'And Account Name');

      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testEqual_WhenAddOrConditionAfterOrCondition_ThenAddOrCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .whereEqual('Name', 'Test Account')
      .orCondition()
      .whereEqual('Name', 'Or Account Name')
      .orCondition()
      .whereEqual('Name', 'Another Or Account Name');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = \'Test Account\' OR Name = \'Or Account Name\' OR Name = \'Another Or Account Name\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testGroup_WhenAddGroup_ThenAddGroupCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereEqual('Name', 'Test Opportunity')
      .group(
        Scribe.asGroup()
          .whereGreaterThan('TotalOpportunityQuantity', 10000)
          .orCondition()
          .whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Name = \'Test Opportunity\' AND (TotalOpportunityQuantity > 10000 OR Type = \'Test Type\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testGroup_WhenAddOrGroup_ThenAddOrGroupCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereEqual('Name', 'Test Opportunity')
      .orCondition()
      .group(
        Scribe.asGroup()
          .whereGreaterThan('TotalOpportunityQuantity', 10000)
          .orCondition()
          .whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Name = \'Test Opportunity\' OR (TotalOpportunityQuantity > 10000 OR Type = \'Test Type\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testGroup_WhenAddMultiGroup_ThenAddMultiGroupCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereEqual('Name', 'Test Opportunity')
      .group(
        Scribe.asGroup()
          .whereGreaterThan('TotalOpportunityQuantity', 10000)
          .orCondition()
          .whereEqual('Type', 'Test Type')
      )
      .group(
        Scribe.asGroup()
          .whereLessThan('CloseDate', Date.newInstance(2030, 12, 31))
          .orCondition()
          .whereEqual('StageName', 'Closed Won')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Name = \'Test Opportunity\' AND (TotalOpportunityQuantity > 10000 OR Type = \'Test Type\') AND (CloseDate < 2030-12-31 OR StageName = \'Closed Won\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testGroup_WhenAddAndConditionAfterOrConditionInGroup_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Account.getSObjectType())
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .group(
          Scribe.asGroup()
            .whereGreaterThan('TotalOpportunityQuantity', 10000)
            .orCondition()
            .whereEqual('Type', 'Test Type')
            .whereEqual('StageName', 'Closed Won') // This should throw an exception
        );

      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testGroup_WhenAddAndGroupAfterOrGroup_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Account.getSObjectType())
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .orCondition()
        .group(
          Scribe.asGroup()
            .whereGreaterThan('TotalOpportunityQuantity', 10000)
            .orCondition()
            .whereEqual('Type', 'Test Type')
        )
        .group(
          Scribe.asGroup().whereEqual('StageName', 'Closed Won') // This should throw an exception
        );

      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testIN_WhenUsingSubquery_ThenAddInSubQueryCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereIn(
        'AccountId',
        Scribe.source(Account.getSObjectType()).field('Id').whereEqual('Name', 'Test Account')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE AccountId IN (SELECT id FROM Account WHERE Name = \'Test Account\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testIn_WhenUsingSubqueryWithOrCondition_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Opportunity.getSObjectType())
        .field('Id')
        .whereLike('Name', '%Test%')
        .orCondition()
        .whereIn('AccountId', Scribe.source(Account.getSObjectType()).field('Id').whereLike('Name', '%Test%'));

      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'OR条件の後にINサブクエリを追加することはできません。クエリの分割や見直しを検討してください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testNotIn_WhenUsingSubquery_ThenAddNotInSubQueryCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .whereNotIn(
        'AccountId',
        Scribe.source(Account.getSObjectType()).field('Id').whereEqual('Name', 'Test Account')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE AccountId NOT IN (SELECT id FROM Account WHERE Name = \'Test Account\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testNotIn_WhenUsingSubqueryWithOrCondition_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Opportunity.getSObjectType())
        .field('Id')
        .whereLike('Name', '%Test%')
        .orCondition()
        .whereNotIn('AccountId', Scribe.source(Account.getSObjectType()).field('Id').whereLike('Name', '%Test%'));

      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'OR条件の後にNOT INサブクエリを追加することはできません。クエリの分割や見直しを検討してください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithChildren_ThenAddWithChildrenCondition_ThenAddWithChildrenCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .withChildren(Scribe.source(Opportunity.getSObjectType()).field('Id').whereNotNull('Name'))
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT id FROM Opportunities WHERE Name != NULL) FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithChildren_WhenAddParallelWithChildrenCondition_ThenAddParallelWithChildrenCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .withChildren(Scribe.source(Opportunity.getSObjectType()).field('Id').whereNotNull('Name'))
      .withChildren(Scribe.source(Contact.getSObjectType()).field('Id').whereNotNull('Email'))
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT id FROM Opportunities WHERE Name != NULL), (SELECT id FROM Contacts WHERE Email != NULL) FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithChildren_WhenAddNestedWithChildrenCondition_ThenAddNestedWithChildrenCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .withChildren(
        Scribe.source(Contact.getSObjectType())
          .field('Id')
          .whereNotNull('Name')
          .withChildren(Scribe.source(Opportunity.getSObjectType()).field('Id').whereNotNull('Email'))
      )
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT id, (SELECT id FROM Opportunities WHERE Email != NULL) FROM Contacts WHERE Name != NULL) FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithChildren_WhenAddWithChildrenConditionAfterOrCondition_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Account.getSObjectType())
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .orCondition()
        .withChildren(Scribe.source(Opportunity.getSObjectType()).field('Id').whereNotNull('Name'));

      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'orConditionメソッドに続くメソッドはWhere系もしくはgroupメソッドでなければなりません。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithChildren_WhenAddOverFourNestChildren_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .withChildren(
        Scribe.source(Contact.getSObjectType())
          .field('Id')
          .withChildren(
            Scribe.source(Opportunity.getSObjectType())
              .field('Id')
              .withChildren(
                Scribe.source(Quote.getSObjectType())
                  .field('Id')
                  .withChildren(
                    Scribe.source(Order.getSObjectType())
                      .field('Id')
                      .withChildren(Scribe.source(OrderItem.getSObjectType()).field('Id'))
                  )
              )
          )
      );

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'ネストの深度が最大値を超えました。最大ネスト深度: 4, オブジェクト名: OrderItem',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithChildren_WhenAddOverFourNestChildrenUsingOtherScribeInstance_ThenThrowException() {
    // Arrange
    Scribe oppScribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .withChildren(
        Scribe.source(Quote.getSObjectType())
          .field('Id')
          .withChildren(
            Scribe.source(Order.getSObjectType())
              .field('Id')
              .withChildren(Scribe.source(OrderItem.getSObjectType()).field('Id'))
          )
      );

    Scribe accountScribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .withChildren(Scribe.source(Contact.getSObjectType()).field('Id').withChildren(oppScribe));

    // Act / Assert
    try {
      String soql = accountScribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'ネストの深度が最大値を超えました。最大ネスト深度: 4, オブジェクト名: OrderItem',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithParent_WhenAddOnlyParentField_ThenAddOnlyParentField() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddOnlyParentFieldUsingAsGroup_ThenErrorThrown() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Opportunity.getSObjectType())
        .field('Id')
        .parentField('AccountId', Scribe.asGroup().field('Name').field('Id'))
        .whereEqual('Name', 'Test Opportunity');

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'parentFieldメソッドの引数のScribeクラスは、Scribe.asParent()で生成されたScribeクラスを入れてください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithParent_AddOnlyParentCondition_ThenAddOnlyParentCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentCondition('AccountId', Scribe.asParent().whereEqual('Name', 'Test Account'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Account.Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_AddOnlyParentConditionUsingAsGroup_ThenErrorThrown() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Opportunity.getSObjectType())
        .field('Id')
        .parentCondition('AccountId', Scribe.asGroup().whereEqual('Name', 'Test Account'));

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'parentConditionメソッドの引数のScribeクラスは、Scribe.asParent()で生成されたScribeクラスを入れてください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithParent_WhenAddWithParentCondition_ThenAddWithParentCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition('AccountId', Scribe.asParent().whereEqual('Name', 'Test Account'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Account.Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddWithParentMultipleCondition_ThenAddWithParentMultipleCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        'AccountId',
        Scribe.asParent().whereEqual('Name', 'Test Account').whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Account.Name = \'Test Account\' AND Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddWithParentMultipleConditionByAnotherMethod_ThenAddWithParentMultipleCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition('AccountId', Scribe.asParent().whereEqual('Name', 'Test Account'))
      .parentCondition('AccountId', Scribe.asParent().whereEqual('Type', 'Test Type'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Account.Name = \'Test Account\' AND Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddOrConditionParent_ThenAddOrConditionParent() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        'AccountId',
        Scribe.asParent().whereEqual('Name', 'Test Account').orCondition().whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Account.Name = \'Test Account\' OR Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddParentConditionAfterOrCondition_ThenThrownError() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.source(Opportunity.getSObjectType())
        .field('Id')
        .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
        .whereEqual('Name', 'Test Opportunity')
        .orCondition()
        .parentCondition(
          'AccountId',
          Scribe.asParent().whereEqual('Name', 'Test Account').orCondition().whereEqual('Type', 'Test Type')
        );

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'orConditionメソッドに続くメソッドはWhere系もしくはgroupメソッドでなければなりません。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithParent_WhenAddOrConditionAtFirstInParentCondition_ThenAddOrParentCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition('AccountId', Scribe.asParent().orCondition().whereEqual('Name', 'Test Account'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' OR Account.Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddOrConditionParentAsGroup_ThenAddOrConditionParentAsasGroup() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .group(
        Scribe.asGroup()
          .parentCondition(
            'AccountId',
            Scribe.asParent().whereEqual('Name', 'Test Account').orCondition().whereEqual('Type', 'Test Type')
          )
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND (Account.Name = \'Test Account\' OR Account.Type = \'Test Type\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddNestedParent_ThenAddNestedParentCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField(
        'ContractId',
        Scribe.asParent()
          .field('Id')
          .field('Name')
          .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      )
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        'ContractId',
        Scribe.asParent()
          .whereEqual('Name', 'Test Contract')
          .parentCondition('AccountId', Scribe.asParent().whereEqual('Name', 'Test Account'))
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Contract.id, Contract.name, Contract.Account.name, Contract.Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Contract.Name = \'Test Contract\' AND Contract.Account.Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddThreeNestedParentOrCondition_ThenAddNestedParentCondition() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField(
        'ContractId',
        Scribe.asParent()
          .field('Id')
          .field('Name')
          .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      )
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        'ContractId',
        Scribe.asParent()
          .whereEqual('Name', 'Test Contract')
          .parentCondition(
            'AccountId',
            Scribe.asParent().whereEqual('Name', 'Test Account').whereEqual('Type', 'Test Type')
          )
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Contract.id, Contract.name, Contract.Account.name, Contract.Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Contract.Name = \'Test Contract\' AND Contract.Account.Name = \'Test Account\' AND Contract.Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  public static void testWithParent_WhenAddAndConditionAfterOrParentCondition_ThenErrorThrown() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .parentCondition(
        'AccountId',
        Scribe.asParent().whereEqual('Name', 'Test Account').orCondition().whereEqual('Type', 'Test Type')
      )
      .whereEqual('Name', 'Test Opportunity');

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithParent_WhenAddAndConditionAfterNestedOrParentCondition_ThenErrorThrown() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .parentCondition(
        'ContractId',
        Scribe.asParent()
          .whereEqual('Name', 'Test Contract')
          .parentCondition(
            'AccountId',
            Scribe.asParent().whereEqual('Name', 'Test Account').orCondition().whereEqual('Type', 'Test Type')
          )
      )
      .whereEqual('Name', 'Test Opportunity');

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testWithParent_WhenAddOverFourNestedParentFieldOver_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(OrderItem.getSObjectType())
      .field('Id')
      .parentField(
        'OrderId',
        Scribe.asParent()
          .field('Id')
          .parentField(
            'OriginalOrderId',
            Scribe.asParent()
              .field('Id')
              .parentField(
                'QuoteId',
                Scribe.asParent()
                  .field('Id')
                  .parentField(
                    'OpportunityId',
                    Scribe.asParent()
                      .field('Id')
                      .parentField(
                        'ContractId',
                        Scribe.asParent().field('Id').parentField('AccountId', Scribe.asParent().field('Id'))
                      )
                  )
              )
          )
      );

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      Assert.areEqual(
        '親方向のネスト深度が最大値を超えました。最大ネスト深度: 5, オブジェクト名: Account',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testBuildFieldStructure_WhenAddField_ThenReturnFieldStructure() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').field('Name').field('Type');

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasField('name'));
    Assert.isTrue(fieldStructure.hasField('type'));
    Assert.isFalse(fieldStructure.hasField('nonSelectedField'));
  }

  @isTest
  public static void testBuildFieldStructure_WhenAddParentField_ThenReturnFieldStructureWithParentFields() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .parentField('AccountId', Scribe.asParent().field('Name').field('Id'))
      .parentField('ContractId', Scribe.asParent().field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity');

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasRelation('accountid'));
    FieldStructure accountFieldStructure = fieldStructure.getRelationFieldStructure('accountid');
    Assert.isTrue(accountFieldStructure.hasField('name'));
    Assert.isTrue(accountFieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasRelation('contractid'));
    FieldStructure contractFieldStructure = fieldStructure.getRelationFieldStructure('contractid');
    Assert.isTrue(contractFieldStructure.hasField('name'));
    Assert.isTrue(contractFieldStructure.hasField('id'));
  }

  @isTest
  public static void testBuildFieldStructure_WhenAddNestedParentField_ThenReturnFieldStructureWithNestedParentFields() {
    // Arrange
    List<String> fields = new List<String>{ 'Id', 'Name' };
    Scribe scribe = Scribe.source(OrderItem.getSObjectType())
      .field('id')
      .field('ListPrice')
      .parentField(
        'OrderId',
        Scribe.asParent()
          .fields(fields)
          .parentField(
            'OriginalOrderId',
            Scribe.asParent()
              .fields(fields)
              .parentField(
                'QuoteId',
                Scribe.asParent()
                  .fields(fields)
                  .parentField(
                    'OpportunityId',
                    Scribe.asParent().fields(fields).parentField('ContractId', Scribe.asParent().fields(fields))
                  )
              )
          )
      );

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasField('listprice'));
    Assert.isTrue(fieldStructure.hasRelation('orderid'));
    FieldStructure orderFieldStructure = fieldStructure.getRelationFieldStructure('orderid');
    Assert.isTrue(orderFieldStructure.hasField('id'));
    Assert.isTrue(orderFieldStructure.hasField('name'));
    Assert.isTrue(orderFieldStructure.hasRelation('originalorderid'));
    FieldStructure originalOrderFieldStructure = orderFieldStructure.getRelationFieldStructure('originalorderid');
    Assert.isTrue(originalOrderFieldStructure.hasField('id'));
    Assert.isTrue(originalOrderFieldStructure.hasField('name'));
    Assert.isTrue(originalOrderFieldStructure.hasRelation('quoteid'));
    FieldStructure quoteFieldStructure = originalOrderFieldStructure.getRelationFieldStructure('quoteid');
    Assert.isTrue(quoteFieldStructure.hasField('id'));
    Assert.isTrue(quoteFieldStructure.hasField('name'));
    Assert.isTrue(quoteFieldStructure.hasRelation('opportunityid'));
    FieldStructure opportunityFieldStructure = quoteFieldStructure.getRelationFieldStructure('opportunityid');
    Assert.isTrue(opportunityFieldStructure.hasField('id'));
    Assert.isTrue(opportunityFieldStructure.hasField('name'));
    Assert.isTrue(opportunityFieldStructure.hasRelation('contractid'));
    FieldStructure contractFieldStructure = opportunityFieldStructure.getRelationFieldStructure('contractid');
    Assert.isTrue(contractFieldStructure.hasField('id'));
    Assert.isTrue(contractFieldStructure.hasField('name'));
  }

  @isTest
  public static void testBuildFieldStructure_WhenAddWithChildren_ThenReturnFieldStructureWithChildren() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .withChildren(Scribe.source(Opportunity.getSObjectType()).field('Id').field('Name'))
      .withChildren(Scribe.source(Contact.getSObjectType()).field('Id').field('Email'));

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasRelation('opportunity'));
    FieldStructure opportunitiesFieldStructure = fieldStructure.getRelationFieldStructure('opportunity');
    Assert.isTrue(opportunitiesFieldStructure.hasField('id'));
    Assert.isTrue(opportunitiesFieldStructure.hasField('name'));
    Assert.isTrue(fieldStructure.hasRelation('contact'));
    FieldStructure contactsFieldStructure = fieldStructure.getRelationFieldStructure('contact');
    Assert.isTrue(contactsFieldStructure.hasField('id'));
    Assert.isTrue(contactsFieldStructure.hasField('email'));
    Assert.isFalse(contactsFieldStructure.hasField('name'));
  }

  @isTest
  public static void testBuildFieldStructure_WhenAddNestedChildrenField_ThenReturnFieldStructureWithNestedChildren() {
    // Arrange
    List<String> fields = new List<String>{ 'Id', 'Name' };
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(fields)
      .withChildren(
        Scribe.source(Contact.getSObjectType())
          .fields(fields)
          .withChildren(
            Scribe.source(Opportunity.getSObjectType())
              .fields(fields)
              .withChildren(
                Scribe.source(Quote.getSObjectType())
                  .fields(fields)
                  .withChildren(Scribe.source(Order.getSObjectType()).fields(fields))
              )
          )
      );

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasField('name'));
    Assert.isTrue(fieldStructure.hasRelation('contact'));
    FieldStructure contactFieldStructure = fieldStructure.getRelationFieldStructure('contact');
    Assert.isTrue(contactFieldStructure.hasField('id'));
    Assert.isTrue(contactFieldStructure.hasField('name'));
    Assert.isTrue(contactFieldStructure.hasRelation('opportunity'));
    FieldStructure opportunityFieldStructure = contactFieldStructure.getRelationFieldStructure('opportunity');
    Assert.isTrue(opportunityFieldStructure.hasField('id'));
    Assert.isTrue(opportunityFieldStructure.hasField('name'));
    Assert.isTrue(opportunityFieldStructure.hasRelation('quote'));
    FieldStructure quoteFieldStructure = opportunityFieldStructure.getRelationFieldStructure('quote');
    Assert.isTrue(quoteFieldStructure.hasField('id'));
    Assert.isTrue(quoteFieldStructure.hasField('name'));
    Assert.isTrue(quoteFieldStructure.hasRelation('order'));
    FieldStructure orderFieldStructure = quoteFieldStructure.getRelationFieldStructure('order');
    Assert.isTrue(orderFieldStructure.hasField('id'));
    Assert.isTrue(orderFieldStructure.hasField('name'));
    Assert.isFalse(orderFieldStructure.hasField('email'));

  }
}
