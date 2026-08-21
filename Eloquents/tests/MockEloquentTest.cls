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
 * @directory ApexEloquent/Eloquents/tests
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
  static void testGet_WhenEntryWithNestedParentGetId_ThenReturnIdWithoutScribeDeclaration() {
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
    // Real SOQL returns the Id of a traversed parent even when it is not listed in
    // the SELECT clause, so the mock must not require a Scribe declaration for it.
    Assert.areEqual(
      '001000000000000001',
      grandparentEntry.getId(),
      'Id of a nested parent should be readable without a Scribe declaration.'
    );
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
  static void testGet_WhenEntryWithNestedChildrenGetId_ThenReadableWithoutScribeDeclaration() {
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
    // Real SOQL returns the Id of subquery rows even when it is not listed in the
    // SELECT clause, so reading Id must not require a Scribe declaration. The mock
    // data sets no Id, so null comes back instead of an exception.
    for (IEntry grandchildCase : grandchildCases1) {
      Assert.isNull(grandchildCase.getId(), 'Id must be readable without a Scribe declaration.');
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
  static void testDoUpdate_WhenApplyNullAsSObjectWithAllOrNone_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    Opportunity opp = null;

    // Act & Assert
    try {
      eloquent.doUpdate(opp, true);
      Assert.fail('Expected ApexEloquentException to be thrown for null record');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(SObject record, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplySObjectWithAllOrNone_ThenReturnSuccessSaveResult() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity');
    IEloquent eloquent = new MockEloquent();

    // Act
    Database.SaveResult saveResult = eloquent.doUpdate(record, false);

    // Assert
    Assert.isTrue(saveResult.isSuccess(), 'Expected SaveResult to be success');
    Assert.areEqual('006000000000001', saveResult.getId(), 'Expected SaveResult Id to match record Id');
  }

  @isTest
  static void testDoUpdate_WhenSObjectWithAllOrNoneAndSetFail_ThenThrowException() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity');
    IEloquent eloquent = (new MockEloquent()).failOnDoUpdate();

    // Act & Assert
    try {
      eloquent.doUpdate(record, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(SObject record, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullAsIEntryWithAllOrNone_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    MockEntry entry = null;

    // Act & Assert
    try {
      eloquent.doUpdate(entry, true);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(IEntry entry, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEntryWithAllOrNone_ThenReturnSuccessSaveResult() {
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
    Database.SaveResult saveResult = eloquent.doUpdate(mockEntry, false);

    // Assert
    Assert.isTrue(saveResult.isSuccess(), 'Expected SaveResult to be success');
    Assert.areEqual(mockEntry.getId(), saveResult.getId(), 'Expected SaveResult Id to match entry Id');
  }

  @isTest
  static void testDoUpdate_WhenIEntryWithAllOrNoneAndSetFail_ThenThrowException() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity');
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoUpdate();

    // Act & Assert
    try {
      eloquent.doUpdate(mockEntry, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(IEntry entry, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullAsListOfSObjectWithAllOrNone_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<Opportunity> opps = null;

    // Act & Assert
    try {
      eloquent.doUpdate(opps, true);
      Assert.fail('Expected ApexEloquentException to be thrown for null record list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<SObject> records, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyListOfSObjectWithAllOrNone_ThenReturnSuccessSaveResults() {
    // Arrange
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity 1'),
      new Opportunity(Id = '006000000000002', Name = 'Updated Opportunity 2')
    };
    IEloquent eloquent = new MockEloquent();

    // Act
    List<Database.SaveResult> saveResults = eloquent.doUpdate(records, false);

    // Assert
    Assert.areEqual(2, saveResults.size(), 'Expected two SaveResults');
    for (Database.SaveResult sr : saveResults) {
      Assert.isTrue(sr.isSuccess(), 'Expected each SaveResult to be success');
    }
  }

  @isTest
  static void testDoUpdate_WhenListOfSObjectWithAllOrNoneAndSetFail_ThenThrowException() {
    // Arrange
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Id = '006000000000001', Name = 'Updated Opportunity 1')
    };
    IEloquent eloquent = (new MockEloquent()).failOnDoUpdate();

    // Act & Assert
    try {
      eloquent.doUpdate(records, false);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<SObject> records, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullAsListOfIEntryWithAllOrNone_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<MockEntry> entries = null;

    // Act & Assert
    try {
      eloquent.doUpdate(entries, true);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<IEntry> entries, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyListOfIEntryWithAllOrNone_ThenReturnSuccessSaveResults() {
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
    List<Database.SaveResult> saveResults = eloquent.doUpdate(updateEntries, false);

    // Assert
    Assert.areEqual(2, saveResults.size(), 'Expected two SaveResults');
    for (Database.SaveResult sr : saveResults) {
      Assert.isTrue(sr.isSuccess(), 'Expected each SaveResult to be success');
    }
  }

  @isTest
  static void testDoUpdate_WhenListOfIEntryWithAllOrNoneAndSetFail_ThenThrowException() {
    // Arrange
    List<MockEntry> entries = new List<MockEntry>{ MockEntry.of(Opportunity.class).autoId(1) };
    IEloquent eloquent = (new MockEloquent()).failOnDoUpdate();

    // Act & Assert
    try {
      eloquent.doUpdate(entries, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<IEntry> entries, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
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
  static void testDoUpsert_WhenAddEntryWithoutId_ThenInputEntryNotMutated() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = new MockEloquent();

    // Act
    IEntry upsertedEntry = eloquent.doUpsert(mockEntry);

    // Assert
    // Mirror Eloquent: Database.upsert writes the Id back to the internal clone, so
    // the caller's entry stays untouched and the Id is carried by the returned Entry.
    Assert.isNull(mockEntry.getId(), 'Input entry must not be mutated by the mock.');
    Assert.isNotNull(upsertedEntry.getId(), 'Returned entry must carry the generated Id.');
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
  static void testDoUpsert_WhenAddEntriesWithoutId_ThenReturnNewEntriesAndInputNotMutated() {
    // Arrange
    List<MockEntry> mockEntries = new List<MockEntry>{
      MockEntry.of(Opportunity.class),
      MockEntry.of(Opportunity.class)
    };
    IEloquent eloquent = new MockEloquent();

    // Act
    List<IEntry> upsertedEntries = eloquent.doUpsert(mockEntries);

    // Assert
    // Mirror Eloquent: fresh Entry instances carry the Ids; the caller's entries stay untouched.
    for (Integer i = 0; i < mockEntries.size(); i++) {
      Assert.isNull(mockEntries[i].getId(), 'Input entries must not be mutated by the mock.');
      Assert.isNotNull(upsertedEntries[i].getId(), 'Returned entries must carry the generated Ids.');
    }
    Assert.areNotEqual(
      upsertedEntries[0].getId(),
      upsertedEntries[1].getId(),
      'Each created record must receive a distinct Id.'
    );
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyNullAsSObject_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    Opportunity opp = null;

    // Act & Assert
    try {
      eloquent.doUpsertByExternalId(opp, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown for null record');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(SObject record, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenSObjectWithoutId_ThenReturnCreatedUpsertResult() {
    // Arrange
    Opportunity record = new Opportunity(Name = 'New Opportunity');
    IEloquent eloquent = new MockEloquent();

    // Act
    Database.UpsertResult result = eloquent.doUpsertByExternalId(record, Opportunity.Id, false);

    // Assert
    Assert.isTrue(result.isSuccess(), 'Expected UpsertResult to be success');
    Assert.isTrue(result.isCreated(), 'Expected isCreated to be true for record without Id');
    Assert.isNotNull(result.getId(), 'Expected UpsertResult to have an Id');
  }

  @isTest
  static void testDoUpsertByExternalId_WhenSObjectWithExistingId_ThenReturnUpdatedUpsertResult() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Existing Opportunity');
    IEloquent eloquent = new MockEloquent();

    // Act
    Database.UpsertResult result = eloquent.doUpsertByExternalId(record, Opportunity.Id, false);

    // Assert
    Assert.isTrue(result.isSuccess(), 'Expected UpsertResult to be success');
    Assert.isFalse(result.isCreated(), 'Expected isCreated to be false for record with existing Id');
    Assert.areEqual('006000000000001', result.getId(), 'Expected UpsertResult Id to match record Id');
  }

  @isTest
  static void testDoUpsertByExternalId_WhenSObjectAndSetFail_ThenThrowException() {
    // Arrange
    Opportunity record = new Opportunity(Id = '006000000000001', Name = 'Upserted Opportunity');
    IEloquent eloquent = (new MockEloquent()).failOnDoUpsertByExternalId();

    // Act & Assert
    try {
      eloquent.doUpsertByExternalId(record, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(SObject record, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyNullAsIEntry_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    MockEntry entry = null;

    // Act & Assert
    try {
      eloquent.doUpsertByExternalId(entry, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(IEntry entry, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyEntry_ThenReturnSuccessUpsertResult() {
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
    Database.UpsertResult result = eloquent.doUpsertByExternalId(mockEntry, Opportunity.Id, false);

    // Assert
    Assert.isTrue(result.isSuccess(), 'Expected UpsertResult to be success');
    Assert.isFalse(result.isCreated(), 'Expected isCreated to be false for entry with auto Id');
    Assert.areEqual(mockEntry.getId(), result.getId(), 'Expected UpsertResult Id to match entry Id');
  }

  @isTest
  static void testDoUpsertByExternalId_WhenIEntryAndSetFail_ThenThrowException() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = (new MockEloquent(mockEntry)).failOnDoUpsertByExternalId();

    // Act & Assert
    try {
      eloquent.doUpsertByExternalId(mockEntry, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(IEntry entry, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyNullAsListOfSObject_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<Opportunity> opps = null;

    // Act & Assert
    try {
      eloquent.doUpsertByExternalId(opps, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown for null record list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyListOfSObject_ThenReturnSuccessUpsertResults() {
    // Arrange
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Name = 'New Opportunity 1'),
      new Opportunity(Id = '006000000000002', Name = 'Existing Opportunity 2')
    };
    IEloquent eloquent = new MockEloquent();

    // Act
    List<Database.UpsertResult> results = eloquent.doUpsertByExternalId(records, Opportunity.Id, false);

    // Assert
    Assert.areEqual(2, results.size(), 'Expected two UpsertResults');
    Assert.isTrue(results[0].isSuccess(), 'Expected first UpsertResult to be success');
    Assert.isTrue(results[0].isCreated(), 'Expected first isCreated to be true (no Id)');
    Assert.isTrue(results[1].isSuccess(), 'Expected second UpsertResult to be success');
    Assert.isFalse(results[1].isCreated(), 'Expected second isCreated to be false (Id provided)');
  }

  @isTest
  static void testDoUpsertByExternalId_WhenListOfSObjectAndSetFail_ThenThrowException() {
    // Arrange
    List<Opportunity> records = new List<Opportunity>{
      new Opportunity(Id = '006000000000001', Name = 'Upserted Opportunity 1')
    };
    IEloquent eloquent = (new MockEloquent()).failOnDoUpsertByExternalId();

    // Act & Assert
    try {
      eloquent.doUpsertByExternalId(records, Opportunity.Id, false);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyNullAsListOfIEntry_ThenThrowException() {
    // Arrange
    IEloquent eloquent = new MockEloquent();
    List<MockEntry> entries = null;

    // Act & Assert
    try {
      eloquent.doUpsertByExternalId(entries, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown for null entry list');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(List<IEntry> entries, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyListOfIEntry_ThenReturnSuccessUpsertResults() {
    // Arrange
    List<MockEntry> mockEntries = new List<MockEntry>{
      MockEntry.of(Opportunity.class),
      MockEntry.of(Opportunity.class).autoId(1)
    };
    IEloquent eloquent = new MockEloquent();

    // Act
    List<Database.UpsertResult> results = eloquent.doUpsertByExternalId(mockEntries, Opportunity.Id, false);

    // Assert
    Assert.areEqual(2, results.size(), 'Expected two UpsertResults');
    Assert.isTrue(results[0].isSuccess(), 'Expected first UpsertResult to be success');
    Assert.isTrue(results[0].isCreated(), 'Expected first isCreated to be true (no Id)');
    Assert.isTrue(results[1].isSuccess(), 'Expected second UpsertResult to be success');
    Assert.isFalse(results[1].isCreated(), 'Expected second isCreated to be false (auto Id assigned)');
  }

  @isTest
  static void testDoUpsertByExternalId_WhenEntryWithoutId_ThenResultCarriesIdAndEntryNotMutated() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Opportunity.class);
    IEloquent eloquent = new MockEloquent();

    // Act
    Database.UpsertResult result = eloquent.doUpsertByExternalId(mockEntry, Opportunity.Id, false);

    // Assert
    // Mirror Eloquent: Database.upsert reports the Id through the UpsertResult and
    // never writes it back into the caller's entry (it lands on the internal clone).
    Assert.isTrue(result.isCreated(), 'Expected isCreated to be true for entry without Id');
    Assert.isNotNull(result.getId(), 'UpsertResult must carry the generated Id.');
    Assert.isNull(mockEntry.getId(), 'Input entry must not be mutated by the mock.');
  }

  @isTest
  static void testDoUpsertByExternalId_WhenEntriesWithoutId_ThenResultsAndRecordsCarryIds() {
    // Arrange
    List<MockEntry> mockEntries = new List<MockEntry>{
      MockEntry.of(Opportunity.class),
      MockEntry.of(Opportunity.class)
    };
    MockEloquent eloquent = new MockEloquent();

    // Act
    List<Database.UpsertResult> results = eloquent.label('upsert')
      .doUpsertByExternalId(mockEntries, Opportunity.Id, false);

    // Assert
    for (Database.UpsertResult result : results) {
      Assert.isNotNull(result.getId(), 'Each UpsertResult must carry the generated Id.');
    }
    for (MockEntry mockEntry : mockEntries) {
      Assert.isNull(mockEntry.getId(), 'Input entries must not be mutated by the mock.');
    }
    for (SObject recorded : eloquent.upsertedRecordsAt('upsert')) {
      Assert.isNotNull(recorded.Id, 'Recorded records must carry the generated Ids.');
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenListOfIEntryAndSetFail_ThenThrowException() {
    // Arrange
    List<MockEntry> entries = new List<MockEntry>{ MockEntry.of(Opportunity.class).autoId(1) };
    IEloquent eloquent = (new MockEloquent()).failOnDoUpsertByExternalId();

    // Act & Assert
    try {
      eloquent.doUpsertByExternalId(entries, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(List<IEntry> entries, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('MockEloquent was configured to throw this exception'));
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

  // ===========================================================================
  // label() / attach() / upsertedRecordsAt() / deletedCountAt() / whenLabel() (issue_42)
  // ===========================================================================

  // --- A. label() / attach() basics ----------------------------------------

  @isTest
  static void testLabel_WhenChained_ThenReturnSelf() {
    MockEloquent mock = new MockEloquent();
    IEloquent result = mock.label('foo');
    Assert.areEqual(mock, result, 'label() should return the same instance for chaining.');
  }

  @isTest
  static void testLabel_WhenNull_ThenThrowException() {
    try {
      (new MockEloquent()).label(null);
      Assert.fail('Expected ApexEloquentException for null label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('label(String label)'));
    }
  }

  @isTest
  static void testLabel_WhenBlank_ThenThrowException() {
    try {
      (new MockEloquent()).label(' ');
      Assert.fail('Expected ApexEloquentException for blank label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('label(String label)'));
    }
  }

  @isTest
  static void testAttach_WhenChained_ThenReturnCopyCarryingAttachment() {
    // Since issue #63, attach() returns a new instance (builder immutability);
    // the returned copy carries the attachment, the receiver stays untouched
    MockEloquent mock = new MockEloquent();
    MockEloquent result = mock.attach('foo', new List<IEntry>());
    Assert.areNotEqual(mock, result, 'attach() must return a copy, not the receiver');
    Assert.areEqual(0, result.label('foo').get(Scribe.of(Account.class).field('Id')).size());
  }

  @isTest
  static void testAttach_WhenSameLabelTwice_ThenOverwrite() {
    MockEntry first = MockEntry.of(Account.class).autoId(1).set('Name', 'First');
    MockEntry second = MockEntry.of(Account.class).autoId(2).set('Name', 'Second');
    MockEloquent mock = (new MockEloquent())
      .attach('opp', new List<IEntry>{ first })
      .attach('opp', new List<IEntry>{ second }); // overwrites

    Scribe scribe = Scribe.of(Account.class).field('Name');
    List<IEntry> result = mock.label('opp').get(scribe);

    Assert.areEqual(1, result.size(), 'Second attach should have replaced first.');
    Assert.areEqual('Second', result[0].get('Name'));
  }

  @isTest
  static void testAttach_WhenSingleEntryOverload_ThenWrapsAsList() {
    MockEntry entry = MockEntry.of(Account.class).autoId(1).set('Name', 'Acme');
    MockEloquent mock = (new MockEloquent()).attach('opp', entry);
    Scribe scribe = Scribe.of(Account.class).field('Name');
    List<IEntry> result = mock.label('opp').get(scribe);
    Assert.areEqual(1, result.size());
    Assert.areEqual('Acme', result[0].get('Name'));
  }

  @isTest
  static void testAttach_WhenNullEntries_ThenStoreEmptyList() {
    MockEloquent mock = (new MockEloquent()).attach('opp', (List<IEntry>) null);
    Scribe scribe = Scribe.of(Account.class).field('Name');
    List<IEntry> result = mock.label('opp').get(scribe);
    Assert.areEqual(0, result.size());
  }

  // --- B. query label routing ----------------------------------------------

  @isTest
  static void testGet_WhenAttachedAndLabelMatch_ThenReturnAttachedData() {
    MockEntry entry = MockEntry.of(Account.class).autoId(1).set('Name', 'A');
    MockEloquent mock = (new MockEloquent()).attach('opp', new List<IEntry>{ entry });
    Scribe scribe = Scribe.of(Account.class).field('Name');
    List<IEntry> result = mock.label('opp').get(scribe);
    Assert.areEqual(1, result.size());
    Assert.areEqual('A', result[0].get('Name'));
  }

  @isTest
  static void testGet_WhenAttachedButNoLabelCalled_ThenReturnLegacyDefaultEntries() {
    // Legacy: MockEloquent(List<IEntry>) populates 'default' source via entries field
    MockEntry legacy = MockEntry.of(Account.class).autoId(1).set('Name', 'LegacyDefault');
    MockEntry attached = MockEntry.of(Account.class).autoId(2).set('Name', 'AttachedOpp');
    MockEloquent mock = (new MockEloquent(new List<IEntry>{ legacy }))
      .attach('opp', new List<IEntry>{ attached });

    Scribe scribe = Scribe.of(Account.class).field('Name');
    // no label() -> default -> falls back to legacy entries
    List<IEntry> result = mock.get(scribe);
    Assert.areEqual(1, result.size());
    Assert.areEqual('LegacyDefault', result[0].get('Name'));
  }

  @isTest
  static void testGet_WhenLabelCalledButNoAttach_ThenThrows() {
    MockEntry legacy = MockEntry.of(Account.class).autoId(1).set('Name', 'LegacyDefault');
    MockEloquent mock = new MockEloquent(new List<IEntry>{ legacy });
    Scribe scribe = Scribe.of(Account.class).field('Name');
    // label('opp') has no attach — no legacy fallback, and in test context this is
    // treated as a test-setup bug (forgotten attach) instead of a silent empty list
    try {
      mock.label('opp').get(scribe);
      Assert.fail('Expected ApexEloquentException for unattached label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('has no attached entries'), e.getMessage());
    }
  }

  @isTest
  static void testFirst_WhenAttachedAndLabelMatch_ThenReturnFirstEntry() {
    MockEntry e1 = MockEntry.of(Account.class).autoId(1).set('Name', 'First');
    MockEntry e2 = MockEntry.of(Account.class).autoId(2).set('Name', 'Second');
    MockEloquent mock = (new MockEloquent()).attach('opp', new List<IEntry>{ e1, e2 });
    Scribe scribe = Scribe.of(Account.class).field('Name');
    IEntry result = mock.label('opp').first(scribe);
    Assert.areEqual('First', result.get('Name'));
  }

  @isTest
  static void testFirstOrFail_WhenLabelEmpty_ThenThrowException() {
    // The zero-row path is declared explicitly with an attached empty list
    MockEloquent mock = (new MockEloquent()).attach('opp', new List<IEntry>());
    Scribe scribe = Scribe.of(Account.class).field('Name');
    try {
      mock.label('opp').firstOrFail(scribe);
      Assert.fail('Expected ApexEloquentException for empty label preload.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('No records were found'));
    }
  }

  @isTest
  static void testGet_WhenTwoConsecutiveLabels_ThenEachRoutesIndependently() {
    MockEntry oppData = MockEntry.of(Account.class).autoId(1).set('Name', 'OppAcc');
    MockEntry quoteData = MockEntry.of(Account.class).autoId(2).set('Name', 'QuoteAcc');
    MockEloquent mock = (new MockEloquent())
      .attach('opp', new List<IEntry>{ oppData })
      .attach('quote', new List<IEntry>{ quoteData });
    Scribe scribe = Scribe.of(Account.class).field('Name');

    IEntry oppResult = mock.label('opp').first(scribe);
    IEntry quoteResult = mock.label('quote').first(scribe);

    Assert.areEqual('OppAcc', oppResult.get('Name'));
    Assert.areEqual('QuoteAcc', quoteResult.get('Name'));
  }

  // (testGet_WhenLabelResetsAfterOneOp_ThenSecondOpUsesDefault was removed
  // in issue_39: strict mode forbids label-less ops after the first .label(),
  // and the new behavior is covered by testStrict_AfterLabelCall_NoLabelOpThrows
  // at the bottom of this file.)

  // --- C. DML per-label accumulators ---------------------------------------

  @isTest
  static void testDoInsert_WhenWithLabel_ThenStoreInLabelBucket() {
    MockEloquent mock = new MockEloquent();
    Account a = new Account(Name = 'Inserted');
    mock.label('acc').doInsert(a);

    Assert.areEqual(1, mock.upsertedRecordsAt('acc').size());
    Assert.areEqual(0, mock.upsertedRecords.size(), 'Default bucket should be empty.');
  }

  @isTest
  static void testDoInsert_WhenWithoutLabel_ThenStoreInDefaultBucket() {
    MockEloquent mock = new MockEloquent();
    mock.doInsert(new Account(Name = 'Inserted'));

    Assert.areEqual(1, mock.upsertedRecords.size(), 'Legacy field reflects default bucket.');
    Assert.areEqual(1, mock.upsertedRecordsAt('default').size());
    Assert.areEqual(0, mock.upsertedRecordsAt('acc').size());
  }

  @isTest
  static void testDoUpdate_WhenWithLabel_ThenStoreInLabelBucket() {
    MockEloquent mock = new MockEloquent();
    mock.label('quoteUpdate').doUpdate(new Account(Id = '001000000000001', Name = 'Updated'));
    Assert.areEqual(1, mock.upsertedRecordsAt('quoteUpdate').size());
    Assert.areEqual(0, mock.upsertedRecords.size());
  }

  @isTest
  static void testDoUpsert_WhenWithLabel_ThenStoreInLabelBucket() {
    MockEloquent mock = new MockEloquent();
    mock.label('oppUpsert').doUpsert(new Account(Id = '001000000000001', Name = 'Upserted'));
    Assert.areEqual(1, mock.upsertedRecordsAt('oppUpsert').size());
  }

  @isTest
  static void testDoUpsertByExternalId_WhenWithLabel_ThenStoreInLabelBucket() {
    MockEloquent mock = new MockEloquent();
    mock.label('extId').doUpsertByExternalId(new Account(Name = 'Acme'), Account.Id, false);
    Assert.areEqual(1, mock.upsertedRecordsAt('extId').size());
  }

  @isTest
  static void testDoDelete_WhenWithLabel_ThenIncrementLabelDeletedCount() {
    MockEloquent mock = new MockEloquent();
    mock.label('cleanup').doDelete(new Account(Id = '001000000000001'));
    Assert.areEqual(1, mock.deletedCountAt('cleanup'));
    Assert.areEqual(0, mock.deletedCount, 'Default bucket should be empty.');
  }

  @isTest
  static void testDoDelete_WhenWithoutLabel_ThenIncrementDefaultBucket() {
    MockEloquent mock = new MockEloquent();
    mock.doDelete(new Account(Id = '001000000000001'));
    Assert.areEqual(1, mock.deletedCount);
    Assert.areEqual(1, mock.deletedCountAt('default'));
    Assert.areEqual(0, mock.deletedCountAt('other'));
  }

  @isTest
  static void testUpsertedRecordsAt_WhenUnknownLabel_ThenReturnEmptyList() {
    MockEloquent mock = new MockEloquent();
    Assert.areEqual(0, mock.upsertedRecordsAt('neverUsed').size());
  }

  @isTest
  static void testDeletedCountAt_WhenUnknownLabel_ThenReturnZero() {
    MockEloquent mock = new MockEloquent();
    Assert.areEqual(0, mock.deletedCountAt('neverUsed'));
  }

  // --- E. whenLabel (scoped failures) --------------------------------------

  @isTest
  static void testWhenLabel_WhenCalledWithoutPriorFailOnXxx_ThenThrowException() {
    try {
      (new MockEloquent()).whenLabel('opp');
      Assert.fail('Expected ApexEloquentException — whenLabel needs preceding failOnXxx.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('whenLabel(String label)'));
      Assert.isTrue(e.getMessage().contains('No failOnXxx to scope'));
    }
  }

  @isTest
  static void testFailOnGet_WithWhenLabel_AndLabelMatches_ThenFire() {
    MockEloquent mock = (new MockEloquent()).failOnGet().whenLabel('opp');
    Scribe scribe = Scribe.of(Account.class).field('Name');
    try {
      mock.label('opp').get(scribe);
      Assert.fail('Expected failOnGet to fire for matching label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('MockEloquent was configured to throw'));
    }
  }

  @isTest
  static void testFailOnGet_WithWhenLabel_AndLabelMismatch_ThenDoNotFire() {
    MockEloquent mock = (new MockEloquent())
      .attach('quote', new List<IEntry>())
      .failOnGet()
      .whenLabel('opp');
    Scribe scribe = Scribe.of(Account.class).field('Name');
    // Calling with a different label should NOT fire the failure
    List<IEntry> result = mock.label('quote').get(scribe);
    Assert.areEqual(0, result.size(), 'No failure should fire; quote is attached empty.');
  }

  @isTest
  static void testFailOnDoUpdate_WithWhenLabel_AndLabelMatches_ThenFire() {
    MockEloquent mock = (new MockEloquent()).failOnDoUpdate().whenLabel('finalDml');
    try {
      mock.label('finalDml').doUpdate(new Account(Id = '001000000000001', Name = 'X'));
      Assert.fail('Expected failOnDoUpdate to fire for matching label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('MockEloquent was configured to throw'));
    }
  }

  @isTest
  static void testFailOnXxx_WithoutWhenLabel_WhenLenientCall_ThenFires() {
    MockEloquent mock = (new MockEloquent()).failOnGet();
    Scribe scribe = Scribe.of(Account.class).field('Name');
    try {
      mock.get(scribe);
      Assert.fail('Label-free failOnGet must fire for a label-free (default) call.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('MockEloquent was configured to throw'));
    }
  }

  @isTest
  static void testFailOnXxx_WithoutWhenLabel_WhenStrictCall_ThenThrowsUnreachableConfig() {
    // strict mode never runs under 'default', so a label-free failOnGet can
    // never fire — the mock diagnoses the dead config instead of staying silent
    MockEloquent mock = (new MockEloquent()).failOnGet();
    Scribe scribe = Scribe.of(Account.class).field('Name');
    try {
      mock.label('anyLabel').get(scribe);
      Assert.fail('Expected unreachable-config diagnostic.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('unreachable config'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('anyLabel'), 'Diagnostic should suggest the call label.');
    }
  }

  @isTest
  static void testWhenLabel_WhenNullOrBlank_ThenThrowRequired() {
    try {
      (new MockEloquent()).failOnGet().whenLabel(null);
      Assert.fail('Expected required-argument exception for null label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The `label` argument is required'), e.getMessage());
    }
    try {
      (new MockEloquent()).failOnGet().whenLabel(' ');
      Assert.fail('Expected required-argument exception for blank label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The `label` argument is required'), e.getMessage());
    }
  }

  @isTest
  static void testWhenLabel_WhenDefaultLabel_ThenThrowInvalidOperation() {
    // registering without whenLabel(...) already targets 'default' — naming it is redundant
    try {
      (new MockEloquent()).failOnGet().whenLabel('default');
      Assert.fail('Expected invalid-operation exception for the reserved default label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('redundant'), e.getMessage());
    }
  }

  @isTest
  static void testFailOn_WhenTwoLabeledConfigsOnSameMethod_ThenEachFiresForItsLabel() {
    // no head-of-line blocking: even with the 'X' config at the queue head,
    // a 'Y' call must reach the 'Y' config
    MockEloquent mock = (new MockEloquent())
      .failOnGet(new QueryException('for X'))
      .whenLabel('X')
      .failOnGet(new QueryException('for Y'))
      .whenLabel('Y');
    Scribe scribe = Scribe.of(Account.class).field('Name');

    try {
      mock.label('Y').get(scribe);
      Assert.fail('Y-scoped failure must fire.');
    } catch (QueryException e) {
      Assert.areEqual('for Y', e.getMessage());
    }

    try {
      mock.label('X').get(scribe);
      Assert.fail('X-scoped failure must fire.');
    } catch (QueryException e) {
      Assert.areEqual('for X', e.getMessage());
    }
  }

  @isTest
  static void testFailOn_WhenLabelMismatch_ThenConfigSurvivesForLaterMatch() {
    MockEloquent mock = (new MockEloquent())
      .attach('quote', new List<IEntry>())
      .failOnGet(new QueryException('boom'))
      .whenLabel('opp');
    Scribe scribe = Scribe.of(Account.class).field('Name');

    // mismatch — must not fire, must not be consumed
    Assert.areEqual(0, mock.label('quote').get(scribe).size());

    try {
      mock.label('opp').get(scribe);
      Assert.fail('The surviving config must fire for its label.');
    } catch (QueryException e) {
      Assert.areEqual('boom', e.getMessage());
    }
  }

  // ===========================================================================
  // Error-injection semantics (issues #62 / #64): failures form a FIFO queue
  // per label ('default' = label-free calls). A failed operation releases its
  // label — consume-once guards one SUCCESSFUL operation per label — so the
  // labeled scenarios below retry under the same label.
  // ===========================================================================

  @isTest
  static void testScenario_TwoDefaultConfigs_ThenFifoThenSuccess() {
    // 1回目A、2回目B、3回目成功
    MockEloquent mock = (new MockEloquent())
      .failOnGet(new QueryException('A'))
      .failOnGet(new QueryException('B'));
    Scribe scribe = Scribe.of(Account.class).field('Name');

    try {
      mock.get(scribe);
      Assert.fail('1st call must fail with A.');
    } catch (QueryException e) {
      Assert.areEqual('A', e.getMessage());
    }
    try {
      mock.get(scribe);
      Assert.fail('2nd call must fail with B.');
    } catch (QueryException e) {
      Assert.areEqual('B', e.getMessage());
    }
    Assert.areEqual(0, mock.get(scribe).size(), '3rd call succeeds.');
  }

  @isTest
  static void testScenario_DefaultRepeat_ThenFailsEveryTime() {
    // 毎回失敗
    MockEloquent mock = (new MockEloquent()).failOnGet(new QueryException('boom')).repeat();
    Scribe scribe = Scribe.of(Account.class).field('Name');
    for (Integer attempt = 1; attempt <= 3; attempt++) {
      try {
        mock.get(scribe);
        Assert.fail('Attempt ' + attempt + ' must fail.');
      } catch (QueryException e) {
        Assert.areEqual('boom', e.getMessage());
      }
    }
  }

  @isTest
  static void testScenario_LabeledConfig_ThenFailsOnceThenRetrySucceeds() {
    // opp は1回失敗 → リトライされれば2回目は成功
    MockEloquent mock = (new MockEloquent())
      .attach('opp', new List<IEntry>{ MockEntry.of(Account.class).autoId(1).set('Name', 'X') })
      .failOnGet(new QueryException('boom'))
      .whenLabel('opp');
    Scribe scribe = Scribe.of(Account.class).field('Name');

    try {
      mock.label('opp').get(scribe);
      Assert.fail('1st attempt must fail.');
    } catch (QueryException e) {
      Assert.areEqual('boom', e.getMessage());
    }
    // the failure released 'opp' — the retry reaches the attached data
    Assert.areEqual('X', mock.label('opp').get(scribe)[0].get('Name'));
  }

  @isTest
  static void testScenario_TwoLabeledConfigsSameLabel_ThenFifoAcrossRetries() {
    // opp は1回目A、2回目B、3回目成功
    MockEloquent mock = (new MockEloquent())
      .attach('opp', new List<IEntry>())
      .failOnGet(new QueryException('A'))
      .whenLabel('opp')
      .failOnGet(new QueryException('B'))
      .whenLabel('opp');
    Scribe scribe = Scribe.of(Account.class).field('Name');

    try {
      mock.label('opp').get(scribe);
      Assert.fail('1st attempt must fail with A.');
    } catch (QueryException e) {
      Assert.areEqual('A', e.getMessage());
    }
    try {
      mock.label('opp').get(scribe);
      Assert.fail('2nd attempt must fail with B.');
    } catch (QueryException e) {
      Assert.areEqual('B', e.getMessage());
    }
    Assert.areEqual(0, mock.label('opp').get(scribe).size(), '3rd attempt succeeds.');
  }

  @isTest
  static void testScenario_LabeledRepeat_ThenFailsEveryAttempt() {
    // opp でエラーが繰り返し起こる — the chain does what it reads
    MockEloquent mock = (new MockEloquent()).failOnGet(new QueryException('boom')).whenLabel('opp').repeat();
    Scribe scribe = Scribe.of(Account.class).field('Name');
    for (Integer attempt = 1; attempt <= 3; attempt++) {
      try {
        mock.label('opp').get(scribe);
        Assert.fail('Attempt ' + attempt + ' must fail.');
      } catch (QueryException e) {
        Assert.areEqual('boom', e.getMessage());
      }
    }
  }

  // --- F. Integration + regression -----------------------------------------

  @isTest
  static void testIntegration_MultipleLabelsAcrossQueriesAndDmls_ThenAllRouteCorrectly() {
    MockEntry oppMock = MockEntry.of(Account.class).autoId(1).set('Name', 'OppAcc');
    MockEntry quoteMock = MockEntry.of(Account.class).autoId(2).set('Name', 'QuoteAcc');
    MockEloquent mock = (new MockEloquent())
      .attach('oppLoad', new List<IEntry>{ oppMock })
      .attach('quoteLoad', new List<IEntry>{ quoteMock });

    Scribe scribe = Scribe.of(Account.class).field('Name');

    // Query labels independently
    IEntry oppResult = mock.label('oppLoad').first(scribe);
    IEntry quoteResult = mock.label('quoteLoad').first(scribe);
    Assert.areEqual('OppAcc', oppResult.get('Name'));
    Assert.areEqual('QuoteAcc', quoteResult.get('Name'));

    // DML to different labels
    mock.label('finalDml').doUpdate(new Account(Id = '001000000000001', Name = 'X'));
    mock.label('cleanup').doDelete(new Account(Id = '001000000000002'));

    // Assert per-label DML state
    Assert.areEqual(1, mock.upsertedRecordsAt('finalDml').size());
    Assert.areEqual(0, mock.upsertedRecordsAt('cleanup').size());
    Assert.areEqual(0, mock.deletedCountAt('finalDml'));
    Assert.areEqual(1, mock.deletedCountAt('cleanup'));

    // Legacy public fields untouched (no default-label DML happened)
    Assert.areEqual(0, mock.upsertedRecords.size());
    Assert.areEqual(0, mock.deletedCount);
  }

  @isTest
  static void testCopy_AfterAttach_ThenAttachSurvives() {
    MockEntry entry = MockEntry.of(Account.class).autoId(1).set('Name', 'Survives');
    MockEloquent mock = (new MockEloquent())
      .attach('opp', new List<IEntry>{ entry })
      .failOnDoUpdate(); // triggers internal copy()

    Scribe scribe = Scribe.of(Account.class).field('Name');
    List<IEntry> result = mock.label('opp').get(scribe);
    Assert.areEqual(1, result.size(), 'attach data should survive failOnXxx copy().');
    Assert.areEqual('Survives', result[0].get('Name'));
  }

  @isTest
  static void testLabel_WhenOperationThrows_ThenLabelStillResetsForNextCall() {
    MockEloquent mock = (new MockEloquent()).failOnGet();
    Scribe scribe = Scribe.of(Account.class).field('Name');
    // First op throws via failOnGet, but label was consumed
    try {
      mock.label('foo').get(scribe);
    } catch (ApexEloquentException e) {
      // expected
    }
    // After the throw, currentLabel should be reset — next op should use 'default'
    // Verify by hitting failOnGet again with another scoped fail that should NOT fire
    // (since the queue was consumed and 'foo' label state is gone)
    MockEloquent mock2 = (new MockEloquent()).failOnGet().whenLabel('opp');
    List<IEntry> result = mock2.get(scribe); // no label, should NOT fire scoped fail
    Assert.areEqual(0, result.size(), 'Default-label op should not consume opp-scoped fail.');
  }

  @isTest
  static void testLegacyMockEloquentConstructor_WhenWithEntries_ThenGetWithoutLabelReturnsEntries() {
    MockEntry e1 = MockEntry.of(Account.class).autoId(1).set('Name', 'X');
    MockEntry e2 = MockEntry.of(Account.class).autoId(2).set('Name', 'Y');
    MockEloquent mock = new MockEloquent(new List<IEntry>{ e1, e2 });
    Scribe scribe = Scribe.of(Account.class).field('Name');
    List<IEntry> result = mock.get(scribe);
    Assert.areEqual(2, result.size(), 'Legacy constructor still works for default-label queries.');
  }

  // ===========================================================================
  // strict mode (issue_39)
  // ===========================================================================

  @isTest
  static void testStrict_AfterLabelCall_NoLabelOpThrows() {
    MockEloquent mock = (new MockEloquent()).attach('a', new List<IEntry>());
    Scribe scribe = Scribe.of(Account.class).field('Name');
    mock.label('a').get(scribe); // enters strict mode, consumes 'a'
    try {
      mock.get(scribe); // no label — strict mode requires .label()
      Assert.fail('Expected strict-mode exception for label-less op after strict mode entered.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(
        e.getMessage().contains('strict mode required'),
        'Expected strict-mode message, got: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void testStrict_AfterStrictModeEntered_ReusingLabelThrows() {
    MockEloquent mock = (new MockEloquent()).attach('a', new List<IEntry>());
    Scribe scribe = Scribe.of(Account.class).field('Name');
    mock.label('a').get(scribe); // 'a' consumed
    try {
      mock.label('a').get(scribe); // 'a' reused — consume-once violation
      Assert.fail('Expected consume-once exception when reusing label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(
        e.getMessage().contains('already been consumed'),
        'Expected consume-once message, got: ' + e.getMessage()
      );
      Assert.isTrue(e.getMessage().contains('\'a\''), 'Should mention the label name.');
    }
  }

  @isTest
  static void testStrict_AfterStrictModeEntered_NewLabelOk() {
    MockEloquent mock = (new MockEloquent())
      .attach('a', new List<IEntry>())
      .attach('b', new List<IEntry>());
    Scribe scribe = Scribe.of(Account.class).field('Name');
    mock.label('a').get(scribe); // strict mode on, 'a' consumed
    mock.label('b').get(scribe); // different label — must NOT throw
    Assert.areEqual(0, mock.upsertedRecordsAt('default').size(), 'No DML happened.');
  }

  @isTest
  static void testStrict_LenientMode_AnyNumberOfNoLabelOpsOk() {
    // Backward-compat lock: a MockEloquent that never sees .label() must
    // continue to accept any number of label-less calls. This is the case
    // that existing 700+ tests rely on.
    MockEloquent mock = new MockEloquent(
      new List<IEntry>{ MockEntry.of(Account.class).autoId(1).set('Name', 'X') }
    );
    Scribe scribe = Scribe.of(Account.class).field('Name');
    mock.get(scribe);
    mock.get(scribe);
    mock.get(scribe);
    Assert.isTrue(true, 'No exception thrown — lenient mode allows repeated label-less ops.');
  }

  @isTest
  static void testStrict_OpThrowsViaFailOn_LabelReleasedForRetry() {
    // A failed op does not fulfill the label's intent: the label is released
    // (consume-once = one SUCCESS per label), so a retry under the same label
    // reaches the next outcome — here, the attached data.
    MockEloquent mock = (new MockEloquent())
      .attach('a', new List<IEntry>())
      .failOnGet(new QueryException('boom'))
      .whenLabel('a');
    Scribe scribe = Scribe.of(Account.class).field('Name');
    try {
      mock.label('a').get(scribe);
      Assert.fail('1st attempt must fail via failOnGet.');
    } catch (QueryException e) {
      Assert.areEqual('boom', e.getMessage());
    }
    Assert.areEqual(0, mock.label('a').get(scribe).size(), 'Retry under the released label succeeds.');
  }

  @isTest
  static void testStrict_DefaultExplicit_AlsoConsumeOnce() {
    MockEloquent mock = (new MockEloquent()).attach('default', new List<IEntry>());
    Scribe scribe = Scribe.of(Account.class).field('Name');
    mock.label('default').get(scribe); // 'default' consumed
    try {
      mock.label('default').get(scribe);
      Assert.fail('Expected consume-once for explicit default.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('already been consumed'));
    }
  }

  @isTest
  static void testStrict_ChainOverwrites_OnlyLastLabelIsConsumed() {
    MockEloquent mock = (new MockEloquent())
      .attach('a', new List<IEntry>())
      .attach('b', new List<IEntry>());
    Scribe scribe = Scribe.of(Account.class).field('Name');
    // chain .label('a').label('b') before op — only 'b' is consumed
    mock.label('a').label('b').get(scribe);
    // 'a' was never consumed, so this should NOT throw consume-once
    mock.label('a').get(scribe);
    Assert.isTrue(true, 'No exception — only the last labeled value is consumed by an op.');
  }

  @isTest
  static void testStrict_StrictModePropagatesThroughCopy() {
    // failOnXxx triggers an internal copy(). The strict-mode flag and the
    // consumedLabels set must survive the copy so that consume-once still
    // works for labels used before the failOn chain.
    MockEloquent mock = (new MockEloquent()).attach('a', new List<IEntry>());
    Scribe scribe = Scribe.of(Account.class).field('Name');
    mock.label('a').get(scribe); // strict mode entered, 'a' consumed
    MockEloquent withFail = (MockEloquent) mock.failOnDoUpdate(); // internal copy()
    try {
      withFail.label('a').doUpdate(new Account(Id = '001000000000001', Name = 'X'));
      Assert.fail('Expected consume-once: \'a\' was consumed on the original instance.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(
        e.getMessage().contains('already been consumed'),
        'Expected consume-once after copy(). Got: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void testStrict_LabelNullOrBlank_ThrowsRequiredBeforeStrictModeActivation() {
    // .label(null) / .label('') throw the required-argument error and must
    // NOT activate strict mode (so subsequent lenient ops keep working).
    MockEloquent mock = new MockEloquent(
      new List<IEntry>{ MockEntry.of(Account.class).autoId(1).set('Name', 'X') }
    );
    Scribe scribe = Scribe.of(Account.class).field('Name');
    try {
      mock.label(null).get(scribe);
      Assert.fail('Expected required-arg exception for null label.');
    } catch (ApexEloquentException e) {
      // expected — label(null) throws BEFORE setting strictMode
    }
    // mock should still be in lenient mode — these must not throw
    mock.get(scribe);
    mock.get(scribe);
    Assert.isTrue(true, 'label(null) did not flip strict mode on.');
  }

  // ===============================================================================
  // Unattached-label guard (auto-strict in test context)
  // ===============================================================================

  @isTest
  static void testGet_WhenLabelNotAttached_ThenThrowsWithAttachedLabelList() {
    // Arrange - 'byPostal' is never attached (forgotten / typo'd attach)
    Scribe scribe = Scribe.of(Account.class).field('Id');
    MockEloquent mock = (new MockEloquent())
      .attach('byName', new List<IEntry>{ MockEntry.of(Account.class).autoId(1) })
      .attach('byCompanyId', new List<IEntry>());

    // Act & Assert
    try {
      mock.label('byPostal').get(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('\'byPostal\' has no attached entries'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('byCompanyId, byName'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('.attach(label, new List<IEntry>())'), e.getMessage());
    }
  }

  @isTest
  static void testGet_WhenEmptyListAttached_ThenReturnsEmptyWithoutException() {
    // Arrange - an explicitly attached empty list is the legitimate zero-row declaration
    Scribe scribe = Scribe.of(Account.class).field('Id');
    MockEloquent mock = (new MockEloquent()).attach('byName', new List<IEntry>());

    // Act
    List<IEntry> entries = mock.label('byName').get(scribe);

    // Assert
    Assert.areEqual(0, entries.size(), 'Attached empty list must stay a valid zero-row path');
  }

  @isTest
  static void testFirst_WhenLabelNotAttached_ThenThrows() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id');
    MockEloquent mock = (new MockEloquent()).attach('byName', new List<IEntry>());

    // Act & Assert - first() is guarded the same way as get()
    try {
      mock.label('byPostal').first(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('has no attached entries'), e.getMessage());
    }
  }

  @isTest
  static void testDoUpdate_WhenLabelNotAttached_ThenNoException() {
    // Arrange - DML does not consult attached data, so unattached labels stay legal
    MockEloquent mock = (new MockEloquent()).attach('byName', new List<IEntry>());
    Account acc = new Account(Id = MockEntry.of(Account.class).autoId(1).getId(), Name = 'x');

    // Act
    mock.label('updateAccounts').doUpdate(acc);

    // Assert
    Assert.areEqual(1, mock.upsertedRecordsAt('updateAccounts').size());
  }

  @isTest
  static void testGet_WhenLegacyUnlabeledMode_ThenConstructorEntriesUnchanged() {
    // Arrange - label-free legacy mode is untouched by the guard
    Scribe scribe = Scribe.of(Account.class).field('Id');
    MockEloquent mock = new MockEloquent(new List<IEntry>{ MockEntry.of(Account.class).autoId(1) });

    // Act
    List<IEntry> entries = mock.get(scribe);

    // Assert
    Assert.areEqual(1, entries.size());
  }

  private class MockNotFoundException extends Exception {
  }

  @isTest
  static void testFirstOrFail_WhenCustomExceptionAndEntryAttached_ThenReturnsEntry() {
    // Arrange
    MockEntry grpEntry = MockEntry.of(Account.class).autoId(1).set('Name', 'Hit');
    MockEloquent mock = (new MockEloquent()).attach('fetch', new List<IEntry>{ grpEntry });
    Scribe scribe = Scribe.of(Account.class).field('Id').field('Name');

    // Act
    IEntry result = mock.label('fetch').firstOrFail(scribe, new MockNotFoundException('not used'));

    // Assert
    Assert.areEqual('Hit', result.get('Name'));
  }

  @isTest
  static void testFirstOrFail_WhenCustomExceptionAndEmptyAttached_ThenThrowsItAsIs() {
    // Arrange - the zero-row path is declared with an explicit empty attach
    MockEloquent mock = (new MockEloquent()).attach('fetch', new List<IEntry>());
    Scribe scribe = Scribe.of(Account.class).field('Id');

    // Act & Assert - the given exception is thrown as-is (type and message preserved)
    try {
      mock.label('fetch').firstOrFail(scribe, new MockNotFoundException('business-facing message'));
      Assert.fail('Expected MockNotFoundException to be thrown');
    } catch (MockNotFoundException e) {
      Assert.areEqual('business-facing message', e.getMessage());
    }
  }

  @isTest
  static void testFirstOrFail_WhenCustomExceptionIsNull_ThenThrowsRequired() {
    // Arrange
    MockEloquent mock = (new MockEloquent()).attach('fetch', new List<IEntry>());

    // Act & Assert
    try {
      mock.label('fetch').firstOrFail(Scribe.of(Account.class).field('Id'), null);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The `orFail` argument is required'), e.getMessage());
    }
  }

  // ===============================================================================
  // failSave: per-record failures for SaveResult/UpsertResult-returning DML (issue #49)
  // ===============================================================================

  @isTest
  static void testFailSave_WhenPartialUpdate_ThenFailedResultAndSpyExcludesIt() {
    // Arrange - the failing record is designated by its autoId
    Account good = new Account(Id = MockEntry.of(Account.class).autoId(1).getId(), Name = 'good');
    Account bad = new Account(Id = MockEntry.of(Account.class).autoId(2).getId(), Name = 'bad');
    MockEloquent mock = (new MockEloquent()).failSave(bad.Id, 'custom validation says no');

    // Act
    List<Database.SaveResult> results = mock.doUpdate(new List<SObject>{ good, bad }, false);

    // Assert - per-record results mirror a real partial success
    Assert.isTrue(results[0].isSuccess());
    Assert.isFalse(results[1].isSuccess());
    Assert.areEqual(bad.Id, results[1].getId());
    Assert.areEqual('custom validation says no', results[1].getErrors()[0].getMessage());

    // Assert - the failed record was not saved, so the spy excludes it
    List<SObject> saved = mock.upsertedRecordsAt('default');
    Assert.areEqual(1, saved.size());
    Assert.areEqual(good.Id, saved[0].Id);
  }

  @isTest
  static void testFailSave_WhenAllOrNoneTrue_ThenThrowsAndNothingRecorded() {
    // Arrange
    Account good = new Account(Id = MockEntry.of(Account.class).autoId(1).getId(), Name = 'good');
    Account bad = new Account(Id = MockEntry.of(Account.class).autoId(2).getId(), Name = 'bad');
    MockEloquent mock = (new MockEloquent()).failSave(bad.Id, 'custom validation says no');

    // Act & Assert - all-or-nothing semantics: the whole operation throws
    try {
      mock.doUpdate(new List<SObject>{ good, bad }, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('DML failed with: custom validation says no'), e.getMessage());
    }
    Assert.areEqual(0, mock.upsertedRecordsAt('default').size(), 'Nothing may be recorded before the throw');
  }

  @isTest
  static void testFailSave_WhenSingleUpdate_ThenFailedResult() {
    // Arrange
    Account bad = new Account(Id = MockEntry.of(Account.class).autoId(1).getId(), Name = 'bad');
    MockEloquent mock = (new MockEloquent()).failSave(bad.Id, 'no');

    // Act
    Database.SaveResult result = mock.doUpdate((SObject) bad, false);

    // Assert
    Assert.isFalse(result.isSuccess());
    Assert.areEqual('no', result.getErrors()[0].getMessage());
  }

  @isTest
  static void testFailSave_WhenUpsertByExternalId_ThenFailedResult() {
    // Arrange
    Account bad = new Account(Id = MockEntry.of(Account.class).autoId(1).getId(), Name = 'bad');
    MockEloquent mock = (new MockEloquent()).failSave(bad.Id, 'no upsert');

    // Act
    Database.UpsertResult result = mock.doUpsertByExternalId((SObject) bad, Account.Name, false);

    // Assert
    Assert.isFalse(result.isSuccess());
    Assert.isFalse(result.isCreated());
    Assert.areEqual('no upsert', result.getErrors()[0].getMessage());
  }

  @isTest
  static void testFailSave_WhenGuardsViolated_ThenThrowRequired() {
    // recordId null
    try {
      (new MockEloquent()).failSave(null, 'msg');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The `recordId` argument is required'), e.getMessage());
    }
    // errorMessage blank
    try {
      (new MockEloquent()).failSave(MockEntry.of(Account.class).autoId(1).getId(), '');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The `errorMessage` argument is required'), e.getMessage());
    }
  }

  @isTest
  static void testFailSave_ThenFailOn_ThenSaveErrorSurvives() {
    // Arrange - failSave registered BEFORE a copy()-returning failOnXxx (issue #61):
    // copy() must carry saveErrorsById, or the registration silently vanishes
    Account bad = new Account(Id = MockEntry.of(Account.class).autoId(1).getId(), Name = 'bad');
    MockEloquent mock = (new MockEloquent())
      .failSave(bad.Id, 'no')
      .failOnGet(new QueryException('unrelated'));

    // Act
    Database.SaveResult result = mock.doUpdate((SObject) bad, false);

    // Assert
    Assert.isFalse(result.isSuccess(), 'failSave registration must survive the failOnXxx copy()');
    Assert.areEqual('no', result.getErrors()[0].getMessage());
  }

  @isTest
  static void testFailOn_ThenFailSave_ThenSaveErrorSurvives() {
    // Arrange - reverse order: failSave mutates the instance returned by failOnXxx
    Account bad = new Account(Id = MockEntry.of(Account.class).autoId(1).getId(), Name = 'bad');
    MockEloquent mock = (new MockEloquent())
      .failOnGet(new QueryException('unrelated'))
      .failSave(bad.Id, 'no');

    // Act
    Database.SaveResult result = mock.doUpdate((SObject) bad, false);

    // Assert
    Assert.isFalse(result.isSuccess());
    Assert.areEqual('no', result.getErrors()[0].getMessage());
  }

  // ===============================================================================
  // Builder immutability: attach / failSave / whenLabel return copies (issue #63)
  // ===============================================================================

  @isTest
  static void testAttach_ReturnsCopy_AndReceiverIsUnmodified() {
    // Arrange
    MockEloquent original = new MockEloquent();
    MockEloquent configured = original.attach(
      'fetch',
      new List<IEntry>{ MockEntry.of(Account.class).autoId(1) }
    );
    Scribe scribe = Scribe.of(Account.class).field('Id');

    // Assert - the returned instance sees the attached data
    Assert.areEqual(1, configured.label('fetch').get(scribe).size());

    // Assert - the receiver never learned the label: strict unattached-label read throws
    try {
      original.label('fetch').get(scribe);
      Assert.fail('Expected ApexEloquentException: label must not leak into the receiver');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('fetch'), e.getMessage());
    }
  }

  @isTest
  static void testFailSave_ReturnsCopy_AndReceiverIsUnmodified() {
    // Arrange
    Account bad = new Account(Id = MockEntry.of(Account.class).autoId(1).getId(), Name = 'bad');
    MockEloquent original = new MockEloquent();
    MockEloquent configured = original.failSave(bad.Id, 'no');

    // Assert - the returned instance fails the record, the receiver still succeeds
    Assert.isFalse(configured.doUpdate((SObject) bad, false).isSuccess());
    Assert.isTrue(original.doUpdate((SObject) bad, false).isSuccess());
  }

  @isTest
  static void testWhenLabel_ReturnsCopy_AndReceiverIsUnmodified() {
    // Arrange
    MockEloquent withFail = (new MockEloquent()).failOnGet(new QueryException('boom'));
    MockEloquent scoped = withFail.whenLabel('opp');
    Scribe scribe = Scribe.of(Account.class).field('Name');

    // Assert - on the scoped instance the config targets 'opp', so a plain get does not fire
    Assert.areEqual(0, scoped.get(scribe).size());

    // Assert - the receiver's config is still unscoped and fires on a plain get
    try {
      withFail.get(scribe);
      Assert.fail('Expected QueryException: whenLabel must not leak into the receiver');
    } catch (QueryException e) {
      Assert.areEqual('boom', e.getMessage());
    }
  }
}
