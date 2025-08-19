@isTest
public class MockEntryTest {
  @isTest
  public static void testConstructor_WhenApplySObject_ThenMockEntryCreated() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');

    // Act
    MockEntry mockEntry = new MockEntry(record);

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully.');
  }

  @isTest
  public static void testConstructor_WhenApplySObjectAndFieldToValue_ThenMockEntryCreated() {
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
  public static void testConstructor_WhenApplySObjectAndFieldStructure_ThenMockEntryCreated() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'Name', 'Industry' });

    // Act
    MockEntry mockEntry = new MockEntry(record, fieldStructure);

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully with fieldStructure');
  }

  @isTest
  public static void TestConstructor_WhenApplySObjectAndFieldStructureAndFieldToValue_ThenMockEntryCreated() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'Name', 'Industry' });
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
  public static void testGet_WhenFieldExists_ThenReturnFieldValue() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id', 'name' });
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    Object fieldValue = mockEntry.get('Name');

    // Assert
    Assert.areEqual('Test Account', fieldValue, 'The field value should match the expected, value.');
  }

  @isTest
  public static void testGet_WhenScriceDoesNotSelectField_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id' });
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
  public static void testGet_WhenFieldValueIsOverride_ThenReturnOverrideValue() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id', 'name' });
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'Name' => 'Mock Account' };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    Object fieldValue = mockEntry.get('Name');

    // Assert
    Assert.areEqual('Mock Account', fieldValue, 'The field value should match the override value.');
  }

  @isTest
  public static void testGetId_WhenCalled_ThenReturnId() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id', 'name' });
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    Id id = mockEntry.getId();

    // Assert
    Assert.areEqual('001000000000000', id, 'The Id should match the expected value.');
  }

  @isTest
  public static void testGetId_WhenIdFieldDoesNotSelected_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'name' });
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
  public static void testGetName_WhenCalled_ThenReturnName() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id', 'name' });
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    String name = mockEntry.getName();

    // Assert
    Assert.areEqual('Test Account', name, 'The Name should match the expected value.');
  }

  @isTest
  public static void testGetName_WhenNameFieldDoesNotSelected_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id' });
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
  public static void testSetRecord_WhenCalled_ThenReturnNewMockEntry() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id', 'name' });
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    SObject newRecord = new Account(Id = '001000000000001', Name = 'New Test Account');
    IEntry newMockEntry = mockEntry.setRecord(newRecord);

    // Assert
    Assert.areEqual('New Test Account', newMockEntry.getName(), 'The Name should match the new record\'s Name.');
  }

  @isTest
  public static void testSetFieldStructure_WhenCalled_ThenReturnNewMockEntryWithFieldStructure() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(new List<String>());
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    FieldStructure newFieldStructure = new FieldStructure(new List<String>{ 'id', 'name' });
    IEntry newMockEntry = mockEntry.setFieldStructure(newFieldStructure);

    // Assert
    Assert.areEqual('Test Account', newMockEntry.getName(), 'The Name should match the original record\'s Name.');
  }

  @isTest
  public static void testGetParent_WhenParentNotExist_ThenReturnNull() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>{ 'accountid' },
      new Map<String, FieldStructure>{ 'accountid' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    IEntry parentEntry = mockEntry.getParent('AccountId');

    // Assert
    Assert.isNull(parentEntry, 'The parent entry should be null when no parent exists.');
  }

  @isTest
  public static void testGetParent_WhenParentIsOverride_ThenReturnParentEntry() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>{ 'id', 'name' },
      new Map<String, FieldStructure>{ 'accountid' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
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
  public static void testGetParent_WhenFieldStructureDoesNotHaveParentIdFiled_ThenThrowException() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'id' });
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
  public static void testGetParent_WhenNestedParentExists_ThenReturnNestedParentEntry() {
    // Arrange
    SObject record = new OrderItem();
    FieldStructure FieldStructure = new FieldStructure(
      new List<String>{ 'name' },
      new Map<String, FieldStructure>{
        'orderid' => new FieldStructure(
          new List<String>{ 'name' },
          new Map<String, FieldStructure>{
            'quoteid' => new FieldStructure(
              new List<String>{ 'name' },
              new Map<String, FieldStructure>{
                'opportunityid' => new FieldStructure(
                  new List<String>{ 'name' },
                  new Map<String, FieldStructure>{
                    'contractid' => new FieldStructure(
                      new List<String>{ 'name' },
                      new Map<String, FieldStructure>{
                        'accountid' => new FieldStructure(new List<String>{ 'name' })
                      }
                    )
                  }
                )
              }
            )
          }
        )
      }
    );
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Name' => 'Test Order Item',
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
  public static void testGetChildren_WhenChildrenExist_ThenReturnChildEntries() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>{ 'id', 'name' },
      new Map<String, FieldStructure>{ 'opportunity' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Opportunity' => new List<IEntry>{
        new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Test Opp 1')),
        new MockEntry(new Opportunity(Id = '006000000000002', Name = 'Test Opp 2'))
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    List<IEntry> children = mockEntry.getChildren('Opportunity');

    // Assert
    Assert.isNotNull(children, 'Children should not be null.');
    Assert.areEqual(2, children.size(), 'There should be two child entries.');
    Assert.areEqual('Test Opp 1', children[0].getName(), 'First child name should match.');
    Assert.areEqual('Test Opp 2', children[1].getName(), 'Second child name should match.');
  }

  @isTest
  public static void testGetChildren_WhenChildObjectDoesNotExist_ThenReturnEmptyList() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>{ 'id', 'name' },
      new Map<String, FieldStructure>{ 'opportunity' => new FieldStructure(new List<String>{ 'id', 'name' }) }
    );
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act
    List<IEntry> children = mockEntry.getChildren('Opportunity');

    // Assert
    Assert.isNotNull(children, 'Children should not be null.');
    Assert.isTrue(children.isEmpty(), 'There should be no child entries when none exist.');
  }

  @isTest
  public static void testGetChildren_WhenChildObjectFieldDoesNotSelected_ThenThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>{ 'id', 'name' },
      new Map<String, FieldStructure>{
        'opportunity' => new FieldStructure(new List<String>{ 'id' }) // 'name' field is not selected
      }
    );
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Opportunity' => new List<IEntry>{
        new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Test Opp 1')),
        new MockEntry(new Opportunity(Id = '006000000000002', Name = 'Test Opp 2'))
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildren('Opportunity');
      String childName = children[0].getName();
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Opportunity, field name: Name',
        e.getMessage()
      );
    }
  }

  @isTest
  public static void testGetChildren_WhenNestedChildrenExist_ThenReturnNestedChildEntries() {
    // Arrange
    Sobject accountEnery = new Account(Name = 'Test Account');
    FieldStructure fieldStructure = new FieldStructure(
      new List<String>{ 'name' },
      new Map<String, FieldStructure>{
        'contract' => new FieldStructure(
          new List<String>{ 'name' },
          new Map<String, FieldStructure>{
            'opportunity' => new FieldStructure(
              new List<String>{ 'name' },
              new Map<String, FieldStructure>{
                'order' => new FieldStructure(
                  new List<String>{ 'name' },
                  new Map<String, FieldStructure>{
                    'orderitem' => new FieldStructure(new List<String>{ 'description' })
                  }
                )
              }
            )
          }
        )
      }
    );
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
}
