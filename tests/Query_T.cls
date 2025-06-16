@isTest(seeAllData=false)
public with sharing class Query_T {
  @isTest
  public static void testQuerySingleField() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\')';
    Assert.areEqual(expected, query.toSoql());
  }

  @isTest
  public static void testQueryMultipleFields() {
    // Arrange
    List<String> fields = new List<String>{ 'Id', 'Name' };
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick(fields)
      .condition('Id', '=', '006000000000000');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id, name FROM Opportunity WHERE (Id = \'006000000000000\')';
    Assert.areEqual(expected, query.toSoql());
  }

  @isTest
  public static void testQueryPickAllFields() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pickAll()
      .condition('Id', '=', '006000000000000');

    // Act
    String actual = query.toSoql();

    // Assert
    Assert.isTrue(actual.startsWith('SELECT '));
    Assert.isTrue(actual.contains(' FROM Opportunity '));
    Assert.isTrue(actual.endsWith(' WHERE (Id = \'006000000000000\')'));
    Assert.isTrue(actual.contains('id'));
    Assert.isTrue(actual.contains('name'));
    Assert.isTrue(actual.contains('closedate'));
    Assert.isTrue(actual.contains('stagename'));
  }

  @isTest
  public static void testQueryWithParents() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .withParents(
        new ParentClause('AccountId', (new Query()).pick('Name').pick('Id').condition('Name', '=', 'testAccount'))
      )
      .condition('Name', '=', 'testOpportunity');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE (Name = \'testOpportunity\' AND Account.Name = \'testAccount\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithParentsWithoutParentClauseInstance() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .withParents('AccountId', (new Query()).pick('Name').pick('Id').condition('Name', '=', 'testAccount'))
      .condition('Name', '=', 'testOpportunity');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE (Name = \'testOpportunity\' AND Account.Name = \'testAccount\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithParentsWithoutChildrenCondition() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .withParents(
        new ParentClause('AccountId', (new Query()).pick('Name').pick('Id').condition('Name', '=', 'testAccount'))
      );

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE (Account.Name = \'testAccount\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithParentsAsParallel() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .withParents(new ParentClause('AccountId', (new Query()).pick('Name').condition('Name', '=', 'testAccount')))
      .withParents(
        new ParentClause('ContractId', (new Query()).pick('Name').condition('Name', '=', 'testContract'))
      )
      .condition('Name', '=', 'testOpportunity');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id, Account.name, Contract.name FROM Opportunity WHERE (Name = \'testOpportunity\' AND Account.Name = \'testAccount\' AND Contract.Name = \'testContract\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithNestedParents() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .withParents(
        new ParentClause(
          'ContractId',
          (new Query())
            .pick('Name')
            .pick('Id')
            .condition('Name', '=', 'testContract')
            .withParents(
              new ParentClause('AccountId', (new Query()).pick('Name').condition('Name', '=', 'testAccount'))
            )
        )
      )
      .condition('Name', '=', 'testOpportunity');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id, Contract.name, Contract.id, Contract.Account.name FROM Opportunity WHERE (Name = \'testOpportunity\' AND Contract.Name = \'testContract\' AND Contract.Account.Name = \'testAccount\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithNestedParents2() {
    // Arrange
    Query query = (new Query())
      .source(OpportunityLineItem.getSObjectType())
      .pick('Id')
      .withParents(
        'OpportunityId',
        (new Query())
          .pick('Id')
          .withParents(
            new ParentClause(
              'AccountId',
              (new Query()).pick('Name').pick('Id').condition('Name', '=', 'testAccount')
            )
          )
      );

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id, Opportunity.id, Opportunity.Account.name, Opportunity.Account.id FROM OpportunityLineItem WHERE (Opportunity.Account.Name = \'testAccount\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithChildren() {
    // Arrange
    Query contactQuery = (new Query()).source(Contact.getSObjectType()).pick('FirstName').isNotNull('Name');
    Query oppQuery = (new Query()).source(Opportunity.getSObjectType()).pick('Name').isNotNull('Name');
    Query query = (new Query())
      .source(Account.getSObjectType())
      .pick('Name')
      .withChildren(contactQuery)
      .withChildren(oppQuery)
      .condition('Name', '=', 'testAccount');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT name, (SELECT firstname FROM Contacts WHERE (Name != NULL)), (SELECT name FROM Opportunities WHERE (Name != NULL)) FROM Account WHERE (Name = \'testAccount\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithNestedChildren() {
    // Arrange
    Query query = (new Query())
      .source(Account.getSObjectType())
      .pick('Name')
      .withChildren(
        (new Query())
          .source(Contact.getSObjectType())
          .pick('Name')
          .condition('Name', '=', 'testContact')
          .withChildren(
            (new Query())
              .source(Opportunity.getSObjectType())
              .pick('Name')
              .condition('Name', '=', 'testOpportunity')
          )
      )
      .condition('Name', '=', 'testAccount');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT name, (SELECT name, (SELECT name FROM Opportunities WHERE (Name = \'testOpportunity\')) FROM Contacts WHERE (Name = \'testContact\')) FROM Account WHERE (Name = \'testAccount\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testAndConditionQuery() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .condition('Name', '=', 'Test');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\' AND Name = \'Test\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testAndConditionQueryWithArray() {
    // Arrange
    List<String> ids = new List<String>{ '006000000000000', '006000000000001' };
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Name', '=', 'Test')
      .condition('Id', 'IN', ids);

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Name = \'Test\' AND Id IN (\'006000000000000\', \'006000000000001\'))';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testAndConditionQueryWithArrayIncludesNull() {
    // Arrange
    List<String> ids = new List<String>{ '006000000000000', null };
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Name', '=', 'Test')
      .condition('Id', 'IN', ids);

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Name = \'Test\' AND Id IN (\'006000000000000\', NULL))';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testAndConditionQueryWithEmptyArray() {
    // Arrange
    List<String> ids = new List<String>();
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Name', '=', 'Test')
      .condition('Id', 'IN', ids);

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Name = \'Test\' AND Id = NULL)';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testOrConditionQuery() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orCondition('Name', '=', 'Test');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') OR (Name = \'Test\')';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testOrConditionQueryWithArray() {
    // Arrange
    List<String> ids = new List<String>{ '006000000000000', '006000000000001' };
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Name', '=', 'Test')
      .orCondition('Id', 'IN', ids);

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Name = \'Test\') OR (Id IN (\'006000000000000\', \'006000000000001\'))';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testOrConditionQueryWithEmptyArray() {
    // Arrange
    List<String> ids = new List<String>();
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Name', '=', 'Test')
      .orCondition('Id', 'IN', ids);

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Name = \'Test\') OR (Id = NULL)';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testAndConditionSubquery() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .condition(
        (new Query()).condition('Name', '=', 'Test').condition('CloseDate', '<=', Date.newInstance(2024, 12, 31))
      );

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') AND ((Name = \'Test\' AND CloseDate <= 2024-12-31))';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testOrConditionSubquery() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orCondition(
        (new Query()).condition('Name', '=', 'Test').condition('CloseDate', '<=', Date.newInstance(2024, 12, 31))
      );

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') OR ((Name = \'Test\' AND CloseDate <= 2024-12-31))';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithJoin() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .join(
        'AccountId',
        'IN',
        (new Query()).source(Account.getSObjectType()).pick('Id').condition('Name', '=', 'TestAccount')
      );

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') AND (AccountId IN (SELECT id FROM Account WHERE (Name = \'TestAccount\')))';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithMultipleJoin() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .join(
        'AccountId',
        'IN',
        (new Query()).source(Account.getSObjectType()).pick('Id').condition('Name', '=', 'TestAccount')
      )
      .join(
        'ContactId',
        'IN',
        (new Query()).source(Contact.getSObjectType()).pick('Id').condition('Name', '=', 'TestContact')
      );

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') AND (AccountId IN (SELECT id FROM Account WHERE (Name = \'TestAccount\'))) AND (ContactId IN (SELECT id FROM Contact WHERE (Name = \'TestContact\')))';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithLimit() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .restrict(10);

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') LIMIT 10';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithOrderBy() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orderBy('CloseDate');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') ORDER BY CloseDate ASC';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithOrderByDesc() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orderBy('CloseDate', 'DESC');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') ORDER BY CloseDate DESC';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithOrderByWithNull() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orderBy('CloseDate', 'ASC', 'FIRST');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') ORDER BY CloseDate ASC NULLS FIRST';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithMultipleOrderBy() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orderBy(new List<String>{ 'CloseDate', 'Name' });

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') ORDER BY CloseDate, Name ASC';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithMultipleOrderByDesc() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orderBy(new List<String>{ 'CloseDate', 'Name' }, 'DESC');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') ORDER BY CloseDate, Name DESC';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithMultipleOrderByWithNull() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orderBy(new List<String>{ 'CloseDate', 'Name' }, 'ASC', 'FIRST');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000\') ORDER BY CloseDate, Name ASC NULLS FIRST';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithfind() {
    // Arrange
    Query query = (new Query()).source(Opportunity.getSObjectType()).pick('Id').find('006000000000000');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id = \'006000000000000AAA\')'; // salesforce converts id which is 15 char to 18 char
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithfindMany() {
    // Arrange
    List<String> ids = new List<String>{ '006000000000000', '006000000000001' };
    Query query = (new Query()).source(Opportunity.getSObjectType()).pick('Id').findMany(ids);

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (Id IN (\'006000000000000\', \'006000000000001\'))';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithBetweenInclusive() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .betweenInclusive('CloseDate', Date.newInstance(2024, 1, 1), Date.newInstance(2024, 12, 31));

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (CloseDate >= 2024-01-01 AND CloseDate <= 2024-12-31)';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithBetweenExclusive() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('Id')
      .betweenExclusive('CloseDate', Date.newInstance(2024, 1, 1), Date.newInstance(2024, 12, 31));

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (CloseDate > 2024-01-01 AND CloseDate < 2024-12-31)';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithIsNull() {
    // Arrange
    Query query = (new Query()).source(Opportunity.getSObjectType()).pick('Id').isNull('CloseDate');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (CloseDate = NULL)';
    Assert.areEqual(expected, actual);
  }

  @isTest
  public static void testQueryWithIsNotNull() {
    // Arrange
    Query query = (new Query()).source(Opportunity.getSObjectType()).pick('Id').isNotNull('CloseDate');

    // Act
    String actual = query.toSoql();

    // Assert
    String expected = 'SELECT id FROM Opportunity WHERE (CloseDate != NULL)';
    Assert.areEqual(expected, actual);
  }

  @isTest
  static void testGetSelectedFields_WhenAllFieldSelected_ThenGetAllField() {
    // Arrange
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pickAll()
      .condition('Id', '=', '006000000000000');

    // Act
    List<String> actual = query.getSelectedFields();

    // Assert
    // expected fields are lower case
    List<String> expected = new List<String>{ 'id', 'name', 'closedate', 'stagename' };
    for (String field : expected) {
      Assert.isTrue(actual.contains(field), 'Expected field ' + field + ' to be in the select fields');
    }
  }

  @isTest
  static void testGetSelectedFields_WhenSomeFieldSelected_ThenGetSelectedFields() {
    // Arrange
    List<String> expected = new List<String>{ 'Id', 'Name' };
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick(expected)
      .condition('Id', '=', '006000000000000');

    // Act
    List<String> actual = query.getSelectedFields();
    System.debug('Actual select fields: ' + actual);

    // Assert
    Assert.areEqual(
      expected.size(),
      actual.size(),
      'Expected number of fields does not match actual number of fields'
    );
    for (String field : expected) {
      field = field.toLowerCase();
      Assert.isTrue(actual.contains(field), 'Expected field ' + field + ' to be in the select fields');
    }
  }

  @isTest
  static void testBuildFieldStructure_WhenSourceIsOne_ThenGetFieldStructure() {
    // Arrange
    List<String> selectedFields = new List<String>{ 'Id', 'Name' };
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick(selectedFields)
      .condition('Id', '=', '006000000000000');

    // Act
    FieldStructure actual = query.buildFieldStructure();

    // Assert
    for (String field : selectedFields) {
      field = field.toLowerCase();
      Assert.isTrue(actual.hasField(field), 'Expected field ' + field + ' to be in the field structure');
    }
  }

  @isTest
  static void testBuildFieldStructure_WhenWithParents_ThenGetParentStructure() {
    // Arrange
    List<String> oppFields = new List<String>{ 'Id', 'Name' };
    List<String> contractFields = new List<String>{ 'Id', 'Name', 'ContractNumber', 'ContractTerm' };
    List<String> accountFields = new List<String>{ 'Id', 'Name', 'BillingAddress', 'Phone', 'Fax' };
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick(oppFields)
      .withParents(
        'ContractId',
        (new Query()).pick(contractFields).withParents('AccountId', (new Query()).pick(accountFields))
      )
      .condition('Id', '=', '006000000000000');

    // Act
    FieldStructure actual = query.buildFieldStructure();

    // Assert oppFieldStructure
    for (String field : oppFields) {
      field = field.toLowerCase();
      Assert.isTrue(actual.hasField(field), 'Expected field ' + field + ' to be in the field structure');
    }
    // Assert contractFieldStructure
    Assert.isTrue(actual.hasRelation(), 'Expected field structure to have relation');
    FieldStructure contractFieldStructure = actual.getRelationFieldStructure('ContractId');
    Assert.isNotNull(contractFieldStructure, 'Expected ContractId relation field structure to be not null');
    for (String field : contractFields) {
      field = field.toLowerCase();
      Assert.isTrue(
        contractFieldStructure.hasField(field),
        'Expected contract field ' + field + ' to be in the field structure'
      );
    }
    // Assert accountFieldStructure
    FieldStructure accountFieldStructure = contractFieldStructure.getRelationFieldStructure('AccountId');
    Assert.isNotNull(accountFieldStructure, 'Expected AccountId relation field structure to be not null');
    for (String field : accountFields) {
      field = field.toLowerCase();
      Assert.isTrue(
        accountFieldStructure.hasField(field),
        'Expected account field ' + field + ' to be in the field structure'
      );
    }
  }

  @isTest
  static void testBuildFieldStructure_WhenWithChildren_ThenGetChildrenStructure() {
    // Arrange
    List<String> accountFields = new List<String>{ 'Id', 'Name', 'BillingAddress', 'Phone', 'Fax' };
    List<String> contractFields = new List<String>{ 'Id', 'Name', 'ContractNumber', 'ContractTerm' };
    List<String> oppFields = new List<String>{ 'Id', 'Name' };
    Query query = (new Query())
      .source(Account.getSObjectType())
      .pick(accountFields)
      .withChildren(
        (new Query())
          .source(Contract.getSObjectType())
          .pick(contractFields)
          .withChildren((new Query()).source(Opportunity.getSObjectType()).pick(oppFields))
      )
      .condition('Name', '=', 'Test Account');

    // Act
    FieldStructure actual = query.buildFieldStructure();
    System.debug(actual);

    // Assert accountFieldStructure
    for (String field : accountFields) {
      field = field.toLowerCase();
      Assert.isTrue(actual.hasField(field), 'Expected field ' + field + ' to be in the field structure');
    }
    // Assert contractFieldStructure
    Assert.isTrue(actual.hasRelation(), 'Expected field structure to have relation');
    FieldStructure contractFieldStructure = actual.getRelationFieldStructure('Contract');
    Assert.isNotNull(contractFieldStructure, 'Expected Contracts relation field structure to be not null');
    for (String field : contractFields) {
      field = field.toLowerCase();
      Assert.isTrue(
        contractFieldStructure.hasField(field),
        'Expected contract field ' + field + ' to be in the field structure'
      );
    }
    // Assert oppFieldStructure
    FieldStructure oppFieldStructure = contractFieldStructure.getRelationFieldStructure('Opportunity');
    Assert.isNotNull(oppFieldStructure, 'Expected Opportunities relation field structure to be not null');
    for (String field : oppFields) {
      field = field.toLowerCase();
      Assert.isTrue(
        oppFieldStructure.hasField(field),
        'Expected opportunity field ' + field + ' to be in the field structure'
      );
    }
  }
}
