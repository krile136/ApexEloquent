@isTest
public with sharing class MockEloquentTest {
  @isTest
  static void testGet_WhenEntryExist_ThenReturnEntries() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '00600000000000');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(!entries.isEmpty(), 'Expected entries to be returned');
    Assert.areEqual('006000000000001', entries[0].getId(), 'Expected entry ID to match');
  }

  @isTest
  static void testGet_WhenNoEntries_ThenReturnEmptyList() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.isEmpty(), 'Expected no entries to be returned');
  }

  @isTest
  static void testGet_WhenEntriesExist_ThenReturnEntries() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000001');
    MockEntry mockEntry1 = new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Opportunity 1'));
    MockEntry mockEntry2 = new MockEntry(new Opportunity(Id = '006000000000002', Name = 'Opportunity 2'));
    IEloquent eloquent = new MockEloquent(new List<IEntry>{ mockEntry1, mockEntry2 });

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 2, 'Expected two entries to be returned');
    Assert.areEqual('006000000000001', entries[0].getId(), 'Expected first entry ID to match');
    Assert.areEqual('006000000000002', entries[1].getId(), 'Expected second entry ID to match');
  }

  @isTest
  static void testGet_WhenEntryWithParentExist_ThenReturnNestedEntries() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .field('Name')
      .parentField('AccountId', Scribe.asParent().field('Id').field('Name'))
      .whereEqual('Id', '006000000000001');
    MockEntry oppEntry = new MockEntry(
      new Opportunity(Id = '006000000000001', Name = 'Test Opportunity'),
      new Map<String, Object>{
        'AccountId' => new MockEntry(new Account(Id = '001000000000001', Name = 'Test Account'))
      }
    );
    IEloquent eloquent = new MockEloquent(oppEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 1, 'Expected one nested entry to be returned');
    Assert.areEqual('006000000000001', entries[0].getId(), 'Expected nested entry ID to match');
    Assert.areEqual('Test Opportunity', entries[0].getName(), 'Expected nested entry Name to match');
    IEntry accountEntry = entries[0].getParent('AccountId');
    Assert.areEqual('001000000000001', accountEntry.getId(), 'Expected nested child entry ID to match');
    Assert.areEqual('Test Account', accountEntry.getName(), 'Expected nested child entry Name to match');
  }

  @isTest
  static void testGet_WhenEntryWithNestedParentExist_ThenReturnNestedEntries() {
    // Arrange
    List<String> fields = new List<String>{ 'Name' };
    Scribe scribe = Scribe.source(OrderItem.getSObjectType())
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
    MockEntry orderItemEntry = new MockEntry(
      new OrderItem(ListPrice = 100),
      new Map<String, Object>{
        'OrderId' => new MockEntry(
          new Order(Name = 'Test Order'),
          new Map<String, Object>{
            'OriginalOrderId' => new MockEntry(
              new Order(Name = 'Original Test Order'),
              new Map<String, Object>{
                'QuoteId' => new MockEntry(
                  new Quote(Name = 'Test Quote'),
                  new Map<String, Object>{
                    'OpportunityId' => new MockEntry(
                      new Opportunity(Name = 'Test Opportunity'),
                      new Map<String, Object>{
                        'ContractId' => new MockEntry(new Contract(Name = 'Test Contract'))
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
    IEloquent eloquent = new MockEloquent(orderItemEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 1, 'Expected one nested entry to be returned');
    Assert.areEqual(100, entries[0].get('ListPrice'), 'Expected nested entry Name to match');
    IEntry orderEntry = entries[0].getParent('OrderId');
    Assert.areEqual('Test Order', orderEntry.getName(), 'Expected nested child entry Name to match');
    IEntry originalOrderEntry = orderEntry.getParent('OriginalOrderId');
    Assert.areEqual(
      'Original Test Order',
      originalOrderEntry.getName(),
      'Expected nested grandchild entry Name to match'
    );
    IEntry quoteEntry = originalOrderEntry.getParent('QuoteId');
    Assert.areEqual('Test Quote', quoteEntry.getName(), 'Expected nested great-grandchild entry Name to match');
    IEntry opportunityEntry = quoteEntry.getParent('OpportunityId');
    Assert.areEqual(
      'Test Opportunity',
      opportunityEntry.getName(),
      'Expected nested great-great-grandchild entry Name to match'
    );
    IEntry contractEntry = opportunityEntry.getParent('ContractId');
    Assert.areEqual(
      'Test Contract',
      contractEntry.getName(),
      'Expected nested great-great-great-grandchild entry Name to match'
    );
  }

  @isTest
  static void testGet_WhenEntriesWithChildrenExist_ThenReturnEntriesWithChildren() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .field('Name')
      .withChildren(Scribe.source(Contact.getSObjectType()).field('Id').field('Name'))
      .whereEqual('Id', '001000000000001');
    MockEntry accountEntry = new MockEntry(
      new Account(Id = '001000000000001', Name = 'Test Account'),
      new Map<String, Object>{
        'Contact' => new List<IEntry>{
          new MockEntry(
            new Contact(Id = '003000000000001'),
            new Map<String, Object>{ 'Name' => 'Test Contact 1' }
          ),
          new MockEntry(new Contact(Id = '003000000000002'), new Map<String, Object>{ 'Name' => 'Test Contact 2' })
        }
      }
    );
    IEloquent eloquent = new MockEloquent(accountEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 1, 'Expected one entry to be returned');
    Assert.areEqual('001000000000001', entries[0].getId(), 'Expected entry ID to match');
    Assert.areEqual('Test Account', entries[0].getName(), 'Expected entry Name to match');
    List<IEntry> contacts = entries[0].getChildren('Contact');
    Assert.isTrue(contacts.size() == 2, 'Expected two child entries to be returned');
    Assert.areEqual('003000000000001', contacts[0].getId(), 'Expected first child entry ID to match');
    Assert.areEqual('Test Contact 1', contacts[0].getName(), 'Expected first child entry Name to match');
    Assert.areEqual('003000000000002', contacts[1].getId(), 'Expected second child entry ID to match');
    Assert.areEqual('Test Contact 2', contacts[1].getName(), 'Expected second child entry Name to match');
  }

  @isTest
  static void testGet_WhenEntriesWithNestedChildren_ThenReturnEntriesWithNestedChildren() {
    // Arrange
    List<String> fields = new List<String>{ 'Name' };
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

    MockEntry accountEntry = new MockEntry(
      new Account(Name = 'Test Account'),
      new Map<String, Object>{
        'Contact' => new List<IEntry>{
          new MockEntry(
            new Contact(),
            new Map<String, Object>{
              'Name' => 'Test Contact 1',
              'Opportunity' => new List<IEntry>{
                new MockEntry(
                  new Opportunity(Name = 'Test Opportunity 1'),
                  new Map<String, Object>{
                    'Quote' => new List<IEntry>{
                      new MockEntry(
                        new Quote(Name = 'Test Quote 1'),
                        new Map<String, Object>{
                          'Order' => new List<IEntry>{ new MockEntry(new Order(Name = 'Test Order 1')) }
                        }
                      )
                    }
                  }
                )
              }
            }
          ),
          new MockEntry(
            new Contact(),
            new Map<String, Object>{
              'Name' => 'Test Contact 2',
              'Opportunity' => new List<IEntry>{
                new MockEntry(
                  new Opportunity(Name = 'Test Opportunity 2'),
                  new Map<String, Object>{
                    'Quote' => new List<IEntry>{
                      new MockEntry(
                        new Quote(Name = 'Test Quote 2'),
                        new Map<String, Object>{
                          'Order' => new List<IEntry>{ new MockEntry(new Order(Name = 'Test Order 2')) }
                        }
                      )
                    }
                  }
                )
              }
            }
          )
        }
      }
    );
    IEloquent eloquent = new MockEloquent(accountEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 1, 'Expected one entry to be returned');
    Assert.areEqual('Test Account', entries[0].getName(), 'Expected entry Name to match');
    List<IEntry> contacts = entries[0].getChildren('Contact');
    Assert.isTrue(contacts.size() == 2, 'Expected two child entries to be returned');

    // Assert first contact and its children
    Assert.areEqual('Test Contact 1', contacts[0].getName(), 'Expected first child entry Name to match');
    List<IEntry> opportunities1 = contacts[0].getChildren('Opportunity');
    Assert.isTrue(opportunities1.size() == 1, 'Expected one opportunity entry to be returned');
    Assert.areEqual('Test Opportunity 1', opportunities1[0].getName(), 'Expected opportunity Name to match');
    List<IEntry> quotes1 = opportunities1[0].getChildren('Quote');
    Assert.isTrue(quotes1.size() == 1, 'Expected one quote entry to be returned');
    Assert.areEqual('Test Quote 1', quotes1[0].getName(), 'Expected quote Name to match');
    List<IEntry> orders1 = quotes1[0].getChildren('Order');
    Assert.isTrue(orders1.size() == 1, 'Expected one order entry to be returned');
    Assert.areEqual('Test Order 1', orders1[0].getName(), 'Expected order Name to match');

    // Assert second contact and its children
    Assert.areEqual('Test Contact 2', contacts[1].getName(), 'Expected second child entry Name to match');
    List<IEntry> opportunities2 = contacts[1].getChildren('Opportunity');
    Assert.isTrue(opportunities2.size() == 1, 'Expected one opportunity entry to be returned');
    Assert.areEqual('Test Opportunity 2', opportunities2[0].getName(), 'Expected opportunity Name to match');
    List<IEntry> quotes2 = opportunities2[0].getChildren('Quote');
    Assert.isTrue(quotes2.size() == 1, 'Expected one quote entry to be returned');
    Assert.areEqual('Test Quote 2', quotes2[0].getName(), 'Expected quote Name to match');
    List<IEntry> orders2 = quotes2[0].getChildren('Order');
    Assert.isTrue(orders2.size() == 1, 'Expected one order entry to be returned');
    Assert.areEqual('Test Order 2', orders2[0].getName(), 'Expected order Name to match');
  }

  @isTest
  static void testGet_WhenGetNonSelectedField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '00600000000000');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act & Assert
    List<IEntry> entries = eloquent.get(scribe);
    try {
      IEntry entry = entries[0];
      entry.getName(); // This field is not selected in the Scribe query
      Assert.fail('Expected QueryException to be thrown for non-selected field');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.isTrue(
        e.getMessage()
          .contains('The specified field is not selected in Scribe. object name: Opportunity, field name: Name'),
        'Expected QueryException with specific message for non-selected field'
      );
    }
  }

  @isTest
  static void testGet_WhenEntryWithoutParentGetParent_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .field('Name')
      .whereEqual('Id', '006000000000001');
    MockEntry oppEntry = new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(oppEntry);

    // Act & Assert
    List<IEntry> entries = eloquent.get(scribe);
    try {
      IEntry entry = entries[0];
      entry.getParent('AccountId'); // This parent does not exist in the mock entry
      Assert.fail('Expected QueryException to be thrown for non-existing parent');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual(
        'The specified parentIdFieldName is not set in Scribe. object name: Opportunity, parent Id field name: AccountId',
        e.getMessage(),
        'Expected QueryException with specific message for non-existing parent'
      );
    }
  }

  @isTest
  static void testGet_WhenEntryWithParentGetNonSelectedField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('Id')
      .field('Name')
      .parentField('AccountId', Scribe.asParent().field('Id')) // 'Name' field is not selected
      .whereEqual('Id', '006000000000001');
    MockEntry oppEntry = new MockEntry(
      new Opportunity(Id = '006000000000001', Name = 'Test Opportunity'),
      new Map<String, Object>{ 'AccountId' => new MockEntry(new Account(Id = '001000000000001')) }
    );
    IEloquent eloquent = new MockEloquent(oppEntry);

    // Act & Assert
    List<IEntry> entries = eloquent.get(scribe);
    try {
      IEntry entry = entries[0];
      entry.getParent('AccountId').getName(); // This field is not selected in the Scribe query
      Assert.fail('Expected QueryException to be thrown for non-selected field in parent');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Account, field name: Name',
        e.getMessage(),
        'Expected QueryException with specific message for non-selected field in parent'
      );
    }
  }

  @isTest
  static void testGet_WhenEntryWithNestedParentGetNonSelectedField_ThenThrowException() {
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
                    new Map<String, Object>{
                      'AccountId' => new MockEntry(
                        new Account(
                          Name = 'Test Account',
                          Id = '001000000000000001' // account Id is not selected in Scribe
                        )
                      )
                    }
                  )
                }
              )
            }
          )
        }
      )
    };

    // Act
    MockEntry mockEntry = new MockEntry(record, FieldStructure, fieldToValue);
    IEntry orderEnrty = mockEntry.getParent('OrderId');
    IEntry quoteEntry = orderEnrty.getParent('QuoteId');
    IEntry opportunityEntry = quoteEntry.getParent('OpportunityId');
    IEntry contractEntry = opportunityEntry.getParent('ContractId');
    IEntry accountEntry = contractEntry.getParent('AccountId');

    // Assert
    try {
      accountEntry.getId(); // This field is not selected in the Scribe query
      Assert.fail('Expected QueryException to be thrown for non-selected field in nested parent');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Account, field name: Id',
        e.getMessage(),
        'Expected QueryException with specific message for non-selected field in nested parent'
      );
    }
  }

  @isTest
  static void testGet_WhenEntryWithoutChildrenGetChildren_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .field('Name')
      .whereEqual('Id', '006000000000001');
    MockEntry accountEntry = new MockEntry(new Account(Id = '001000000000000001', Name = 'Test Account'));
    IEloquent eloquent = new MockEloquent(accountEntry);

    // Act & Assert
    List<IEntry> entries = eloquent.get(scribe);
    try {
      IEntry entry = entries[0];
      entry.getChildren('Opportunity'); // This child does not exist in the mock entry
      Assert.fail('Expected QueryException to be thrown for non-existing child');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual(
        'The specified childObjectName is not set in Scribe. object name: Account, child object name: Opportunity',
        e.getMessage(),
        'Expected QueryException with specific message for non-existing child'
      );
    }
  }

  @isTest
  static void testGet_WhenEntryWithChildrenGetNonSelectedField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .field('Name')
      .withChildren(Scribe.source(Contact.getSObjectType()).field('Id')) // 'Name' field is not selected
      .whereEqual('Id', '001000000000001');
    MockEntry accountEntry = new MockEntry(
      new Account(Id = '001000000000001', Name = 'Test Account'),
      new Map<String, Object>{
        'Contact' => new List<IEntry>{
          new MockEntry(
            new Contact(Id = '003000000000001'),
            new Map<String, Object>{ 'Name' => 'Test Contact 1' }
          ),
          new MockEntry(new Contact(Id = '003000000000002'), new Map<String, Object>{ 'Name' => 'Test Contact 2' })
        }
      }
    );
    IEloquent eloquent = new MockEloquent(accountEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    try {
      IEntry entry = entries[0];
      List<IEntry> contacts = entry.getChildren('Contact');
      for (IEntry contact : contacts) {
        contact.getName(); // This field is not selected in the Scribe query
      }
      Assert.fail('Expected QueryException to be thrown for non-selected field in child');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Contact, field name: Name',
        e.getMessage(),
        'Expected QueryException with specific message for non-selected field in child'
      );
    }
  }

  @isTest
  static void testGet_WhenEntryWithNestedChildrenGetNonSelectedField_ThenThrowException() {
    // Arrange
    List<String> fields = new List<String>{ 'Name' };
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

    MockEntry accountEntry = new MockEntry(
      new Account(Name = 'Test Account'),
      new Map<String, Object>{
        'Contact' => new List<IEntry>{
          new MockEntry(
            new Contact(),
            new Map<String, Object>{
              'Name' => 'Test Contact 1',
              'Opportunity' => new List<IEntry>{
                new MockEntry(
                  new Opportunity(Name = 'Test Opportunity 1'),
                  new Map<String, Object>{
                    'Quote' => new List<IEntry>{
                      new MockEntry(
                        new Quote(Name = 'Test Quote 1'),
                        new Map<String, Object>{
                          'Order' => new List<IEntry>{ new MockEntry(new Order(Name = 'Test Order 1')) }
                        }
                      )
                    }
                  }
                )
              }
            }
          )
        }
      }
    );
    IEloquent eloquent = new MockEloquent(accountEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);
    List<IEntry> contacts = entries[0].getChildren('Contact');
    List<IEntry> opportunities1 = contacts[0].getChildren('Opportunity');
    List<IEntry> quotes1 = opportunities1[0].getChildren('Quote');
    List<IEntry> orders1 = quotes1[0].getChildren('Order');

    // Assert
    try {
      for (IEntry order : orders1) {
        order.getId(); // This field is not selected in the Scribe query
        Assert.fail('Expected QueryException to be thrown for non-selected field in nested child');
      }
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual(
        'The specified field is not selected in Scribe. object name: Order, field name: Id',
        e.getMessage(),
        'Expected QueryException with specific message for non-selected field in nested child'
      );
    }
  }

  @isTest
  static void testFirst_WhenEntryExists_ThenReturnFirstEntry() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    IEntry entry = eloquent.first(scribe);

    // Assert
    Assert.isNotNull(entry, 'Expected first entry to be returned');
    Assert.areEqual('006000000000000001', entry.getId(), 'Expected entry ID to match');
  }

  @isTest
  static void testFirst_WhenNoEntries_ThenReturnNull() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act
    IEntry entry = eloquent.first(scribe);

    // Assert
    Assert.isNull(entry, 'Expected null when no entries exist');
  }

  @isTest
  static void testFirst_WhenFieldisNotSelected_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    try {
      IEntry entry = eloquent.first(scribe);
      entry.getName(); // This field is not selected in the Scribe query
      Assert.fail('Expected QueryException to be thrown for non-selected field');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.isTrue(
        e.getMessage()
          .contains('The specified field is not selected in Scribe. object name: Opportunity, field name: Name'),
        'Expected QueryException with specific message for non-selected field'
      );
    }
  }

  @isTest
  static void testFirstOrFail_WhenEntryExists_ThenReturnFirstEntry() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    IEntry entry = eloquent.firstOrFail(scribe);

    // Assert
    Assert.isNotNull(entry, 'Expected first entry to be returned');
    Assert.areEqual('006000000000000001', entry.getId(), 'Expected entry ID to match');
  }

  @isTest
  static void testFirstOrFail_WhenNoEntries_ThenReturnNull() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      IEntry entry = eloquent.firstOrFail(scribe);
      Assert.fail('Expected QueryException to be thrown when no entries exist');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual(
        'No records found for query: ' + scribe.toSoql(),
        e.getMessage(),
        'Expected QueryException with specific message'
      );
    }
  }

  @isTest
  static void testFirstOrFail_WhenFieldisNotSelected_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    try {
      IEntry entry = eloquent.first(scribe);
      entry.getName(); // This field is not selected in the Scribe query
      Assert.fail('Expected QueryException to be thrown for non-selected field');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.isTrue(
        e.getMessage()
          .contains('The specified field is not selected in Scribe. object name: Opportunity, field name: Name'),
        'Expected QueryException with specific message for non-selected field'
      );
    }
  }

  @isTest
  static void testDoInsert_WhenRecordIsInserted_ThenReturnRecordWithId() {
    // Arrange
    Opportunity record = new Opportunity(Name = 'Test Opportunity');
    IEloquent eloquent = new MockEloquent();

    // Act
    Opportunity insertedRecord = (Opportunity) eloquent.doInsert(record);

    // Assert
    Assert.isNotNull(insertedRecord.Id, 'Expected record to have an Id after insertion');
    Assert.areEqual('Test Opportunity', insertedRecord.Name, 'Expected record Name to match');
    Assert.areEqual('006000000000000', insertedRecord.Id, 'Expected record Id to be generated');
  }

  @isTest
  static void testDoInsert_WhenMultipleRecordsAreInserted_ThenReturnRecordsWithIds() {
    // Arrange
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Name = 'Test Opportunity 1'),
      new Opportunity(Name = 'Test Opportunity 2')
    };
    IEloquent eloquent = new MockEloquent();
    // Act
    List<Opportunity> insertedRecords = (List<Opportunity>) eloquent.doInsert(records);
    // Assert
    Assert.isTrue(insertedRecords.size() == 2, 'Expected two records to be inserted');
    for (Integer i = 0; i < insertedRecords.size(); i++) {
      Opportunity record = insertedRecords[i]; 
      Assert.isNotNull(record.Id, 'Expected each record to have an Id after insertion');
      String generatedId = '00600000000000' + String.valueOf(i);
      Assert.areEqual(generatedId, record.Id, 'Expected each record Id to be generated');
    }
  }

  @isTest
  static void testDoUpdate_WhenRecordIsUpdated_ThenReturnRecord() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity');
    IEloquent eloquent = new MockEloquent();

    // Act
    Opportunity updatedRecord = (Opportunity) eloquent.doUpdate(record);

    // Assert
    Assert.isNotNull(updatedRecord.Id, 'Expected record to have an Id after update');
    Assert.areEqual('Updated Opportunity', updatedRecord.Name, 'Expected record Name to match after update');
  }

  @isTest
  static void testDoUpdate_WhenMultipleRecordsAreUpdated_ThenReturnRecords() {
    // Arrange
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity 1'),
      new Opportunity(Id = '006000000000002', Name = 'Updated Opportunity 2')
    };
    IEloquent eloquent = new MockEloquent();

    // Act
    List<Opportunity> updatedRecords = (List<Opportunity>) eloquent.doUpdate(records);

    // Assert
    Assert.isTrue(updatedRecords.size() == 2, 'Expected two records to be updated');
  }

  @isTest
  static void testDoDelete_WhenRecordIsDeleted_ThenNoExceptionThrown() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Test Opportunity');
    IEloquent eloquent = new MockEloquent();

    // Act
    eloquent.doDelete(record);

    // Assert
    // No exception should be thrown, indicating successful deletion
  }

  @isTest
  static void testDoDelete_WhenMultipleRecordsAreDeleted_ThenNoExceptionThrown() {
    // Arrange
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Id = '006000000000001', Name = 'Test Opportunity 1'),
      new Opportunity(Id = '006000000000002', Name = 'Test Opportunity 2')
    };
    IEloquent eloquent = new MockEloquent();

    // Act
    eloquent.doDelete(records);

    // Assert
    // No exception should be thrown, indicating successful deletion
  }
}
