@isTest
public class MockEntryTest {
  @isTest
  static void testConstructor_WhenApplySObject_ThenMockEntryCreated() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');

    // Act
    MockEntry mockEntry = new MockEntry(record);

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully.');
  }

  @isTest
  static void testConstructor_WhenApplySObjectAndFieldToValue_ThenMockEntryCreated() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Name' => 'Mock Account',
      'Industry' => 'Technology'
    };

    // Act
    MockEntry mockEntry = new MockEntry(record, fieldToValue);

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully with fieldToValue');
  }

  @isTest
  static void testConstructor_WhenApplySObjectAndFieldStructure_ThenMockEntryCreated() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'Name', 'Industry' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Act
    MockEntry mockEntry = new MockEntry(record, fieldStructure);

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully with fieldStructure');
  }

  @isTest
  static void TestConstructor_WhenApplySObjectAndFieldStructureAndFieldToValue_ThenMockEntryCreated() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'Name', 'Industry' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Name' => 'Mock Account',
      'Industry' => 'Technology'
    };

    // Act
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully with fieldStructure and fieldToValue');
  }

  @isTest
  static void testConstructor_WhenApplyOnlyFieldToValue_ThenMockEntryCreated() {
    // Arrange
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'Name' => 'Mock Account', 'maxAmount' => 100 };

    // Act
    MockEntry mockEntry = new MockEntry(fieldToValue);

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully with only fieldToValue');
    Assert.isTrue(mockEntry.hasAggregateResult, 'MockEntry should be marked as having an AggregateResult');
  }

  @isTest
  static void testGet_WhenFieldExists_ThenReturnFieldValue() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id', 'name' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    Object fieldValue = mockEntry.get('Name');

    // Assert
    Assert.areEqual('Test Account', fieldValue, 'The field value should match the expected, value.');
  }

  @isTest
  static void testGet_WhenScriceDoesNotSelectField_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      mockEntry.get('Name');
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Account, field name: Name',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testGet_WhenFieldValueIsOverride_ThenReturnOverrideValue() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id', 'name' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'Name' => 'Mock Account' };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    Object fieldValue = mockEntry.get('Name');

    // Assert
    Assert.areEqual('Mock Account', fieldValue, 'The field value should match the override value.');
  }

  @isTest
  static void testGet_WhenGetNotExistFieldInAggregateScribe_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'avgAmount' => 1500 };
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      Object fieldValue = mockEntry.get('Id'); // 'Id' field is not exist in aggregate field structure
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field or alias is not exist in Scribe. field or alias name: Id',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testGet_WhenGetNotExistAliasInAggregateScribe_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'avgAmount' => 1500 };
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      Object fieldValue = mockEntry.get('maxAmount'); // 'maxAmount' field is not exist in aggregate field structure
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field or alias is not exist in Scribe. field or alias name: maxAmount',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testGet_WhenGetNotExistFieldInFieldToValue_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'avgAmount' => 1500 }; // StageName is not exist
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      Object fieldValue = mockEntry.get('StageName'); // 'StageName' field is not exist in fieldToValue
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field or alias is not found in the mock data. field or alias name: StageName',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testGet_WhenGetNotExistAliasInFieldToValue_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'StageName' => 'Test StageName' }; // alias 'avgAmount' is not exist
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      Object fieldValue = mockEntry.get('avgAmount'); // 'avgAmount' field is not exist in fieldToValue
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field or alias is not found in the mock data. field or alias name: avgAmount',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testGet_WhenGetExistFieldAndAliasInFieldToValue_ThenReturnValue() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'StageName' => 'Test StageName',
      'avgAmount' => 1500
    };
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);

    // Act & Assert
    Assert.areEqual('Test StageName', mockEntry.get('StageName'));
    Assert.areEqual(1500, mockEntry.get('avgAmount'));
  }

  @isTest
  static void testGetId_WhenCalled_ThenReturnId() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id', 'name' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    Id id = mockEntry.getId();

    // Assert
    Assert.areEqual('001000000000000', id, 'The Id should match the expected value.');
  }

  @isTest
  static void testGetId_WhenIdFieldDoesNotSelected_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'name' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      mockEntry.getId();
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Account, field name: Id',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testGetName_WhenCalled_ThenReturnName() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id', 'name' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    String name = mockEntry.getName();

    // Assert
    Assert.areEqual('Test Account', name, 'The Name should match the expected value.');
  }

  @isTest
  static void testGetName_WhenNameFieldDoesNotSelected_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      mockEntry.getName();
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Account, field name: Name',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testSetRecord_WhenCalled_ThenReturnNewMockEntry() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id', 'name' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    SObject newRecord = new Account(Id = '001000000000001', Name = 'New Test Account');
    IEntry newMockEntry = mockEntry.setRecord(newRecord);

    // Assert
    Assert.areEqual('New Test Account', newMockEntry.getName(), 'The Name should match the new record\'s Name.');
  }

  @isTest
  static void testSetFieldStructure_WhenCalled_ThenReturnNewMockEntryWithFieldStructure() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType());
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    FieldStructure newFieldStructure = new FieldStructure(new List<String>{ 'id', 'name' });
    IEntry newMockEntry = mockEntry.setFieldStructure(newFieldStructure);

    // Assert
    Assert.areEqual('Test Account', newMockEntry.getName(), 'The Name should match the original record\'s Name.');
  }

  @isTest
  static void testGetParent_WhenParentNotExist_ThenReturnNull() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('AccountId')
      .parentField(Scribe.asParent('AccountId').fields(new List<String>{ 'id', 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    IEntry parentEntry = mockEntry.getParent('AccountId');

    // Assert
    Assert.isNull(parentEntry, 'The parent entry should be null when no parent exists.');
  }

  @isTest
  static void testGetParent_WhenParentIsOverride_ThenReturnParentEntry() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .field('Name')
      .parentField(Scribe.asParent('AccountId').fields(new List<String>{ 'Id', 'Name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'AccountId' => new MockEntry(new Account(Id = '001000000000001', Name = 'Test Account'))
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    IEntry parentEntry = mockEntry.getParent('AccountId');
    System.debug('Parent Entry: ' + parentEntry);

    // Assert
    Assert.areEqual('Test Account', parentEntry.getName());
  }

  @isTest
  static void testGetParent_WhenFieldStructureDoesNotHaveParentIdFiled_ThenThrowException() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id');
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'AccountId' => new MockEntry(new Account(Id = '001000000000001', Name = 'Test Account'))
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      IEntry parentEntry = mockEntry.getParent('AccountId');
      String parentName = parentEntry.getName();
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified parentIdFieldName is not set in Scribe. object name: Opportunity, parent Id field name: AccountId',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testGetParent_WhenNestedParentExists_ThenReturnNestedParentEntry() {
    // Arrange
    SObject record = new OrderItem();
    Scribe scribe = Scribe.source(OrderItem.getSObjectType())
      .fields(new List<String>{ 'Id' })
      .parentField(
        Scribe.asParent('OrderId')
          .fields(new List<String>{ 'Name' })
          .parentField(
            Scribe.asParent('QuoteId')
              .fields(new List<String>{ 'Name' })
              .parentField(
                Scribe.asParent('OpportunityId')
                  .fields(new List<String>{ 'Name' })
                  .parentField(
                    Scribe.asParent('ContractId')
                      .fields(new List<String>{ 'Name' })
                      .parentField(Scribe.asParent('AccountId').fields(new List<String>{ 'Name' }))
                  )
              )
          )
      );
    FieldStructure FieldStructure = scribe.buildFieldStructure();

    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Id' => '802000000000001',
      'OrderId' => new MockEntry(
        new Order(Name = 'Test Order'),
        new Map<String, Object>{
          'QuoteId' => new MockEntry(
            new Quote(Name = 'Test Quote'),
            new Map<String, Object>{
              'OpportunityId' => new MockEntry(
                new Opportunity(Name = 'Test Opportunity'),
                new Map<String, Object>{
                  'ContractId' => new MockEntry(
                    new Contract(Name = 'Test Account'),
                    new Map<String, Object>{ 'AccountId' => new MockEntry(new Account(Name = 'Test Account')) }
                  )
                }
              )
            }
          )
        }
      )
    };
    MockEntry mockEntry = new MockEntry(record, FieldStructure, fieldToValue);

    // Act / Assert
    System.debug('get Order');
    IEntry orderEnrty = mockEntry.getParent('OrderId');
    Assert.isNotNull(orderEnrty, 'Order entry should not be null.');
    Assert.areEqual('Test Order', orderEnrty.getName(), 'Order name should match.');
    System.debug('get Quote');
    IEntry quoteEntry = orderEnrty.getParent('QuoteId');
    Assert.isNotNull(quoteEntry, 'Quote entry should not be null.');
    Assert.areEqual('Test Quote', quoteEntry.getName(), 'Quote name should match.');
    System.debug('get Opportunity');
    IEntry opportunityEntry = quoteEntry.getParent('OpportunityId');
    Assert.isNotNull(opportunityEntry, 'Opportunity entry should not be null.');
    Assert.areEqual('Test Opportunity', opportunityEntry.getName(), 'Opportunity name should match.');
    System.debug('get Contract');
    IEntry contractEntry = opportunityEntry.getParent('ContractId');
    Assert.isNotNull(contractEntry, 'Contract entry should not be null.');
    Assert.areEqual('Test Account', contractEntry.getName(), 'Contract name should match.');
    System.debug('get Account');
    IEntry accountEntry = contractEntry.getParent('AccountId');
    Assert.isNotNull(accountEntry, 'Account entry should not be null.');
    Assert.areEqual('Test Account', accountEntry.getName(), 'Account name should match.');
  }

  @isTest
  static void testGetChildren_WhenChildrenExist_ThenReturnChildEntries() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.getSObjectType()).fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Contract' => new List<IEntry>{
        new MockEntry(new Contract(), new Map<String, Object>{ 'Name' => 'Test Contract 1' }),
        new MockEntry(new Contract(), new Map<String, Object>{ 'Name' => 'Test Contract 2' })
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    List<IEntry> children = mockEntry.getChildren('Contract');

    // Assert
    Assert.isNotNull(children, 'Children should not be null.');
    Assert.areEqual(2, children.size(), 'There should be two child entries.');
    Assert.areEqual('Test Contract 1', children[0].getName(), 'First child name should match.');
    Assert.areEqual('Test Contract 2', children[1].getName(), 'Second child name should match.');
  }

  @isTest
  static void testGetChildren_WhenChildrenObjectIsNotIEntry_ThenThrowError() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.getSObjectType()).fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Contract' => new List<Contract>{ new Contract() }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildren('Contract');
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      String expected = String.format(
        'The child object needs to be a List<IEntry> or IEntry. object name: {0}, child object name: {1}',
        new List<String>{ 'Account', 'Contract' }
      );
      Assert.areEqual(expected, e.getMessage());
    }
  }

  @isTest
  static void testGetChildren_WhenChildObjectDoesNotExist_ThenReturnEmptyList() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.getSObjectType()).fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    List<IEntry> children = mockEntry.getChildren('Contract');

    // Assert
    Assert.isNotNull(children, 'Children should not be null.');
    Assert.isTrue(children.isEmpty(), 'There should be no child entries when none exist.');
  }

  @isTest
  static void testGetChildren_WhenChildObjectFieldDoesNotSelected_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(
        Scribe.asChild(Contract.getSObjectType()).fields(new List<String>{ 'id' }) // 'name' field is not selected
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Contract' => new List<IEntry>{
        new MockEntry(new Contract(Id = '800000000000001', Name = 'Test Contract 1')),
        new MockEntry(new Contract(Id = '800000000000002', Name = 'Test Contract 2'))
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildren('Contract');
      String childName = children[0].getName();
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Contract, field name: Name',
        e.getMessage()
      );
    }
  }

  @isTest
  static void testGetChildren_WhenNestedChildrenExist_ThenReturnNestedChildEntries() {
    // Arrange
    Sobject accountEnery = new Account(Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(new List<String>{ 'name' })
      .withChildren(
        Scribe.asChild(Contract.getSObjectType())
          .fields(new List<String>{ 'name' })
          .withChildren(
            Scribe.asChild(Opportunity.getSObjectType())
              .fields(new List<String>{ 'name' })
              .withChildren(
                Scribe.asChild(Order.getSObjectType())
                  .fields(new List<String>{ 'name' })
                  .withChildren(
                    Scribe.asChild(OrderItem.getSObjectType()).fields(new List<String>{ 'description' })
                  )
              )
          )
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Name' => 'Test Account',
      'Contract' => new MockEntry(
        new Contract(Name = 'Test Contract'),
        new Map<String, Object>{
          'Opportunity' => new MockEntry(
            new Opportunity(Name = 'Test Opportunity'),
            new Map<String, Object>{
              'Order' => new MockEntry(
                new Order(Name = 'Test Order'),
                new Map<String, Object>{
                  'OrderItem' => new List<IEntry>{
                    new MockEntry(new OrderItem(Description = 'Test Order Item 1')),
                    new MockEntry(new OrderItem(Description = 'Test Order Item 2'))
                  }
                }
              )
            }
          )
        }
      )
    };
    MockEntry mockEntry = new MockEntry(accountEnery, fieldStructure, fieldToValue);

    // Act / Assert
    System.debug('get Contract');
    IEntry contractEntry = mockEntry.getChildren('Contract')[0];
    Assert.isNotNull(contractEntry, 'Contract entry should not be null.');
    Assert.areEqual('Test Contract', contractEntry.getName(), 'Contract name should match.');
    System.debug('get Opportunity');
    IEntry opportunityEntry = contractEntry.getChildren('Opportunity')[0];
    Assert.isNotNull(opportunityEntry, 'Opportunity entry should not be null.');
    Assert.areEqual('Test Opportunity', opportunityEntry.getName(), 'Opportunity name should match.');
    System.debug('get Order');
    IEntry orderEntry = opportunityEntry.getChildren('Order')[0];
    Assert.isNotNull(orderEntry, 'Order entry should not be null.');
    Assert.areEqual('Test Order', orderEntry.getName(), 'Order name should match.');
    System.debug('get OrderItem');
    List<IEntry> orderItems = orderEntry.getChildren('OrderItem');
    Assert.isNotNull(orderItems, 'Order items should not be null.');
    Assert.areEqual(2, orderItems.size(), 'There should be two order items.');
    Assert.areEqual('Test Order Item 1', orderItems[0].get('Description'), 'First order item name should match.');
    Assert.areEqual('Test Order Item 2', orderItems[1].get('Description'), 'Second order item name should match.');
  }

  @isTest
  static void testGetChildrenByRelationName_WhenRelationNameIsValid_ThenReturnChildEntries() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(
        Scribe.asChild(Contract.getSObjectType()).relationName('Contracts').fields(new List<String>{ 'name' })
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Contracts' => new List<IEntry>{
        new MockEntry(new Contract(), new Map<String, Object>{ 'Name' => 'Test Contract 1' }),
        new MockEntry(new Contract(), new Map<String, Object>{ 'Name' => 'Test Contract 2' })
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    List<IEntry> children = mockEntry.getChildrenByRelationName('Contracts');

    // Assert
    Assert.isNotNull(children, 'Children should not be null.');
    Assert.areEqual(2, children.size(), 'There should be two child entries.');
    Assert.areEqual('Test Contract 1', children[0].getName(), 'First child name should match.');
    Assert.areEqual('Test Contract 2', children[1].getName(), 'Second child name should match.');
  }

  @isTest
  static void testGetChildrenByRelationName_WhenRelationNameIsInvalid_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(
        Scribe.asChild(Contract.getSObjectType()).relationName('Contract__r').fields(new List<String>{ 'name' })
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildrenByRelationName('Contract__r');
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      String expected = String.format(
        'The specified childRelationName does not exist in the parent object\'s children relationships. parent object name: {0}, child relation name: {1}',
        new List<String>{ 'Account', 'Contract__r' }
      );
      Assert.areEqual(expected, e.getMessage());
    }
  }

  @isTest
  static void testGetThrough_WhenRelationIsValid_ThenReturnRelatedObject() {
    // Arrange
    SObject record = new Order(Id = '801000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.source(Order.getSObjectType())
      .fields(new List<String>{ 'id', 'name' })
      .through(
        Scribe.asThrough(OrderItem.getSObjectType(), 'Product2Id').fields(new List<String>{ 'id', 'name' })
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    System.debug('Field Structure: ' + fieldStructure);
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'OrderItem' => new List<IEntry>{
        new MockEntry(
          new OrderItem(),
          new Map<String, Object>{ 'Product2Id' => new MockEntry(new Product2(Name = 'Test Product1')) }
        ),
        new MockEntry(
          new OrderItem(),
          new Map<String, Object>{ 'Product2Id' => new MockEntry(new Product2(Name = 'Test Product2')) }
        )
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    List<IEntry> relatedObjects = mockEntry.getThrough('OrderItem', 'Product2Id');

    // Assert
    Assert.isNotNull(relatedObjects, 'Related objects should not be null.');
    Assert.areEqual(2, relatedObjects.size(), 'There should be two related objects.');
    Assert.areEqual('Test Product1', relatedObjects[0].getName(), 'First related object name should match.');
    Assert.areEqual('Test Product2', relatedObjects[1].getName(), 'Second related object name should match.');
  }

  @isTest
  static void testGetThroughByRelationName_WhenRelationIsValid_ThenReturnRelatedObject() {
    // Arrange
    SObject record = new User(Id = '005000000000000');
    Scribe scribe = Scribe.source(User.getSObjectType())
      .field('Id')
      .through(
        Scribe.asThrough(Opportunity.getSObjectType(), 'LastModifiedById')
          .relationName('CR_DeputySalesManagerBusySeason__r')
          .field('Name')
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'CR_DeputySalesManagerBusySeason__r' => new List<IEntry>{
        new MockEntry(
          new Opportunity(),
          new Map<String, Object>{
            'LastModifiedById' => new MockEntry(new User(), new Map<String, Object>{ 'Name' => 'Last Modify 1' })
          }
        ),
        new MockEntry(
          new Opportunity(),
          new Map<String, Object>{
            'LastModifiedById' => new MockEntry(new User(), new Map<String, Object>{ 'Name' => 'Last Modify 2' })
          }
        )
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    List<IEntry> relatedObjects = mockEntry.getThroughByRelationName(
      'CR_DeputySalesManagerBusySeason__r',
      'LastModifiedById'
    );

    // Assert
    Assert.isNotNull(relatedObjects, 'Related objects should not be null.');
    Assert.areEqual(2, relatedObjects.size(), 'There should be two related objects.');
    Assert.areEqual('Last Modify 1', relatedObjects[0].getName(), 'First related object name should match.');
    Assert.areEqual('Last Modify 2', relatedObjects[1].getName(), 'Second related object name should match.');
  }
}
