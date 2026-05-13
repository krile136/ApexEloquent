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
  static void testGet_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = null;

    // Act & Assert
    try {
      (new MockEloquent()).get(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  // ====== rawSoql ======

  @isTest
  static void testRawSoql_WhenSoqlIsBlank_ThenThrowException() {
    try {
      (new MockEloquent()).rawSoql(null);
      Assert.fail('Expected ApexEloquentException when SOQL is null');
    } catch (ApexEloquentException e) {
      String msg = e.getMessage();
      Assert.isTrue(msg.contains('rawSoql(String soql)'), 'should mention rawSoql method');
      Assert.isTrue(msg.contains('argument is required'), 'should indicate required-parameter violation');
    }

    try {
      (new MockEloquent()).rawSoql('');
      Assert.fail('Expected ApexEloquentException when SOQL is empty');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('rawSoql(String soql)'), 'should mention rawSoql method');
    }
  }

  @isTest
  static void testRawSoql_WhenAccessUnselectedField_ThenDoesNotThrow() {
    // Raw SOQL bypasses the Scribe FieldStructure pipeline; the returned mock IEntry
    // should have select-forgotten detection disabled so that any field can be read.
    // Arrange — register a MockEntry built via a Scribe with only 'Id' selected.
    Scribe scribe = Scribe.of(Opportunity.class).field('Id');
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    MockEntry mockEntry = new MockEntry(
      new Opportunity(Id = '006000000000001', Name = 'Test Opportunity'),
      fieldStructure,
      new Map<String, Object>{ 'Name' => 'Test Opportunity' }
    );
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act — call rawSoql (which should disable select-forgotten detection)
    List<IEntry> entries = eloquent.rawSoql('SELECT Id FROM Opportunity');

    // Assert — accessing 'Name' (NOT selected in the original Scribe) must not throw
    Assert.areEqual(1, entries.size(), 'should return the registered entry');
    Object name = entries[0].get('Name');
    Assert.areEqual('Test Opportunity', name, 'should return the mocked value without select-forgotten detection');
  }

  @isTest
  static void testRawSoql_WhenFailOnRawSoqlNoArg_ThenThrowTestException() {
    // Arrange
    MockEloquent eloquent = (new MockEloquent()).failOnRawSoql();

    // Act & Assert
    try {
      eloquent.rawSoql('SELECT Id FROM Opportunity');
      Assert.fail('Expected forced ApexEloquentException');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('Forced Exception for Testing'), 'should be the framework testException');
      Assert.isTrue(e.getMessage().contains('rawSoql(String soql)'), 'should attach the method signature');
    }
  }

  @isTest
  static void testRawSoql_WhenFailOnRawSoqlWithCustomException_ThenThrowThatException() {
    // Arrange
    Exception customEx = new System.DmlException('custom failure');
    MockEloquent eloquent = (new MockEloquent()).failOnRawSoql(customEx);

    // Act & Assert
    try {
      eloquent.rawSoql('SELECT Id FROM Opportunity');
      Assert.fail('Expected the custom exception to be thrown');
    } catch (System.DmlException e) {
      Assert.areEqual('custom failure', e.getMessage(), 'should propagate the user-supplied exception verbatim');
    }
  }

  @isTest
  static void testGet_WhenEntryExist_ThenReturnEntries() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '00600000000000');
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
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '00600000000000');
    MockEntry mockEntry = MockEntry.of(Opportunity.class).autoId(1).add('Name', 'Test Opportunity');
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
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.isEmpty(), 'Expected no entries to be returned');
  }

  @isTest
  static void testGet_WhenEntriesExist_ThenReturnEntries() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000001');
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
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .field('Name')
      .parentField(Scribe.asParent('AccountId').field('Id').field('Name'))
      .whereEqual('Id', '006000000000001');
    MockEntry oppEntry = MockEntry.of(Opportunity.class)
      .autoId(1)
      .add('Name', 'Test Opportunity')
      .addParent('AccountId', MockEntry.of(Account.class).autoId(1).add('Name', 'Test Account'));

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
    Scribe scribe = Scribe.of(OrderItem.class)
      .field('ListPrice')
      .parentField(
        Scribe.asParent('OrderId')
          .fields(fields)
          .parentField(
            Scribe.asParent('OriginalOrderId')
              .fields(fields)
              .parentField(
                Scribe.asParent('ContractId')
                  .fields(fields)
                  .parentField(
                    Scribe.asParent('AccountId')
                      .fields(fields)
                      .parentField(Scribe.asParent('ParentId').fields(fields))
                  )
              )
          )
      );
    MockEntry orderItemEntry = MockEntry.of(OrderItem.class)
      .add('ListPrice', 100)
      .addParent(
        'OrderId',
        MockEntry.of(Order.class)
          .add('Name', 'Test Order')
          .addParent(
            'OriginalOrderId',
            MockEntry.of(Order.class)
              .add('Name', 'Original Test Order')
              .addParent(
                'ContractId',
                MockEntry.of(Contract.class)
                  .add('Name', 'Test Contract')
                  .addParent(
                    'AccountId',
                    MockEntry.of(Account.class)
                      .add('Name', 'Test Account')
                      .addParent('ParentId', MockEntry.of(Account.class).add('Name', 'Parent Account'))
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
    IEntry contractEntry = originalOrderEntry.getParent('ContractId');
    Assert.areEqual('Test Contract', contractEntry.getName(), 'Expected nested great-grandchild entry Name to match');
    IEntry accountEntry = contractEntry.getParent('AccountId');
    Assert.areEqual(
      'Test Account',
      accountEntry.getName(),
      'Expected nested great-great-grandchild entry Name to match'
    );
    IEntry parentAccountEntry = accountEntry.getParent('ParentId');
    Assert.areEqual(
      'Parent Account',
      parentAccountEntry.getName(),
      'Expected nested great-great-great-grandchild entry Name to match'
    );
  }

  @isTest
  static void testGet_WhenEntriesWithChildrenExist_ThenReturnEntriesWithChildren() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .field('Name')
      .withChildren(Scribe.asChild(Contact.class).field('Id').field('Name'))
      .whereEqual('Id', '001000000000001');
    MockEntry accountEntry = MockEntry.of(Account.class)
      .autoId(1)
      .add('Name', 'Test Account')
      .addChildren('Contact', MockEntry.of(Contact.class).autoId('{#}').add('Name', 'Test Contact {#}').times(2));

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
    List<String> nameFields = new List<String>{ 'Name' };
    List<String> caseFields = new List<String>{ 'Subject' };
    Scribe scribe = Scribe.of(Account.class)
      .fields(nameFields)
      .withChildren(
        Scribe.asChild(Contact.class)
          .fields(nameFields)
          .withChildren(
            Scribe.asChild(Case.class)
              .fields(caseFields)
              .withChildren(
                Scribe.asChild(Case.class).fields(caseFields).withChildren(Scribe.asChild(Case.class).fields(caseFields))
              )
          )
      );

    MockEntry accountEntry = MockEntry.of(Account.class)
      .add('Name', 'Test Account')
      .addChildren(
        'Contact',
        new List<MockEntry>{
          MockEntry.of(Contact.class)
            .add('Name', 'Test Contact 1')
            .addChildren(
              'Case',
              new List<MockEntry>{
                MockEntry.of(Case.class)
                  .add('Subject', 'Test Case 1')
                  .addChildren(
                    'Case',
                    new List<MockEntry>{
                      MockEntry.of(Case.class)
                        .add('Subject', 'Test Child Case 1')
                        .addChildren(
                          'Case',
                          new List<MockEntry>{ MockEntry.of(Case.class).add('Subject', 'Test Grandchild Case 1') }
                        )
                    }
                  )
              }
            ),
          MockEntry.of(Contact.class)
            .add('Name', 'Test Contact 2')
            .addChildren(
              'Case',
              new List<MockEntry>{
                MockEntry.of(Case.class)
                  .add('Subject', 'Test Case 2')
                  .addChildren(
                    'Case',
                    new List<MockEntry>{
                      MockEntry.of(Case.class)
                        .add('Subject', 'Test Child Case 2')
                        .addChildren(
                          'Case',
                          new List<MockEntry>{ MockEntry.of(Case.class).add('Subject', 'Test Grandchild Case 2') }
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
    List<IEntry> cases1 = contacts[0].getChildren('Case');
    Assert.isTrue(cases1.size() == 1, 'Expected one case entry to be returned');
    Assert.areEqual('Test Case 1', cases1[0].get('Subject'), 'Expected case Subject to match');
    List<IEntry> childCases1 = cases1[0].getChildren('Case');
    Assert.isTrue(childCases1.size() == 1, 'Expected one child case entry to be returned');
    Assert.areEqual('Test Child Case 1', childCases1[0].get('Subject'), 'Expected child case Subject to match');
    List<IEntry> grandchildCases1 = childCases1[0].getChildren('Case');
    Assert.isTrue(grandchildCases1.size() == 1, 'Expected one grandchild case entry to be returned');
    Assert.areEqual('Test Grandchild Case 1', grandchildCases1[0].get('Subject'), 'Expected grandchild case Subject to match');

    // Assert second contact and its children
    Assert.areEqual('Test Contact 2', contacts[1].getName(), 'Expected second child entry Name to match');
    List<IEntry> cases2 = contacts[1].getChildren('Case');
    Assert.isTrue(cases2.size() == 1, 'Expected one case entry to be returned');
    Assert.areEqual('Test Case 2', cases2[0].get('Subject'), 'Expected case Subject to match');
    List<IEntry> childCases2 = cases2[0].getChildren('Case');
    Assert.isTrue(childCases2.size() == 1, 'Expected one child case entry to be returned');
    Assert.areEqual('Test Child Case 2', childCases2[0].get('Subject'), 'Expected child case Subject to match');
    List<IEntry> grandchildCases2 = childCases2[0].getChildren('Case');
    Assert.isTrue(grandchildCases2.size() == 1, 'Expected one grandchild case entry to be returned');
    Assert.areEqual('Test Grandchild Case 2', grandchildCases2[0].get('Subject'), 'Expected grandchild case Subject to match');
  }

  @isTest
  static void testGet_WhenGetNonSelectedField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '00600000000000');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act & Assert
    List<IEntry> entries = eloquent.get(scribe);
    try {
      IEntry entry = entries[0];
      entry.getName(); // This field is not selected in the Scribe query
      Assert.fail('Expected ApexEloquentException to be thrown for non-selected field');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified field is not selected in Scribe'));
      Assert.isTrue(error.contains('[objectName => \'Opportunity\']'));
      Assert.isTrue(error.contains('[fieldName => \'Name\']'));
    }
  }

  @isTest
  static void testGet_WhenEntryWithoutParentGetParent_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').field('Name').whereEqual('Id', '006000000000001');
    MockEntry oppEntry = new MockEntry(new Opportunity(Id = '006000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(oppEntry);

    // Act & Assert
    List<IEntry> entries = eloquent.get(scribe);
    try {
      IEntry entry = entries[0];
      entry.getParent('AccountId'); // This parent does not exist in the mock entry
      Assert.fail('Expected ApexEloquentException to be thrown for non-existing parent');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified parentIdFieldName is not defined as a relationship in Scribe'));
      Assert.isTrue(error.contains('parentIdFieldName \'AccountId\''));
    }
  }

  @isTest
  static void testGet_WhenEntryWithParentGetNonSelectedField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
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
      Assert.fail('Expected ApexEloquentException to be thrown for non-selected field in parent');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified field is not selected in Scribe'));
      Assert.isTrue(error.contains('[objectName => \'Account\']'));
      Assert.isTrue(error.contains('[fieldName => \'Name\']'));
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
            'contractid' => new FieldStructure(
              new List<String>{ 'name' },
              new Map<String, FieldStructure>{
                'accountid' => new FieldStructure(
                  new List<String>{ 'name' },
                  new Map<String, FieldStructure>{
                    'parentid' => new FieldStructure(
                      new List<String>{ 'name' },
                      new Map<String, FieldStructure>{
                        'parentid' => new FieldStructure(new List<String>{ 'name' })
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
          'ContractId' => new MockEntry(
            new Contract(Name = 'Test Contract'),
            new Map<String, Object>{
              'AccountId' => new MockEntry(
                new Account(Name = 'Test Account'),
                new Map<String, Object>{
                  'ParentId' => new MockEntry(
                    new Account(Name = 'Parent Account'),
                    new Map<String, Object>{
                      'ParentId' => new MockEntry(
                        new Account(
                          Name = 'Grandparent Account',
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
    IEntry contractEntry = orderEnrty.getParent('ContractId');
    IEntry accountEntry = contractEntry.getParent('AccountId');
    IEntry parentEntry = accountEntry.getParent('ParentId');
    IEntry grandparentEntry = parentEntry.getParent('ParentId');

    // Assert
    try {
      grandparentEntry.getId(); // This field is not selected in the Scribe query
      Assert.fail('Expected ApexEloquentException to be thrown for non-selected field in nested parent');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified field is not selected in Scribe'));
      Assert.isTrue(error.contains('[objectName => \'Account\']'));
      Assert.isTrue(error.contains('[fieldName => \'Id\']'));
    }
  }

  @isTest
  static void testGet_WhenEntryWithoutChildrenGetChildren_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Order.class).field('Id').field('Name').whereEqual('Id', '801000000000001');
    MockEntry accountEntry = new MockEntry(new Order(Id = '801000000000000001', Name = 'Test Account'));
    IEloquent eloquent = new MockEloquent(accountEntry);

    // Act & Assert
    List<IEntry> entries = eloquent.get(scribe);
    try {
      IEntry entry = entries[0];
      entry.getChildren('OrderItem'); // This child does not exist in the mock entry
      Assert.fail('Expected ApexEloquentException to be thrown for non-existing child');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified child Object Name `OrderItem` is not set in Scribe'));
      Assert.isTrue(error.contains('parent object name: Order'));
    }
  }

  @isTest
  static void testGet_WhenEntryWithChildrenGetNonSelectedField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .field('Name')
      .withChildren(Scribe.asChild(Contact.class).field('Id')) // 'Name' field is not selected
      .whereEqual('Id', '001000000000001');
    MockEntry accountEntry = MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .addChildren('Contact', MockEntry.of(Contact.class).autoId('{#}').set('Name', 'Test Contact {#}').times(2));
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
      Assert.fail('Expected ApexEloquentException to be thrown for non-selected field in child');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified field is not selected in Scribe'));
      Assert.isTrue(error.contains('[objectName => \'Contact\']'));
      Assert.isTrue(error.contains('[fieldName => \'Name\']'));
    }
  }

  @isTest
  static void testGet_WhenEntryWithNestedChildrenGetNonSelectedField_ThenThrowException() {
    // Arrange
    List<String> nameFields = new List<String>{ 'Name' };
    List<String> caseFields = new List<String>{ 'Subject' };
    Scribe scribe = Scribe.of(Account.class)
      .fields(nameFields)
      .withChildren(
        Scribe.asChild(Contact.class)
          .fields(nameFields)
          .withChildren(
            Scribe.asChild(Case.class)
              .fields(caseFields)
              .withChildren(
                Scribe.asChild(Case.class).fields(caseFields).withChildren(Scribe.asChild(Case.class).fields(caseFields))
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
              'Case' => new List<IEntry>{
                new MockEntry(
                  new Case(Subject = 'Test Case 1'),
                  new Map<String, Object>{
                    'Case' => new List<IEntry>{
                      new MockEntry(
                        new Case(Subject = 'Test Child Case 1'),
                        new Map<String, Object>{
                          'Case' => new List<IEntry>{ new MockEntry(new Case(Subject = 'Test Grandchild Case 1')) }
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
    List<IEntry> cases1 = contacts[0].getChildren('Case');
    List<IEntry> childCases1 = cases1[0].getChildren('Case');
    List<IEntry> grandchildCases1 = childCases1[0].getChildren('Case');

    // Assert
    try {
      for (IEntry grandchildCase : grandchildCases1) {
        grandchildCase.getId(); // This field is not selected in the Scribe query
        Assert.fail('Expected ApexEloquentException to be thrown for non-selected field in nested child');
      }
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified field is not selected in Scribe'));
      Assert.isTrue(error.contains('[objectName => \'Case\']'));
      Assert.isTrue(error.contains('[fieldName => \'Id\']'));
    }
  }

  @isTest
  static void testRepeat_WhenUsingWithoutFailONXxxMethod_ThenThrowException() {
    // Arrange
    MockEloquent mockEloquent = new MockEloquent();

    // Act & Assert
    try {
      mockEloquent.repeat();
      Assert.fail('Expected ApexEloquentException to be thrown when calling repeat() without failOnXxx()');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('No method call to repeat'));
    }
  }

  @isTest
  static void testGet_WhenSetFail_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnGet();

    // Act & Assert
    try {
      eloquent.get(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testGet_WhenSetFailAndGetTwice_ThenThrowExceptionOnlyFirstTime() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnGet();

    // Act & Assert
    try {
      eloquent.get(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown on first get');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }

    // Second call should not throw exception
    try {
      List<IEntry> entries = eloquent.get(scribe);
      Assert.isNotNull(entries, 'Expected entries to be returned on second get');
    } catch (ApexEloquentException e) {
      Assert.fail('Did not expect ApexEloquentException to be thrown on second get');
    }
  }

  @isTest
  static void testGet_WhenSetFailAndRepeat_ThenThrowExceptionEveryTime() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnGet().repeat();

    // Act & Assert
    for (Integer i = 0; i < 3; i++) {
      try {
        eloquent.get(scribe);
        Assert.fail('Expected ApexEloquentException to be thrown on get attempt ' + (i + 1));
      } catch (ApexEloquentException e) {
        String errorMessage = e.getMessage();
        Assert.isTrue(errorMessage.contains('get(Scribe scribe)'));
        Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
      }
    }
  }

  @isTest
  static void testGet_WhenSetFailTwiceAndGetTreeTimes_ThenThrowExceptionFirstTwoTimes() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnGet().failOnGet();

    // Act & Assert
    for (Integer i = 0; i < 3; i++) {
      try {
        eloquent.get(scribe);
        if (i < 2) {
          Assert.fail('Expected ApexEloquentException to be thrown on get attempt ' + (i + 1));
        } else {
          Assert.isNotNull(eloquent.get(scribe), 'Expected entries to be returned on third get');
        }
      } catch (ApexEloquentException e) {
        if (i < 2) {
          String errorMessage = e.getMessage();
          Assert.isTrue(errorMessage.contains('get(Scribe scribe)'));
          Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
        } else {
          Assert.fail('Did not expect ApexEloquentException to be thrown on third get');
        }
      }
    }
  }

  @isTest
  static void testGet_WhenSetQueryException_ThenThrowQueryException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    QueryException qe = new QueryException('Mocked query exception');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnGet(qe);

    // Act & Assert
    try {
      eloquent.get(scribe);
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      Assert.areEqual('Mocked query exception', e.getMessage(), 'Expected the mocked query exception message');
    }
  }

  @isTest
  static void testGet_WhenAggregateEntryExist_ThenReturnEntries() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    IEloquent eloquent = new MockEloquent(
      new List<IEntry>{
        MockEntry.asAggregateResult(new Map<String, Object>{ 'StageName' => 'Prospecting', 'avgAmount' => 5000 }),
        MockEntry.asAggregateResult(new Map<String, Object>{ 'StageName' => 'Closed Won', 'avgAmount' => 15000 })
      }
    );

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 2, 'Expected two aggregate entries to be returned');
    Assert.areEqual('Prospecting', entries[0].get('StageName'), 'Expected first entry StageName to match');
    Assert.areEqual(5000, entries[0].get('avgAmount'), 'Expected first entry avgAmount to match');
    Assert.areEqual('Closed Won', entries[1].get('StageName'), 'Expected second entry StageName to match');
    Assert.areEqual(15000, entries[1].get('avgAmount'), 'Expected second entry avgAmount to match');
  }

  @isTest
  static void testGet_WhenApplyAggregateScribeAndAccessNonSelectedField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    IEloquent eloquent = new MockEloquent(
      new List<IEntry>{
        MockEntry.asAggregateResult(new Map<String, Object>{ 'StageName' => 'Prospecting', 'avgAmount' => 5000 })
      }
    );

    // Act & Assert
    try {
      List<IEntry> entries = eloquent.get(scribe);
      IEntry entry = entries[0];
      entry.get('CloseDate'); // This field is not selected in the Scribe query
      Assert.fail('Expected ApexEloquentException to be thrown for non-selected field');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified field or alias is not exist in Scribe'));
    }
  }

  @isTest
  static void testGet_WhenApplyAggregateScribeAndAccessNonExistAlias_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    IEloquent eloquent = new MockEloquent(
      new List<IEntry>{
        MockEntry.asAggregateResult(new Map<String, Object>{ 'StageName' => 'Prospecting', 'avgAmount' => 5000 })
      }
    );

    // Act & Assert
    try {
      List<IEntry> entries = eloquent.get(scribe);
      IEntry entry = entries[0];
      entry.get('totalAmount'); // This alias does not exist in the Scribe query
      Assert.fail('Expected ApexEloquentException to be thrown for non-existing alias');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('The specified field or alias is not exist in Scribe'));
    }
  }

  @isTest
  static void testGet_WhenAddNestedAggregateScribe_ThenCanAccessFieldAndAliasAsFlatField() {
    // Arrange
    Scribe scribe = Scribe.of(OrderItem.class)
      .count('Id', 'itemCount')
      .parentField(
        Scribe.asParent('OrderId')
          .parentField(
            Scribe.asParent('OriginalOrderId')
              .parentField(
                Scribe.asParent('ContractId')
                  .parentField(
                    Scribe.asParent('AccountId')
                      .parentField(Scribe.asParent('ParentId').field('Type').count('Name', 'accountCount'))
                  )
              )
          )
      )
      .groupByParent(
        Scribe.asParent('OrderId')
          .groupByParent(
            Scribe.asParent('OriginalOrderId')
              .groupByParent(
                Scribe.asParent('ContractId')
                  .groupByParent(
                    Scribe.asParent('AccountId')
                      .groupByParent(Scribe.asParent('ParentId').groupByField('Type'))
                  )
              )
          )
      );
    IEloquent eloquent = new MockEloquent(
      MockEntry.asAggregateResult(new Map<String, Object>{ 'itemCount' => 10, 'accountCount' => 5, 'Type' => 'TestType1' })
    );

    // Act
    List<IEntry> entries = eloquent.get(scribe);

    // Assert
    Assert.isTrue(entries.size() == 1, 'Expected one aggregate entry to be returned');
    IEntry entry = entries[0];
    System.debug(entry);
    Assert.areEqual(10, entry.get('itemCount'), 'Expected itemCount to match');
    Assert.areEqual(5, entry.get('accountCount'), 'Expected accountCount to match');
    Assert.areEqual('TestType1', entry.get('Type'), 'Expected Type to match');
  }

  @isTest
  static void testGetAsSObject_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      eloquent.getAsSObject(null);
      Assert.fail('Expected ApexEloquentException to be thrown for null Scribe');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testGetAsSObject_WhenSetFail_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnGetAsSObject();

    // Act & Assert
    try {
      eloquent.getAsSObject(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testGetAsSObject_WhenSetQueryException_ThenThrowQueryException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    QueryException qe = new QueryException('Mocked query exception for getAsSObject');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnGetAsSObject(qe);

    // Act & Assert
    try {
      eloquent.getAsSObject(scribe);
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      Assert.areEqual(
        'Mocked query exception for getAsSObject',
        e.getMessage(),
        'Expected the mocked query exception message for getAsSObject'
      );
    }
  }

  @isTest
  static void testGetAsSObject_WhenEntriesExist_ThenReturnSObjects() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000001');
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
  static void testFirst_WhenApplyNull_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      eloquent.first(null);
      Assert.fail('Expected ApexEloquentException to be thrown for null Scribe');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('first(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testFirst_WhenSetFail_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnFirst();

    // Act & Assert
    try {
      eloquent.first(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('first(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testFirst_WhenSetQueryException_ThenThrowQueryException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    QueryException qe = new QueryException('Mocked query exception for first');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnFirst(qe);

    // Act & Assert
    try {
      eloquent.first(scribe);
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      Assert.areEqual(
        'Mocked query exception for first',
        e.getMessage(),
        'Expected the mocked query exception message for first'
      );
    }
  }

  @isTest
  static void testFirst_WhenEntryExists_ThenReturnFirstEntry() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
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
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act
    IEntry entry = eloquent.first(scribe);

    // Assert
    Assert.isNull(entry, 'Expected null when no entries exist');
  }

  @isTest
  static void testFirst_WhenFieldisNotSelected_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    try {
      IEntry entry = eloquent.first(scribe);
      entry.getName(); // This field is not selected in the Scribe query
      Assert.fail('Expected ApexEloquentException to be thrown for non-selected field');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The specified field is not selected in Scribe'));
      Assert.isTrue(e.getMessage().contains('[objectName => \'Opportunity\']'));
      Assert.isTrue(e.getMessage().contains('[fieldName => \'Name\']'));
    }
  }

  @isTest
  static void testFirstAsSObject_WhenApplyNull_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      eloquent.firstAsSObject(null);
      Assert.fail('Expected ApexEloquentException to be thrown for null Scribe');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testFirstAsSObject_WhenSetFail_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnFirstAsSObject();

    // Act & Assert
    try {
      eloquent.firstAsSObject(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testFirstAsSObject_WhenSetQueryException_ThenThrowQueryException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    QueryException qe = new QueryException('Mocked query exception for firstAsSObject');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnFirstAsSObject(qe);

    // Act & Assert
    try {
      eloquent.firstAsSObject(scribe);
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      Assert.areEqual(
        'Mocked query exception for firstAsSObject',
        e.getMessage(),
        'Expected the mocked query exception message for firstAsSObject'
      );
    }
  }

  @isTest
  static void testFirstAsSObject_WhenEntryExists_ThenReturnFirstEntry() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    Opportunity opp = (Opportunity) eloquent.firstAsSObject(scribe);

    // Assert
    Assert.isNotNull(opp, 'Expected first entry to be returned');
    Assert.areEqual('006000000000000001', opp.Id, 'Expected entry ID to match');
    Assert.areEqual('Test Opportunity', opp.Name, 'Expected entry Name to match');
  }

  @isTest
  static void testFirstAsSObject_WhenNoEntries_ThenReturnNull() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act
    Opportunity opp = (Opportunity) eloquent.firstAsSObject(scribe);

    // Assert
    Assert.isNull(opp, 'Expected null when no entries exist');
  }

  @isTest
  static void testFirstOrFail_WhenApplyNull_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      eloquent.firstOrFail(null);
      Assert.fail('Expected ApexEloquentException to be thrown for null Scribe');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstOrFail(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testFirstOrFail_WhenSetFail_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnFirstOrFail();

    // Act & Assert
    try {
      eloquent.firstOrFail(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstOrFail(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testFirstOrFail_WhenSetQueryException_ThenThrowQueryException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    QueryException qe = new QueryException('Mocked query exception for firstOrFail');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnFirstOrFail(qe);

    // Act & Assert
    try {
      eloquent.firstOrFail(scribe);
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      Assert.areEqual(
        'Mocked query exception for firstOrFail',
        e.getMessage(),
        'Expected the mocked query exception message for firstOrFail'
      );
    }
  }

  @isTest
  static void testFirstOrFail_WhenEntryExists_ThenReturnFirstEntry() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
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
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      IEntry entry = eloquent.firstOrFail(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown when no entries exist');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('No records were found'));
    }
  }

  @isTest
  static void testFirstOrFail_WhenFieldisNotSelected_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = new MockEntry(new Opportunity(Id = '006000000000000001', Name = 'Test Opportunity'));
    IEloquent eloquent = new MockEloquent(mockEntry);

    // Act
    try {
      IEntry entry = eloquent.first(scribe);
      entry.getName(); // This field is not selected in the Scribe query
      Assert.fail('Expected ApexEloquentException to be thrown for non-selected field');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The specified field is not selected in Scribe'));
      Assert.isTrue(e.getMessage().contains('[objectName => \'Opportunity\']'));
      Assert.isTrue(e.getMessage().contains('[fieldName => \'Name\']'));
    }
  }

  @isTest
  static void testFirstOrFailAsSObject_WhenApplyNull_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      eloquent.firstOrFailAsSObject(null);
      Assert.fail('Expected ApexEloquentException to be thrown for null Scribe');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstOrFailAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testFirstOrFailAsSObject_WhenSetFail_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnFirstOrFailAsSObject();

    // Act & Assert
    try {
      eloquent.firstOrFailAsSObject(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstOrFailAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testFirstOrFailAsSObject_WhenSetQueryException_ThenThrowQueryException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    QueryException qe = new QueryException('Mocked query exception for firstOrFailAsSObject');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnFirstOrFailAsSObject(qe);

    // Act & Assert
    try {
      eloquent.firstOrFailAsSObject(scribe);
      Assert.fail('Expected QueryException to be thrown');
    } catch (QueryException e) {
      Assert.areEqual(
        'Mocked query exception for firstOrFailAsSObject',
        e.getMessage(),
        'Expected the mocked query exception message for firstOrFailAsSObject'
      );
    }
  }

  @isTest
  static void testFirstOrFailAsSObject_WhenEntryExists_ThenReturnFirstEntry() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
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
  static void testFirstOrFailAsSObject_WhenNoEntries_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000001');
    IEloquent eloquent = new MockEloquent();

    // Act & Assert
    try {
      Opportunity opp = (Opportunity) eloquent.firstOrFailAsSObject(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown when no entries exist');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('No records were found'));
    }
  }

  @isTest
  static void testDoInsert_WhenApplyNullAsSObjct_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    Opportunity opp = null;

    // Act & Assert
    try {
      eloquent.doInsert(opp);
      Assert.fail('Expected ApexEloquentException to be thrown for null record');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doInsert(SObject record)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoInsert_WhenSetFail_ThenThrowException() {
    // Arrange
    Opportunity record = new Opportunity(Name = 'Test Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoInsert();

    // Act & Assert
    try {
      eloquent.doInsert(record);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doInsert(SObject record)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoInsert_WhenSetDmlException_ThenThrowDmlException() {
    // Arrange
    Opportunity record = new Opportunity(Name = 'Test Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    DmlException dmlException = new DmlException('Mocked DML exception for doInsert');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoInsert(dmlException);

    // Act & Assert
    try {
      eloquent.doInsert(record);
      Assert.fail('Expected DmlException to be thrown');
    } catch (DmlException e) {
      Assert.areEqual(
        'Mocked DML exception for doInsert',
        e.getMessage(),
        'Expected the mocked DML exception message for doInsert'
      );
    }
  }

  @isTest
  static void testDoInsert_WhenApplyNullAsListOfSObjct_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<Opportunity> opps = null;

    // Act & Assert
    try {
      eloquent.doInsert(opps);
      Assert.fail('Expected ApexEloquentException to be thrown for null record list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doInsert(List<SObject> records)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
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
  static void testDoUpdate_WhenApplyNullAsSObjct_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    Opportunity opp = null;

    // Act & Assert
    try {
      eloquent.doUpdate(opp);
      Assert.fail('Expected ApexEloquentException to be thrown for null record');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(SObject record)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenSetFail_ThenThrowException() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoUpdate();

    // Act & Assert
    try {
      eloquent.doUpdate(record);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(SObject record)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoUpdate_WhenSetDmlException_ThenThrowDmlException() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    DmlException dmlException = new DmlException('Mocked DML exception for doUpdate');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoUpdate(dmlException);

    // Act & Assert
    try {
      eloquent.doUpdate(record);
      Assert.fail('Expected DmlException to be thrown');
    } catch (DmlException e) {
      Assert.areEqual(
        'Mocked DML exception for doUpdate',
        e.getMessage(),
        'Expected the mocked DML exception message for doUpdate'
      );
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
  static void testDoUpdate_WhenAppluNullAsIEntry_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    MockEntry entry = null;

    // Act & Assert
    try {
      eloquent.doUpdate(entry);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(IEntry entry)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEntry_ThenReturnEntry() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .fields(new List<String>{ 'Id', 'Name' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class)
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
  static void testDoUpdate_WhenApplyNullAsListOfSObject_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<Opportunity> opps = null;

    // Act & Assert
    try {
      eloquent.doUpdate(opps);
      Assert.fail('Expected ApexEloquentException to be thrown for null record list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<SObject> records)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
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
  static void testDoUpdate_WhenApplyNullAsListOfIEntry_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<MockEntry> entries = null;

    // Act & Assert
    try {
      eloquent.doUpdate(entries);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<IEntry> entries)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenMultipleEntriesAreUpdated_ThenReturnEntries() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .fields(new List<String>{ 'Id', 'Name' })
      .buildFieldStructure();
    List<MockEntry> mockEntries = MockEntry.of(Opportunity.class)
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
  static void testDoUpsert_WhenAddNullRecord_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    SObject record = null;

    // Act & Assert
    try {
      eloquent.doUpsert(record);
      Assert.fail('Expected ApexEloquentException to be thrown for null record');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(SObject record)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsert_WhenAddNullInSObjectList_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<SObject> records = new List<SObject>{ new Opportunity(Name = 'Upserted Opportunity 1'), null };

    // Act & Assert
    try {
      eloquent.doUpsert(records);
      Assert.fail('Expected ApexEloquentException to be thrown for null record in list');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('doUpsert(List<SObject> records)'));
      Assert.isTrue(error.contains('Null record found in records list'));
    }
  }

  @isTest
  static void testDoUpsert_WhenSetFail_ThenThrowException() {
    // Arrange
    Opportunity record = new Opportunity(Name = 'Upserted Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoUpsert();

    // Act & Assert
    try {
      eloquent.doUpsert(record);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(SObject record)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoUpsert_WhenSetDmlException_ThenThrowDmlException() {
    // Arrange
    Opportunity record = new Opportunity(Name = 'Upserted Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    DmlException dmlException = new DmlException('Mocked DML exception for doUpsert');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoUpsert(dmlException);

    // Act & Assert
    try {
      eloquent.doUpsert(record);
      Assert.fail('Expected DmlException to be thrown');
    } catch (DmlException e) {
      Assert.areEqual(
        'Mocked DML exception for doUpsert',
        e.getMessage(),
        'Expected the mocked DML exception message for doUpsert'
      );
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
      Assert.fail('Expected ApexEloquentException to be thrown for null entry');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(IEntry entry)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsert_WhenAddNullInEntryList_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<IEntry> entries = new List<IEntry>{ MockEntry.of(Opportunity.class), null };

    // Act & Assert
    try {
      eloquent.doUpsert(entries);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry in list');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('doUpsert(List<IEntry> entries)'));
      Assert.isTrue(error.contains('Null entry found in entries list'));
    }
  }

  @isTest
  static void testDoUpsert_WhenAddEntry_ThenReturnUpsertedEntry() {
    // Arrange
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class);
    IEloquent eloquent = new MockEloquent();

    // Act
    IEntry upsertedEntry = eloquent.doUpsert(mockEntry);

    // Assert
    Assert.isNotNull(upsertedEntry.getId(), 'Expected entry to have an Id after upsert');
  }

  @isTest
  static void testDoUpsert_WhenAddNullListOfSObject_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<SObject> records = null;

    // Act & Assert
    try {
      eloquent.doUpsert(records);
      Assert.fail('Expected ApexEloquentException to be thrown for null record list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(List<SObject> records)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
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
  static void testDoUpsert_WhenAddNullListOfIEntry_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<IEntry> entries = null;

    // Act & Assert
    try {
      eloquent.doUpsert(entries);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(List<IEntry> entries)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsert_WhenAddMultiEntries_ThenReturnUpsertedEntries() {
    // Arrange
    List<MockEntry> mockEntries = new List<MockEntry>{
      MockEntry.of(Opportunity.class),
      MockEntry.of(Opportunity.class).autoId(1)
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
  static void testDoDelete_WhenApplyNullAsSObjct_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    Opportunity opp = null;

    // Act & Assert
    try {
      eloquent.doDelete(opp);
      Assert.fail('Expected ApexEloquentException to be thrown for null record');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(SObject record)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoDelete_WhenSetFail_ThenThrowException() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Test Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoDelete();

    // Act & Assert
    try {
      eloquent.doDelete(record);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(SObject record)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoDelete_WhenSetDmlException_ThenThrowDmlException() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Test Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    DmlException dmlException = new DmlException('Mocked DML exception for doDelete');
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoDelete(dmlException);

    // Act & Assert
    try {
      eloquent.doDelete(record);
      Assert.fail('Expected DmlException to be thrown');
    } catch (DmlException e) {
      Assert.areEqual(
        'Mocked DML exception for doDelete',
        e.getMessage(),
        'Expected the mocked DML exception message for doDelete'
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
  static void testDoDelete_WhenApplyNullAsIEntry_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    MockEntry entry = null;

    // Act & Assert
    try {
      eloquent.doDelete(entry);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(IEntry entry)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoDelete_WhenEntryIsDeleted_ThenNoExceptionThrown() {
    // Arrange
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class).autoId(1).add('Name', 'Opportunity 1');
    IEloquent eloquent = new MockEloquent();

    // Act
    eloquent.doDelete(mockEntry);

    // Assert
    // No exception should be thrown, indicating successful deletion
  }

  @isTest
  static void testDoDelete_WhenApplyNullAsListOfSObjct_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<Opportunity> opps = null;

    // Act & Assert
    try {
      eloquent.doDelete(opps);
      Assert.fail('Expected ApexEloquentException to be thrown for null record list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(List<SObject> records)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
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
  static void testDoDelete_WhenApplyNullAsListOfIEntry_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<MockEntry> entries = null;

    // Act & Assert
    try {
      eloquent.doDelete(entries);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(List<IEntry> entries)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoDelete_WhenMultipleEntriesAreDeleted_ThenNoExceptionThrown() {
    // Arrange
    List<MockEntry> mockEntries = MockEntry.of(Opportunity.class)
      .autoId('{#}')
      .add('Name', 'Opportunity {#}')
      .times(2);
    IEloquent eloquent = new MockEloquent();

    // Act
    eloquent.doDelete(mockEntries);

    // Assert
    // No exception should be thrown, indicating successful deletion
  }
}
