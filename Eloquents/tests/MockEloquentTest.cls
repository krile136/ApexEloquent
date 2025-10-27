/**
 * Copyright 2025 Hiroyuki Matsuoka
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
  static void testGet_WhenEntryExitAndUsingMockEntryGenerator_ThenReturnEntries() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '00600000000000');
    MockEntry mockEntry = MockENtry.of(Opportunity.getSObjectType()).autoId(1).add('Name', 'Test Opportunity');
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(!entries.isEmpty(), 'Expected entries to be returned');
    Assert.areEqual('006000000000001AAA', entries[0].getId(), 'Expected entry ID to match');
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
      .parentField(Scribe.asParent('AccountId').field('Id').field('Name'))
      .whereEqual('Id', '006000000000001');
    MockENtry oppEntry = MockEntry.of(Opportunity.getSObjectType())
      .autoId(1)
      .add('Name', 'Test Opportunity')
      .addParent('AccountId', MockEntry.of(Account.getSObjectType()).autoId(1).add('Name', 'Test Account'));

    IEloquent eloquent = new MockEloquent(oppEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 1, 'Expected one nested entry to be returned');
    Assert.areEqual('006000000000001AAA', entries[0].getId(), 'Expected nested entry ID to match');
    Assert.areEqual('Test Opportunity', entries[0].getName(), 'Expected nested entry Name to match');
    IEntry accountEntry = entries[0].getParent('AccountId');
    Assert.areEqual('001000000000001AAA', accountEntry.getId(), 'Expected nested child entry ID to match');
    Assert.areEqual('Test Account', accountEntry.getName(), 'Expected nested child entry Name to match');
  }

  @isTest
  static void testGet_WhenEntryWithNestedParentExist_ThenReturnNestedEntries() {
    // Arrange
    List<String> fields = new List<String>{ 'Name' };
    Scribe scribe = Scribe.source(OrderItem.getSObjectType())
      .field('ListPrice')
      .parentField(
        Scribe.asParent('OrderId')
          .fields(fields)
          .parentField(
            Scribe.asParent('OriginalOrderId')
              .fields(fields)
              .parentField(
                Scribe.asParent('QuoteId')
                  .fields(fields)
                  .parentField(
                    Scribe.asParent('OpportunityId')
                      .fields(fields)
                      .parentField(Scribe.asParent('ContractId').fields(fields))
                  )
              )
          )
      );
    MockEntry orderItemEntry = MockEntry.of(OrderItem.getSObjectType())
      .add('ListPrice', 100)
      .addParent(
        'OrderId',
        MockEntry.of(Order.getSObjectType())
          .add('Name', 'Test Order')
          .addParent(
            'OriginalOrderId',
            MockEntry.of(Order.getSObjectType())
              .add('Name', 'Original Test Order')
              .addParent(
                'QuoteId',
                MockEntry.of(Quote.getSObjectType())
                  .add('Name', 'Test Quote')
                  .addParent(
                    'OpportunityId',
                    MockEntry.of(Opportunity.getSObjectType())
                      .add('Name', 'Test Opportunity')
                      .addParent(
                        'ContractId',
                        MockEntry.of(Contract.getSObjectType()).add('Name', 'Test Contract')
                      )
                  )
              )
          )
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
      .withChildren(Scribe.asChild(Contact.getSObjectType()).field('Id').field('Name'))
      .whereEqual('Id', '001000000000001');
    MockEntry accountEntry = MockEntry.of(Account.getSObjectType())
      .autoId(1)
      .add('Name', 'Test Account')
      .addChildren(
        'Contact',
        MockEntry.of(Contact.getSObjectType()).autoId('{#}').add('Name', 'Test Contact {#}').times(2)
      );

    IEloquent eloquent = new MockEloquent(accountEntry);

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 1, 'Expected one entry to be returned');
    Assert.areEqual('001000000000001AAA', entries[0].getId(), 'Expected entry ID to match');
    Assert.areEqual('Test Account', entries[0].getName(), 'Expected entry Name to match');
    List<IEntry> contacts = entries[0].getChildren('Contact');
    Assert.isTrue(contacts.size() == 2, 'Expected two child entries to be returned');
    Assert.areEqual('003000000000001AAA', contacts[0].getId(), 'Expected first child entry ID to match');
    Assert.areEqual('Test Contact 1', contacts[0].getName(), 'Expected first child entry Name to match');
    Assert.areEqual('003000000000002AAA', contacts[1].getId(), 'Expected second child entry ID to match');
    Assert.areEqual('Test Contact 2', contacts[1].getName(), 'Expected second child entry Name to match');
  }

  @isTest
  static void testGet_WhenEntriesWithNestedChildren_ThenReturnEntriesWithNestedChildren() {
    // Arrange
    List<String> fields = new List<String>{ 'Name' };
    Scribe scribe = Scribe.source(Account.getSObjectType())
      .fields(fields)
      .withChildren(
        Scribe.asChild(Contact.getSObjectType())
          .fields(fields)
          .withChildren(
            Scribe.asChild(Opportunity.getSObjectType())
              .fields(fields)
              .withChildren(
                Scribe.asChild(Quote.getSObjectType())
                  .fields(fields)
                  .withChildren(Scribe.asChild(Order.getSObjectType()).fields(fields))
              )
          )
      );

    MockEntry accountEntry = MockEntry.of(Account.getSObjectType())
      .add('Name', 'Test Account')
      .addChildren(
        'Contact',
        new List<MockEntry>{
          MockEntry.of(Contact.getSObjectType())
            .add('Name', 'Test Contact 1')
            .addChildren(
              'Opportunity',
              new List<MockEntry>{
                MockEntry.of(Opportunity.getSObjectType())
                  .add('Name', 'Test Opportunity 1')
                  .addChildren(
                    'Quote',
                    new List<MockEntry>{
                      MockEntry.of(Quote.getSObjectType())
                        .add('Name', 'Test Quote 1')
                        .addChildren(
                          'Order',
                          new List<MockEntry>{ MockEntry.of(Order.getSObjectType()).add('Name', 'Test Order 1') }
                        )
                    }
                  )
              }
            ),
          MockEntry.of(Contact.getSObjectType())
            .add('Name', 'Test Contact 2')
            .addChildren(
              'Opportunity',
              new List<MockEntry>{
                MockEntry.of(Opportunity.getSObjectType())
                  .add('Name', 'Test Opportunity 2')
                  .addChildren(
                    'Quote',
                    new List<MockEntry>{
                      MockEntry.of(Quote.getSObjectType())
                        .add('Name', 'Test Quote 2')
                        .addChildren(
                          'Order',
                          new List<MockEntry>{ MockEntry.of(Order.getSObjectType()).add('Name', 'Test Order 2') }
                        )
                    }
                  )
              }
            )
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
      .parentField(Scribe.asParent('AccountId').field('Id')) // 'Name' field is not selected
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
    Scribe scribe = Scribe.source(Order.getSObjectType())
      .field('Id')
      .field('Name')
      .whereEqual('Id', '801000000000001');
    MockEntry accountEntry = new MockEntry(new Order(Id = '801000000000000001', Name = 'Test Account'));
    IEloquent eloquent = new MockEloquent(accountEntry);

    // Act & Assert
    List<IEntry> entries = eloquent.get(scribe);
    try {
      IEntry entry = entries[0];
      entry.getChildren('OrderItem'); // This child does not exist in the mock entry
      Assert.fail('Expected QueryException to be thrown for non-existing child');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual(
        'The specified childObjectName is not set in Scribe. object name: Order, child object name: OrderItem',
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
      .withChildren(Scribe.asChild(Contact.getSObjectType()).field('Id')) // 'Name' field is not selected
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
        Scribe.asChild(Contact.getSObjectType())
          .fields(fields)
          .withChildren(
            Scribe.asChild(Opportunity.getSObjectType())
              .fields(fields)
              .withChildren(
                Scribe.asChild(Quote.getSObjectType())
                  .fields(fields)
                  .withChildren(Scribe.asChild(Order.getSObjectType()).fields(fields))
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
  static void testFirstOrFailAsSObject_WhenEntryExists_ThenReturnFirstEntry() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    Opportunity opp = (Opportunity) eloquent.firstOrFailAsSObject(scribe);

    // Assert
    Assert.isNotNull(opp, 'Expected first entry to be returned');
    Assert.areEqual('006000000000000001', opp.Id, 'Expected entry ID to match');
    Assert.areEqual('Test Opportunity', opp.Name, 'Expected entry Name to match');
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
  static void testDoUpdate_WhenApplyEntry_ThenReturnEntry() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Opportunity.getSObjectType())
      .fields(new List<String>{ 'Id', 'Name' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.getSObjectType())
      .autoId(1)
      .add('Name', 'Opportunity 1')
      .setFieldStructure(fieldStructure);

    IEloquent eloquent = new MockEloquent();

    // Act
    mockEntry.put('Name', 'Updated Opportunity 1');
    IEntry updatedEntry = eloquent.doUpdate(mockEntry);

    // Assert
    Assert.isNotNull(updatedEntry.getId(), 'Expected entry to have an Id after update');
    Assert.areEqual(
      'Updated Opportunity 1',
      updatedEntry.get('Name'),
      'Expected entry Name to match after update'
    );
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
  static void testDoUpdate_WhenMultipleEntriesAreUpdated_ThenReturnEntries() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Opportunity.getSObjectType())
      .fields(new List<String>{ 'Id', 'Name' })
      .buildFieldStructure();
    List<MockEntry> mockEntries = MockEntry.of(Opportunity.getSObjectType())
      .autoId('{#}')
      .add('Name', 'Opportunity {#}')
      .times(2);
    List<MockEntry> updateEntries = new List<MockEntry>();
    for (MockEntry entry : mockEntries) {
      updateEntries.add((MockEntry) entry.setFieldStructure(fieldStructure));
    }
    IEloquent eloquent = new MockEloquent();

    // Act
    for (MockEntry entry : updateEntries) {
      entry.put('Name', 'Updated ' + entry.get('Name'));
    }
    List<IEntry> resultEntries = eloquent.doUpdate(updateEntries);

    // Assert
    Assert.areEqual(2, resultEntries.size(), 'Expected two entries to be updated');
    for (Integer i = 0; i < resultEntries.size(); i++) {
      IEntry entry = resultEntries[i];
      Assert.isNotNull(entry.getId(), 'Expected each entry to have an Id after update');
      Assert.areEqual(
        'Updated Opportunity ' + (i + 1),
        entry.get('Name'),
        'Expected each entry Name to match after update'
      );
    }
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
  static void testDoDelete_WhenEntryIsDeleted_ThenNoExceptionThrown() {
    // Arrange
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.getSObjectType())
      .autoId(1)
      .add('Name', 'Opportunity 1');
    IEloquent eloquent = new MockEloquent();

    // Act
    eloquent.doDelete(mockEntry);

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

  @isTest
  static void testDoDelete_WhenMultipleEntriesAreDeleted_ThenNoExceptionThrown() {
    // Arrange
    List<MockEntry> mockEntries = MockEntry.of(Opportunity.getSObjectType())
      .autoId('{#}')
      .add('Name', 'Opportunity {#}')
      .times(2);
    IEloquent eloquent = new MockEloquent();

    // Act
    eloquent.doDelete(mockEntries);

    // Assert
    // No exception should be thrown, indicating successful deletion
  }

  @isTest
  static void testGetAggregate_WhenApplyNonAggregateScribe_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      eloquent.getAggregate(scribe);
      Assert.fail('Expected QueryException to be thrown for non-aggregate Scribe');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.isTrue(
        e.getMessage().startsWith('The provided Scribe instance does not represent an aggregate query: ')
      );
    }
  }

  @isTest
  static void testGetAggregate_WhenAggregateEntryExist_ThenReturnEntries() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    IEloquent eloquent = new MockEloquent(
      new List<IEntry>{
        new MockEntry(new Map<String, Object>{ 'StageName' => 'Prospecting', 'avgAmount' => 5000 }),
        new MockEntry(new Map<String, Object>{ 'StageName' => 'Closed Won', 'avgAmount' => 15000 })
      }
    );

    // Act
    List<IEntry> entries = eloquent.getAggregate(scribe);

    // Assert
    Assert.isTrue(entries.size() == 2, 'Expected two aggregate entries to be returned');
    Assert.areEqual('Prospecting', entries[0].get('StageName'), 'Expected first entry StageName to match');
    Assert.areEqual(5000, entries[0].get('avgAmount'), 'Expected first entry avgAmount to match');
    Assert.areEqual('Closed Won', entries[1].get('StageName'), 'Expected second entry StageName to match');
    Assert.areEqual(15000, entries[1].get('avgAmount'), 'Expected second entry avgAmount to match');
  }

  @isTest
  static void testGetAggregate_WhenAccessNonSelectedField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    IEloquent eloquent = new MockEloquent(
      new List<IEntry>{
        new MockEntry(new Map<String, Object>{ 'StageName' => 'Prospecting', 'avgAmount' => 5000 })
      }
    );

    // Act & Assert
    try {
      List<IEntry> entries = eloquent.getAggregate(scribe);
      IEntry entry = entries[0];
      entry.get('CloseDate'); // This field is not selected in the Scribe query
      Assert.fail('Expected QueryException to be thrown for non-selected field');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      String expected = String.format(
        'The specified field or alias is not exist in Scribe. field or alias name: {0}',
        new List<String>{ 'CloseDate' }
      );
      Assert.areEqual(
        expected,
        e.getMessage(),
        'Expected QueryException with specific message for non-selected field'
      );
    }
  }

  @isTest
  static void testGetAggregate_WhenAccessNonExistAlias_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    IEloquent eloquent = new MockEloquent(
      new List<IEntry>{
        new MockEntry(new Map<String, Object>{ 'StageName' => 'Prospecting', 'avgAmount' => 5000 })
      }
    );

    // Act & Assert
    try {
      List<IEntry> entries = eloquent.getAggregate(scribe);
      IEntry entry = entries[0];
      entry.get('totalAmount'); // This alias does not exist in the Scribe query
      Assert.fail('Expected QueryException to be thrown for non-existing alias');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      String expected = String.format(
        'The specified field or alias is not exist in Scribe. field or alias name: {0}',
        new List<String>{ 'totalAmount' }
      );
      Assert.areEqual(
        expected,
        e.getMessage(),
        'Expected QueryException with specific message for non-existing alias'
      );
    }
  }

  @isTest
  static void testGetAggregate_WhenAddNestedAggregate_ThenCanAccessFieldAndAliasAsFlatField() {
    // Arrange
    Scribe scribe = Scribe.source(OrderItem.getSObjectType())
      .count('Id', 'itemCount')
      .parentField(
        Scribe.asParent('OrderId')
          .parentField(
            Scribe.asParent('OriginalOrderId')
              .parentField(
                Scribe.asParent('QuoteId')
                  .parentField(
                    Scribe.asParent('OpportunityId')
                      .parentField(Scribe.asParent('AccountId').field('Type').count('Name', 'accountCount'))
                  )
              )
          )
      )
      .groupByParent(
        Scribe.asParent('OrderId')
          .groupByParent(
            Scribe.asParent('OriginalOrderId')
              .groupByParent(
                Scribe.asParent('QuoteId')
                  .groupByParent(
                    Scribe.asParent('OpportunityId')
                      .groupByParent(Scribe.asParent('AccountId').groupByField('Type'))
                  )
              )
          )
      );
    IEloquent eloquent = new MockEloquent(
      new MockEntry(new Map<String, Object>{ 'itemCount' => 10, 'accountCount' => 5, 'Type' => 'TestType1' })
    );

    // Act
    List<IEntry> entries = eloquent.getAggregate(scribe);

    // Assert
    Assert.isTrue(entries.size() == 1, 'Expected one aggregate entry to be returned');
    IEntry entry = entries[0];
    Assert.areEqual(10, entry.get('itemCount'), 'Expected itemCount to match');
    Assert.areEqual(5, entry.get('accountCount'), 'Expected accountCount to match');
    Assert.areEqual('TestType1', entry.get('Type'), 'Expected Type to match');
  }

  @isTest
  static void testGet_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('StageName', 'Prospecting');

    // Act & Assert
    try {
      eloquent.get(scribe);
      Assert.fail('Expected QueryException to be thrown for get method');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.get()', e.getMessage());
    }
  }

  @isTest
  static void testGetAsSObject_WhenEntriesExist_ThenReturnSObjects() {
    // Arrange
    Scribe scribe = Scribe.source(Opportunity.getSObjectType()).field('Id').whereEqual('Id', '006000000000001');
    List<MockEntry> mockEntries = new List<MockEntry>{
      new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Test Opportunity')),
      new MockEntry(new Opportunity(Id = '006000000000002', Name = 'Another Opportunity'))
    };
    IEloquent eloquent = new MockEloquent(mockEntries);

    // Act
    List<SObject> records = eloquent.getAsSObject(scribe);

    // Assert
    Assert.areEqual(2, records.size(), 'Expected two SObject records to be returned');
    Opportunity record = (Opportunity) records[0];
    Assert.areEqual('006000000000001', record.Id, 'Expected record ID to match');
    Assert.areEqual('Test Opportunity', record.Name, 'Expected record Name to match');
    Opportunity record2 = (Opportunity) records[1];
    Assert.areEqual('006000000000002', record2.Id, 'Expected second record ID to match');
    Assert.areEqual('Another Opportunity', record2.Name, 'Expected second record Name to match');
  }

  @isTest
  static void testGetAggregate_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Scribe scribe = Scribe.source(Opportunity.getSObjectType())
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');

    // Act & Assert
    try {
      eloquent.getAggregate(scribe);
      Assert.fail('Expected QueryException to be thrown for getAggregate method');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.getAggregate()', e.getMessage());
    }
  }

  @isTest
  static void testGetAsSObject_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('StageName', 'Prospecting');

    // Act & Assert
    try {
      eloquent.getAsSObject(scribe);
      Assert.fail('Expected QueryException to be thrown for getAsSObject method');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.getAsSObject()', e.getMessage());
    }
  }

  @isTest
  static void testFirst_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('StageName', 'Prospecting');

    // Act & Assert
    try {
      eloquent.first(scribe);
      Assert.fail('Expected QueryException to be thrown for first method');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.first()', e.getMessage());
    }
  }

  @isTest
  static void testFirstAsSObject_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('StageName', 'Prospecting');

    // Act & Assert
    try {
      eloquent.firstAsSObject(scribe);
      Assert.fail('Expected QueryException to be thrown for firstAsSObject method');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.firstAsSObject()', e.getMessage());
    }
  }

  @isTest
  static void testFirstOrFail_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('StageName', 'Prospecting');

    // Act & Assert
    try {
      eloquent.firstOrFail(scribe);
      Assert.fail('Expected QueryException to be thrown for firstOrFail method');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.firstOrFail()', e.getMessage());
    }
  }

  @isTest
  static void testFirstOrFailAsSObject_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Scribe scribe = Scribe.source(Account.getSObjectType()).field('Id').whereEqual('StageName', 'Prospecting');

    // Act & Assert
    try {
      eloquent.firstOrFailAsSObject(scribe);
      Assert.fail('Expected QueryException to be thrown for firstOrFailAsSObject method');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.firstOrFailAsSObject()', e.getMessage());
    }
  }

  @isTest
  static void testDoInsert_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Opportunity record = new Opportunity(Name = 'Test Opportunity');

    // Act & Assert
    try {
      eloquent.doInsert(record);
      Assert.fail('Expected QueryException to be thrown for doInsert method');
    } catch (DmlException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.doInsert()', e.getMessage());
    }
  }

  @isTest
  static void testDoInsert_WhenShouldThrowIsTrueWithInsertMultipleRecord_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Name = 'Test Opportunity 1'),
      new Opportunity(Name = 'Test Opportunity 2')
    };

    // Act & Assert
    try {
      eloquent.doInsert(records);
      Assert.fail('Expected QueryException to be thrown for doInsert method with multiple records');
    } catch (DmlException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.doInsert()', e.getMessage());
    }
  }

  @isTest
  static void testDoUpdate_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity');
    // Act & Assert
    try {
      eloquent.doUpdate(record);
      Assert.fail('Expected QueryException to be thrown for doUpdate method');
    } catch (DmlException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.doUpdate()', e.getMessage());
    }
  }

  @isTest
  static void testDoUpdate_WhenShouldThrowIsTrueWithUpdateMultipleRecord_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity 1'),
      new Opportunity(Id = '006000000000002', Name = 'Updated Opportunity 2')
    };
    // Act & Assert
    try {
      eloquent.doUpdate(records);
      Assert.fail('Expected QueryException to be thrown for doUpdate method with multiple records');
    } catch (DmlException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.doUpdate()', e.getMessage());
    }
  }

  @isTest
  static void testDoUpsert_WhenAddNullRecord_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      SObject record = null;
      eloquent.doUpsert(record);
      Assert.fail('Expected IllegalArgumentException to be thrown for null record');
    } catch (DmlException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Cannot upsert null record', e.getMessage());
    }
  }

  @isTest
  static void testDoUpsert_WhenAddSObject_ThenReturnUpsertedRecord() {
    // Arrange
    Opportunity record = new Opportunity(Name = 'Upserted Opportunity');
    IEloquent eloquent = new MockEloquent();

    // Act
    Opportunity upsertedRecord = (Opportunity) eloquent.doUpsert(record);

    // Assert
    Assert.isNotNull(upsertedRecord.Id, 'Expected record to have an Id after upsert');
    Assert.areEqual('Upserted Opportunity', upsertedRecord.Name, 'Expected record Name to match after upsert');
  }

  @isTest
  static void testDoUpsert_WhenAddNullEntry_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      IEntry entry = null;
      eloquent.doUpsert(entry);
      Assert.fail('Expected IllegalArgumentException to be thrown for null entry');
    } catch (DmlException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Cannot upsert null entry', e.getMessage());
    }
  }

  @isTest
  static void testDoUpsert_WhenAddEntry_ThenReturnUpsertedEntry() {
    // Arrange
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.getSObjectType());
    IEloquent eloquent = new MockEloquent();

    // Act
    IEntry upsertedEntry = eloquent.doUpsert(mockEntry);

    // Assert
    Assert.isNotNull(upsertedEntry.getId(), 'Expected entry to have an Id after upsert');
  }

  @isTest
  static void testDoUpsert_WhenAddMultiRecords_ThenReturnUpsertedRecords() {
    // Arrange
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Name = 'Upserted Opportunity 1'),
      new Opportunity(Name = 'Upserted Opportunity 2')
    };
    IEloquent eloquent = new MockEloquent();

    // Act
    List<Opportunity> upsertedRecords = (List<Opportunity>) eloquent.doUpsert(records);

    // Assert
    Assert.isTrue(upsertedRecords.size() == 2, 'Expected two records to be upserted');
    for (Integer i = 0; i < upsertedRecords.size(); i++) {
      Opportunity record = upsertedRecords[i];
      Assert.isNotNull(record.Id, 'Expected each record to have an Id after upsert');
      String expectedName = 'Upserted Opportunity ' + (i + 1);
      Assert.areEqual(expectedName, record.Name, 'Expected each record Name to match after upsert');
    }
  }

  @isTest
  static void testDoUpsert_WhenAddMultiEntries_ThenReturnUpsertedEntries() {
    // Arrange
    List<MockEntry> mockEntries = new List<MockEntry>{
      MockEntry.of(Opportunity.getSObjectType()),
      MockEntry.of(Opportunity.getSObjectType()).autoId(1)
    };
    IEloquent eloquent = new MockEloquent();
    // Act
    List<IEntry> upsertedEntries = eloquent.doUpsert(mockEntries);
    // Assert
    Assert.areEqual(2, upsertedEntries.size(), 'Expected two entries to be upserted');
    for (Integer i = 0; i < upsertedEntries.size(); i++) {
      IEntry entry = upsertedEntries[i];
      Assert.isNotNull(entry.getId(), 'Expected each entry to have an Id after upsert');
    }
  }


  @isTest
  static void testDoDelete_WhenShouldThrowIsTrue_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Test Opportunity');

    // Act & Assert
    try {
      eloquent.doDelete(record);
      Assert.fail('Expected QueryException to be thrown for doDelete method');
    } catch (DmlException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.doDelete()', e.getMessage());
    }
  }

  @isTest
  static void testDoDelete_WhenShouldThrowIsTrueWithDeleteMultipleRecord_ThenThrowException() {
    // Arrange
    MockEloquent eloquent = new MockEloquent(true);
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Id = '006000000000001', Name = 'Test Opportunity 1'),
      new Opportunity(Id = '006000000000002', Name = 'Test Opportunity 2')
    };
    // Act & Assert
    try {
      eloquent.doDelete(records);
      Assert.fail('Expected QueryException to be thrown for doDelete method with multiple records');
    } catch (DmlException e) {
      System.debug(e.getMessage());
      Assert.areEqual('Test Exception from MockEloquent.doDelete()', e.getMessage());
    }
  }
}
