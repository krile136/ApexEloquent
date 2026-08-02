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
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'Name', 'Industry' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Act
    MockEntry mockEntry = new MockEntry(record, fieldStructure);

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully with fieldStructure');
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
  static void testOf_WhenAddSobjectType_ThenReturnMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class);

    // Act & Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully using of() method.');
  }

  @isTest
  static void testOf_WhenApplyValidRecordType_ThenReturnMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class);

    // Act & Assert
    Assert.isNotNull(
      mockEntry,
      'MockEntry should be created successfully using of() method with valid SObjectType.'
    );
  }

  @isTest
  static void testOf_WhenApplyStringType_ThenThrowException() {
    // Act & Assert
    try {
      MockEntry mockEntry = MockEntry.of(String.class);
      Assert.fail('Expected IllegalArgumentException to be thrown when using String type.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('MockEntry.of(System.Type recordType)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testSet_WhenApplyNullFieldName_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.set(null, 'Mock Account');
      Assert.fail('Expected ApexEloquentException to be thrown when setting a field with null name.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('set(String fieldName, Object value)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testSet_WhenApplyEmptyFieldName_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.set('', 'Mock Account');
      Assert.fail('Expected ApexEloquentException to be thrown when setting a field with empty string name.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('set(String fieldName, Object value)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testSet_WhenAddFieldAndValue_ThenGetFieldValue() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    mockEntry = mockEntry.set('Name', 'Mock Account');

    // Assert
    String accountName = mockEntry.getName();
    Assert.areEqual('Mock Account', accountName, 'The Name should match the added value.');
  }

  @isTest
  static void testSetChildren_WhenApplyNullToChildObjectName_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .withChildren(Scribe.asChild(Contract.class).field('Name'))
      .buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.setChildren(null, new List<MockEntry>());
      Assert.fail('Expected ApexEloquentException to be thrown when setting children with null list.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(
        errorMessage.contains('setChildren(String childObjectNameOrRelationName, List<MockEntry> children)')
      );
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testSetChildren_WhenApplyEmptyStringToChildObjectName_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .withChildren(Scribe.asChild(Contract.class).field('Name'))
      .buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.setChildren('', new List<MockEntry>());
      Assert.fail('Expected ApexEloquentException to be thrown when setting children with null childObjectName.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(
        errorMessage.contains('setChildren(String childObjectNameOrRelationName, List<MockEntry> children)')
      );
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testSetChildren_WhenApplyNullToChildren_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .withChildren(Scribe.asChild(Contract.class).field('Name'))
      .buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.setChildren('Contract', null);
      Assert.fail('Expected ApexEloquentException to be thrown when setting children with null list.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(
        errorMessage.contains('setChildren(String childObjectNameOrRelationName, List<MockEntry> children)')
      );
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testSetChildren_WhenAddChildren_ThenGetChildren() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .withChildren(Scribe.asChild(Contract.class).field('Name'))
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class)
      .setChildren(
        'Contract',
        new List<MockEntry>{
          MockEntry.of(Contract.class).set('Name', 'Mock Contract 1'),
          MockEntry.of(Contract.class).set('Name', 'Mock Contract 2')
        }
      )
      .setFieldStructure(fieldStructure);

    // Act
    List<IEntry> children = mockEntry.getChildren('Contract');

    // Assert
    Assert.isNotNull(children, 'Children should not be null.');
    Assert.areEqual(2, children.size(), 'There should be two child entries.');
    Assert.areEqual('Mock Contract 1', children[0].getName(), 'First child name should match.');
    Assert.areEqual('Mock Contract 2', children[1].getName(), 'Second child name should match.');
  }

  @isTest
  static void testSetParent_WhenApplyNullToParentIdFieldName_WhenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .parentField(Scribe.asParent('AccountId').field('Name'))
      .buildFieldStructure();

    // Act & Assert
    try {
      MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class)
        .setParent(null, MockEntry.of(Account.class).set('Name', 'Mock Account'))
        .setFieldStructure(fieldStructure);
      Assert.fail('Expected ApexEloquentException to be thrown when setting parent with null parentIdFieldName.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('setParent(String parentIdFieldName, MockEntry parent)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testSetParent_WhenApplyEmptyStringToParentIdFieldName_WhenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .parentField(Scribe.asParent('AccountId').field('Name'))
      .buildFieldStructure();

    // Act & Assert
    try {
      MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class)
        .setParent('', MockEntry.of(Account.class).set('Name', 'Mock Account'))
        .setFieldStructure(fieldStructure);
      Assert.fail(
        'Expected ApexEloquentException to be thrown when setting parent with empty string parentIdFieldName.'
      );
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('setParent(String parentIdFieldName, MockEntry parent)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testSetParent_WhenAddParent_ThenGetParent() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .parentField(Scribe.asParent('AccountId').field('Name'))
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class)
      .setParent('AccountId', MockEntry.of(Account.class).set('Name', 'Mock Account'))
      .setFieldStructure(fieldStructure);

    // Act
    IEntry parent = mockEntry.getParent('AccountId');

    // Assert
    Assert.isNotNull(parent, 'Parent should not be null.');
    Assert.areEqual('Mock Account', parent.getName(), 'Parent name should match.');
  }

  @isTest
  static void testGetParent_WhenParentIsStagedNull_ThenReturnNull() {
    // A parent explicitly staged as null (setParent(field, null)) means "the parent
    // record does not exist". Entry.getParent() returns null in the same case, so
    // MockEntry must behave the same — otherwise the production-side null branch
    // (if (parent == null) { ... }) can never be covered by a unit test.
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .parentField(Scribe.asParent('AccountId').field('Name'))
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class)
      .setParent('AccountId', null)
      .setFieldStructure(fieldStructure);

    // Act
    IEntry parent = mockEntry.getParent('AccountId');

    // Assert
    Assert.isNull(parent, 'A parent staged as null should be returned as null, matching Entry.getParent().');
  }

  @isTest
  static void testTemplate_WhenApplyNull_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.template(null);
      Assert.fail('Expected ApexEloquentException to be thrown when applying null template.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('template(Map<String, Object> fieldToValue)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testTemplate_WhenAddTemplate_ThenCanGetFieldValue() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    Map<String, Object> template = new Map<String, Object>{ 'Name' => 'Mock Account' };
    mockEntry = mockEntry.template(template);

    // Assert
    String accountName = mockEntry.getName();
    Assert.areEqual('Mock Account', accountName, 'The Name should match the template value.');
  }

  @isTest
  static void testTemplate_WhenAddTemplateAtChildren_ThenGetChildrenValues() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .withChildren(Scribe.asChild(Contract.class).field('Name'))
      .buildFieldStructure();
    Map<String, Object> template = new Map<String, Object>{ 'Name' => 'Mock Contract {#}' };
    MockEntry mockEntry = MockEntry.of(Account.class)
      .setChildren('Contract', MockEntry.of(Contract.class).template(template).times(2));
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    List<IEntry> children = mockEntry.getChildren('Contract');

    // Assert
    Assert.isNotNull(children, 'Children should not be null.');
    Assert.areEqual(2, children.size(), 'There should be two child entries.');
    Assert.areEqual('Mock Contract 1', children[0].getName(), 'First child name should match.');
    Assert.areEqual('Mock Contract 2', children[1].getName(), 'Second child name should match.');
  }

  @isTest
  static void testTemplate_WhenAddTemplateAtParent_ThenGetParentValue() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .parentField(Scribe.asParent('AccountId').field('Name'))
      .buildFieldStructure();
    Map<String, Object> template = new Map<String, Object>{ 'Name' => 'Mock Account' };
    MockEntry mockEntry = MockEntry.of(Opportunity.class)
      .setParent('AccountId', MockEntry.of(Account.class).template(template));
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    IEntry parent = mockEntry.getParent('AccountId');

    // Assert
    Assert.isNotNull(parent, 'Parent should not be null.');
    Assert.areEqual('Mock Account', parent.getName(), 'Parent name should match the template value.');
  }

  @isTest
  static void testAutoId_WhenUsingAutoId_ThenGenerateId() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    mockEntry = mockEntry.autoId('AAA');

    // Assert
    String accountId = mockEntry.getId();
    Assert.areEqual('001000000000AAAAA2', accountId, 'The Id should match the auto-generated value.');
  }

  @isTest
  static void testAutoId_WhenUsingAutoIdWithInteger_ThenGenerateId() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    mockEntry = mockEntry.autoId(123);

    // Assert
    String accountId = mockEntry.getId();
    Assert.areEqual('001000000000123AAA', accountId, 'The Id should match the auto-generated value.');
  }

  @isTest
  static void testAutoId_WhenApplyMinusInteger_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry = mockEntry.autoId(-1);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('autoId(Integer suffix)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testAutoId_WhenApplyVoidString_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry = mockEntry.autoId('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('autoId(String suffix)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testTimes_WhenApplyNull_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.set('Name', 'Name-{#}').times(null);
      Assert.fail('Expected ApexEloquentException to be thrown when applying null times.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('times(Integer count)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testTimes_WhenApplyNegativeInteger_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.set('Name', 'Name-{#}').times(-1);
      Assert.fail('Expected ApexEloquentException to be thrown when applying negative times.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('times(Integer count)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testTimes_WhenAddNameTimes_ThenReturnMockEntriesWithNameTimes() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Name', 'Name-{#}').times(3);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('Name-1', mockEntries[0].getName(), 'First entry name should match.');
    Assert.areEqual('Name-2', mockEntries[1].getName(), 'Second entry name should match.');
    Assert.areEqual('Name-3', mockEntries[2].getName(), 'Third entry name should match.');
  }

  @isTest
  static void testTimes_WhenAddNullToStartAt_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.set('Name', 'Name-{#}').times(3, null);
      Assert.fail('Expected ApexEloquentException to be thrown when applying null startAt.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('times(Integer count, Integer startAt)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }


  @isTest
  static void testTimes_WhenAddNameTimesWithStartAt_ThenReturnMockEntriesWithNameTimes() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Name', 'Name-{#}').times(3, 5);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('Name-5', mockEntries[0].getName(), 'First entry name should match.');
    Assert.areEqual('Name-6', mockEntries[1].getName(), 'Second entry name should match.');
    Assert.areEqual('Name-7', mockEntries[2].getName(), 'Third entry name should match.');
  }

  @isTest
  static void testTimes_WhenAddNullToInterval_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(OrderItem.class).field('Quantity').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(OrderItem.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.set('Quantity', '{#}').times(3, 1, null);
      Assert.fail('Expected ApexEloquentException to be thrown when applying null interval.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('times(Integer count, Integer startAt, Integer interval)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testTimes_WhenAddZeroToInterval_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(OrderItem.class).field('Quantity').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(OrderItem.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.set('Quantity', '{#}').times(3, 1, 0);
      Assert.fail('Expected ApexEloquentException to be thrown when applying zero interval.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('times(Integer count, Integer startAt, Integer interval)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testTimes_AddAlphabeticPlaceholderAndNegativeStartAt_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.set('Name', 'Name-{A}').times(3, -1, 1);
      Assert.fail('Expected ApexEloquentException to be thrown when applying negative interval.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('times(Integer count, Integer startAt, Integer interval)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testTimes_WhenAddAmountTimesWithStartAt_ThenReturnMOckEntriesWithAmountTimes() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(OrderItem.class).field('Quantity').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(OrderItem.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Quantity', '{#}').times(3, 50000, 10000);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual(50000, mockEntries[0].get('Quantity'), 'First entry Quantity should match.');
    Assert.areEqual(60000, mockEntries[1].get('Quantity'), 'Second entry Quantity should match.');
    Assert.areEqual(70000, mockEntries[2].get('Quantity'), 'Third entry Quantity should match.');
  }

  @isTest
  static void testTimes_WhenAddIdTimes_ThenReturnMockEntriesWithIdTimes() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Id', '{#}').times(3, 1);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('001000000000001AAA', mockEntries[0].getId(), 'First entry Id should match.');
    Assert.areEqual('001000000000002AAA', mockEntries[1].getId(), 'Second entry Id should match.');
    Assert.areEqual('001000000000003AAA', mockEntries[2].getId(), 'Third entry Id should match.');
  }

  @isTest
  static void testTimes_WhenAddIdTimesWithStartAt_ThenReturnMockEntriesWithIdTimes() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Id', '{#}').times(3, 101);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('001000000000101AAA', mockEntries[0].getId(), 'First entry Id should match.');
    Assert.areEqual('001000000000102AAA', mockEntries[1].getId(), 'Second entry Id should match.');
    Assert.areEqual('001000000000103AAA', mockEntries[2].getId(), 'Third entry Id should match.');
  }

  @isTest
  static void testTimes_WhenUsingUppercaseLetter_ThenReturnConsecutiveUppercaseLetters() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Name', 'Name-{A}').times(3);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('Name-A', mockEntries[0].getName(), 'First entry name should match.');
    Assert.areEqual('Name-B', mockEntries[1].getName(), 'Second entry name should match.');
    Assert.areEqual('Name-C', mockEntries[2].getName(), 'Third entry name should match.');
  }

  @isTest
  static void testTimes_WhenUsingUppercaseLetterWithStartAt_ThenReturnConsecutiveUppercaseLetters() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Name', 'Name-{A}').times(3, 26); // Start at 'Z'

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('Name-Z', mockEntries[0].getName(), 'First entry name should match.');
    Assert.areEqual('Name-AA', mockEntries[1].getName(), 'Second entry name should match.');
    Assert.areEqual('Name-AB', mockEntries[2].getName(), 'Third entry name should match.');
  }

  @isTest
  static void testTimes_WhenUsingUppercaseLetterAtId_ThenReturnConsectiveUppercaseLetterIds() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Id', '{A}').times(3);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('00100000000000AAAQ', mockEntries[0].getId(), 'First entry Id should match.');
    Assert.areEqual('00100000000000BAAQ', mockEntries[1].getId(), 'Second entry Id should match.');
    Assert.areEqual('00100000000000CAAQ', mockEntries[2].getId(), 'Third entry Id should match.');
  }

  @isTest
  static void testTimes_WhenUsingUppercaseLetterAtIdWithStartAt_ThenReturnConsectiveUppercaseLetterIds() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Id', '{A}').times(3, 26); // Start at 'Z'

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('00100000000000ZAAQ', mockEntries[0].getId(), 'First entry Id should match.');
    Assert.areEqual('0010000000000AAAAY', mockEntries[1].getId(), 'Second entry Id should match.');
    Assert.areEqual('0010000000000ABAAY', mockEntries[2].getId(), 'Third entry Id should match.');
  }

  @isTest
  static void testTimes_WhenUsingLowercaseLetter_ThenReturnConsecutiveLowercaseLetters() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Name', 'Name-{a}').times(3);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('Name-a', mockEntries[0].getName(), 'First entry name should match.');
    Assert.areEqual('Name-b', mockEntries[1].getName(), 'Second entry name should match.');
    Assert.areEqual('Name-c', mockEntries[2].getName(), 'Third entry name should match.');
  }

  @isTest
  static void testTimes_WhenUsingLowercaseLetterWithStartAt_ThenReturnConsecutiveLowercaseLetters() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Name', 'Name-{a}').times(3, 26); // Start at 'z'

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('Name-z', mockEntries[0].getName(), 'First entry name should match.');
    Assert.areEqual('Name-aa', mockEntries[1].getName(), 'Second entry name should match.');
    Assert.areEqual('Name-ab', mockEntries[2].getName(), 'Third entry name should match.');
  }

  @isTest
  static void testTimes_WhenUsingLowercaseLetterAtId_ThenReturnConsectiveLowercaseLetterIds() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Id', '{a}').times(3);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('00100000000000aAAA', mockEntries[0].getId(), 'First entry Id should match.');
    Assert.areEqual('00100000000000bAAA', mockEntries[1].getId(), 'Second entry Id should match.');
    Assert.areEqual('00100000000000cAAA', mockEntries[2].getId(), 'Third entry Id should match.');
  }

  @isTest
  static void testTimes_WhenUsingLowercaseLetterAtIdWithStartAt_ThenReturnConsectiveLowercaseLetterIds() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.class);
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.set('Id', '{a}').times(3, 26); // Start at 'z'

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('00100000000000zAAA', mockEntries[0].getId(), 'First entry Id should match.');
    Assert.areEqual('0010000000000aaAAA', mockEntries[1].getId(), 'Second entry Id should match.');
    Assert.areEqual('0010000000000abAAA', mockEntries[2].getId(), 'Third entry Id should match.');
  }

  @isTest
  static void testGet_WhenApplyNull_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.get(null);
      Assert.fail('Expected ApexEloquentException to be thrown when getting a field with null name.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testGet_WhenApplyEmptyString_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class);
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.get('');
      Assert.fail('Expected ApexEloquentException to be thrown when getting a field with empty string name.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testGet_WhenFieldExists_ThenReturnFieldValue() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class).autoId(1).set('Name', 'Test Account');
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    Object fieldValue = mockEntry.get('Name');

    // Assert
    Assert.areEqual('Test Account', fieldValue, 'The field value should match the expected, value.');
  }

  @isTest
  static void testGet_WhenScriceDoesNotSelectField_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .fields(new List<String>{ 'id' })
      .buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.class).autoId(1).set('Name', 'Test Account');
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.get('Name');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGet_WhenWithoutFieldValidation_ThenNotThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class); // No fields are selected in Scribe
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);
    mockEntry = (MockEntry) MockEntry.withoutFieldValidation();

    // Act & Assert
    try {
      String recordName = mockEntry.getName();
      Assert.areEqual('Test Account', recordName, 'The field value should be returned without field validation.');
    } catch (ApexEloquentException e) {
      Assert.fail('ApexEloquentException should not be thrown when field validation is disabled.');
    }
  }

  @isTest
  static void testGet_WhenFieldValueIsOverride_ThenReturnOverrideValue() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'id', 'name' });
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
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'avgAmount' => 1500 };
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      Id oppId = (Id) mockEntry.get('Id'); // id field is not exist in aggregate field structure
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGet_WhenGetNotExistAliasInAggregateScribe_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'avgAmount' => 1500, 'maxAmount' => 2000 };
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      Object fieldValue = mockEntry.get('maxAmount'); // 'maxAmount' field is not exist in aggregate field structure
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGet_WhenGetNotExistAliasInAggregateScribeWithoutFieldValidation_ThenNotThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'avgAmount' => 1500, 'maxAmount' => 2000 };
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);
    mockEntry = (MockEntry) MockEntry.withoutFieldValidation();

    // Act & Assert
    try {
      Object fieldValue = mockEntry.get('maxAmount'); // 'maxAmount' field is not exist in aggregate field structure
      Assert.areEqual(
        2000,
        fieldValue,
        'The field value should match the value in fieldToValue when field validation is disabled.'
      );
    } catch (ApexEloquentException e) {
      Assert.fail('ApexEloquentException should not be thrown when field validation is disabled.');
    }
  }

  @isTest
  static void testGet_WhenGetNotExistFieldInFieldToValue_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
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
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGet_WhenGetNotExistAliasInFieldToValue_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
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
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGet_WhenGetExistFieldAndAliasInFieldToValue_ThenReturnValue() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
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
  static void testPut_WhenPutFieldValue_ThenGetFieldValue() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .setFieldStructure(fieldStructure);

    // Act
    mockEntry.put('Name', 'Updated Account Name');
    Object fieldValue = mockEntry.get('Name');

    // Assert
    Assert.areEqual('Updated Account Name', fieldValue, 'The field value should match the updated value.');
  }

  @isTest
  static void testPut_WhenPutNonSelectedField_ThenCanGetFieldValue() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class).autoId(1).setFieldStructure(fieldStructure);

    // Act
    mockEntry.put('Industry', 'Technology'); // 'Industry' is not selected in Scribe
    Object fieldValue = mockEntry.get('Industry');

    // Assert
    Assert.areEqual('Technology', fieldValue, 'The field value should match the put value.');
  }

  @isTest
  static void testPut_WhenPutNonExistField_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Name').buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class).autoId(1).setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.put('NonExistField', 'Some Value'); // 'NonExistField' does not exist in Account
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('put(String fieldName, Object value)'));
      Assert.isTrue(errorMessage.contains('provided arguments are Invalid'));
    }
  }

  @isTest
  static void testPut_WhenPutNonEditableField_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class).field('Id').buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class).autoId(1).setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.put('LastModifiedById', '005000000000AAA');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('put(String fieldName, Object value)'));
      Assert.isTrue(errorMessage.contains('provided arguments are Invalid'));
    }
  }

  @isTest
  static void testPut_WhenPutAggregateResult_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'avgAmount')
      .groupByField('StageName');
    String soql = scribe.toSoql(); // for generate aggregate field structure
    FieldStructure fieldStructure = scribe.buildAggregateFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{ 'avgAmount' => 1500 };
    MockEntry mockEntry = new MockEntry(null, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      mockEntry.put('avgAmount', 2000); // Cannot put value to aggregate result
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('put(String fieldName, Object value)'));
      Assert.isTrue(errorMessage.contains('Invalid operation'));
    }
  }

  @isTest
  static void testGetId_WhenCalled_ThenReturnId() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'id', 'name' });
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
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'name' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      mockEntry.getId();
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getId()'));
      Assert.isTrue(errorMessage.contains('Add the Id field to the Scribe definition for this object'));
    }
  }

  @isTest
  static void testGetId_WhenIdFieldDoesNotSelectedWithoutFieldValidation_ThenNotThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'name' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);
    mockEntry = (MockEntry) MockEntry.withoutFieldValidation();

    // Act
    Id id = mockEntry.getId();

    // Assert
    Assert.areEqual(
      '001000000000000',
      id,
      'The Id should match the expected value even when field validation is disabled.'
    );
  }

  @isTest
  static void testGetName_WhenCalled_ThenReturnName() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'id', 'name' });
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
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'id' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      mockEntry.getName();
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getName()'));
      Assert.isTrue(errorMessage.contains('Add the Name field to the Scribe definition for this object'));
    }
  }

  @isTest
  static void testGetName_WhenNameFieldDoesNotSelectedWithoutFieldValidation_ThenNotThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'id' });
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);
    mockEntry = (MockEntry) MockEntry.withoutFieldValidation();

    // Act
    String name = mockEntry.getName();

    // Assert
    Assert.areEqual(
      'Test Account',
      name,
      'The Name should match the expected value even when field validation is disabled.'
    );
  }

  @isTest
  static void testGetRecord_WhenCalled_ThenReturnRecord() {
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .setFieldStructure(fieldStructure);

    // Act
    Account acc = (Account) mockEntry.getRecord();

    // Assert
    Assert.areEqual('001000000000001AAA', acc.Id, 'The Id should match the expected value.');
    Assert.areEqual('Test Account', acc.Name, 'The Name should match the expected value');
  }

  @isTest
  static void testGetRecord_WhenAddNonExistFieldValueWithoutSObjectFieldValidation_ThenIgnoreNonExistField() {
    // Arrange: post-issue_40, set() of a non-existent field throws by default.
    // To still document the "ignored at getRecord" behavior when the user has
    // intentionally opted out, call withoutSObjectFieldValidation() first.
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class)
      .withoutSObjectFieldValidation()
      .autoId(1)
      .set('Name', 'Test Account')
      .set('NonExistField', 'Some Value') // 'NonExistField' does not exist on Account; allowed because opted out
      .setFieldStructure(fieldStructure);

    // Act
    Account acc = (Account) mockEntry.getRecord();

    // Assert
    Assert.areEqual('001000000000001AAA', acc.Id, 'The Id should match the expected value.');
    Assert.areEqual('Test Account', acc.Name, 'The Name should match the expected value');
    // NonExistField is ignored at getRecord() time
  }

  @isTest
  static void testGetRecord_WhenMutatedExternally_ThenInternalRecordIsUnchanged() {
    // Defensive-copy regression: mutating the returned SObject must not leak into the cached internal record.
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Original')
      .setFieldStructure(fieldStructure);

    // Act
    Account first = (Account) mockEntry.getRecord();
    first.Name = 'Mutated By Caller';
    Account second = (Account) mockEntry.getRecord();

    // Assert
    Assert.areEqual('Original', second.Name, 'Mutating the returned SObject must not affect a subsequent getRecord() call');
    Assert.areNotEqual(first, second, 'Each getRecord() call should return a distinct SObject instance');
  }

  @isTest
  static void testGetRecord_WhenCalledMultipleTimes_ThenInternalStateNotAccumulated() {
    // Regression: MockEntry used to alias this.record and put() into it, so repeated calls
    // accumulated fieldToValue overrides into the internal record. Verify that does not happen.
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Override Name')
      .setFieldStructure(fieldStructure);

    // Act — call multiple times, each from a clean internal state
    Account first = (Account) mockEntry.getRecord();
    Account second = (Account) mockEntry.getRecord();
    Account third = (Account) mockEntry.getRecord();

    // Assert — every call returns the same overridden value (Apex SObject equality is value-based,
    // so identity-distinctness is not assertable here; we verify it indirectly via the mutation test above).
    Assert.areEqual('Override Name', first.Name, 'first call should return overridden Name');
    Assert.areEqual('Override Name', second.Name, 'second call should return the same overridden Name');
    Assert.areEqual('Override Name', third.Name, 'third call should return the same overridden Name');
  }

  @isTest
  static void testGetRecord_WhenSettingFormulaField_ThenFormulaValueIsApplied() {
    // Regression: SObject.put() rejects formula fields. JSON round-trip should allow it.
    // Arrange
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .fields(new List<String>{ 'id', 'name', 'isclosed' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class)
      .autoId(1)
      .set('Name', 'Test Opp')
      .set('IsClosed', true) // formula field — normally read-only via put()
      .setFieldStructure(fieldStructure);

    // Act
    Opportunity opp = (Opportunity) mockEntry.getRecord();

    // Assert
    Assert.areEqual('Test Opp', opp.Name, 'Name should be set');
    Assert.areEqual(true, opp.IsClosed, 'formula field IsClosed should be set via JSON round-trip');
  }

  @isTest
  static void testGetRecord_WhenSettingAuditField_ThenAuditValueIsApplied() {
    // Regression: SObject.put() rejects audit fields (CreatedDate etc.). JSON round-trip should allow it.
    // Arrange
    Datetime fixedCreated = Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0);
    FieldStructure fieldStructure = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name', 'createddate' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Audit Test')
      .set('CreatedDate', fixedCreated) // audit field — normally read-only via put()
      .setFieldStructure(fieldStructure);

    // Act
    Account acc = (Account) mockEntry.getRecord();

    // Assert
    Assert.areEqual('Audit Test', acc.Name, 'Name should be set');
    Assert.areEqual(fixedCreated, acc.CreatedDate, 'audit field CreatedDate should be set via JSON round-trip');
  }

  @isTest
  static void testGetRecord_WhenSetParentOnly_ThenIdFieldStaysNull() {
    // Relationship overrides (set via setParent) must NOT leak into the flat SObject.
    // Callers expect to navigate via getParent() to access the parent IEntry.
    // Arrange
    MockEntry mockAccount = (MockEntry) MockEntry.of(Account.class).autoId(1).set('Name', 'Parent Acc');
    FieldStructure fieldStructure = Scribe.of(Opportunity.class)
      .fields(new List<String>{ 'id', 'name' })
      .buildFieldStructure();
    MockEntry mockOpp = (MockEntry) MockEntry.of(Opportunity.class)
      .autoId(1)
      .set('Name', 'Test Opp')
      .setParent('AccountId', mockAccount) // relationship — should not flatten into AccountId field
      .setFieldStructure(fieldStructure);

    // Act
    Opportunity opp = (Opportunity) mockOpp.getRecord();

    // Assert
    Assert.areEqual('Test Opp', opp.Name, 'Name should be set');
    Assert.isNull(opp.AccountId, 'AccountId should NOT be auto-populated from a setParent-only call');
  }

  // ====== asAggregateResult factory ======

  @isTest
  static void testAsAggregateResult_WhenNoArg_ThenReturnsEmptyAggregateResultModeMockEntry() {
    // Arrange / Act
    MockEntry agg = MockEntry.asAggregateResult();

    // Assert
    Assert.isTrue(agg.hasAggregateResult, 'should be in AggregateResult mode');
    // Should support chaining via .set()
    MockEntry filled = agg.set('avgAmount', 1500);
    Assert.isTrue(filled.hasAggregateResult, 'chained MockEntry should also be in AggregateResult mode');
  }

  @isTest
  static void testAsAggregateResult_WhenMap_ThenReturnsAggregateResultModeMockEntryWithValues() {
    // Arrange
    Map<String, Object> values = new Map<String, Object>{ 'avgAmount' => 1500, 'countId' => 10 };

    // Act
    MockEntry agg = MockEntry.asAggregateResult(values);

    // Assert
    Assert.isTrue(agg.hasAggregateResult, 'should be in AggregateResult mode');
    // Use skipFieldValidation to bypass the FieldStructure check (mock without Scribe pipeline)
    MockEntry skipped = agg.withoutFieldValidation();
    Assert.areEqual(1500, skipped.get('avgAmount'), 'should return seeded value for avgAmount');
    Assert.areEqual(10, skipped.get('countId'), 'should return seeded value for countId');
  }

  @isTest
  static void testAsAggregateResult_WhenMapIsNull_ThenThrowApexEloquentException() {
    // Arrange
    Map<String, Object> values = null;

    // Act & Assert
    try {
      MockEntry.asAggregateResult(values);
      Assert.fail('Expected ApexEloquentException to be thrown for null fieldToValue');
    } catch (ApexEloquentException e) {
      String msg = e.getMessage();
      Assert.isTrue(msg.contains('MockEntry'), 'should contain class name');
      Assert.isTrue(msg.contains('asAggregateResult'), 'should contain method name');
      Assert.isTrue(msg.contains('fieldToValue'), 'should mention fieldToValue parameter');
      Assert.isTrue(msg.contains('Missing required parameter'), 'should indicate required-parameter violation');
    }
  }

  @isTest
  static void testGetRecord_WhenMockEntryIsAggregateResultMode_ThenThrowApexEloquentException() {
    // Arrange: construct a MockEntry in AggregateResult mode (no SObject record).
    MockEntry mockEntry = MockEntry.asAggregateResult(new Map<String, Object>{ 'avgAmount' => 1500 });

    // Act & Assert
    try {
      mockEntry.getRecord();
      Assert.fail('Expected ApexEloquentException to be thrown for AggregateResult-mode MockEntry');
    } catch (ApexEloquentException e) {
      String msg = e.getMessage();
      Assert.isTrue(msg.contains('MockEntry'), 'should contain class name');
      Assert.isTrue(msg.contains('getRecord()'), 'should contain method name');
      Assert.isTrue(msg.contains('AggregateResult'), 'should mention AggregateResult');
    }
  }

  @isTest
  static void testSetRecord_WhenCalled_ThenReturnNewMockEntry() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class).fields(new List<String>{ 'id', 'name' });
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
    Scribe scribe = Scribe.of(Account.class);
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
  static void testGetParent_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('AccountId')
      .parentField(Scribe.asParent('AccountId').fields(new List<String>{ 'id', 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class).setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      IEntry parentEntry = mockEntry.getParent(null);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getParent(String parentIdFieldName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetParent_WhenApplyEmptyString_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('AccountId')
      .parentField(Scribe.asParent('AccountId').fields(new List<String>{ 'id', 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Opportunity.class).setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      IEntry parentEntry = mockEntry.getParent('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getParent(String parentIdFieldName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetParent_WhenParentNotExist_ThenReturnNull() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    Scribe scribe = Scribe.of(Opportunity.class)
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
    Scribe scribe = Scribe.of(Opportunity.class)
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
    Scribe scribe = Scribe.of(Opportunity.class).field('Id');
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'AccountId' => new MockEntry(new Account(Id = '001000000000001', Name = 'Test Account'))
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      IEntry parentEntry = mockEntry.getParent('AccountId');
      String parentName = parentEntry.getName();
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getParent(String parentIdFieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGetParentAndGet_WhenParentAndFieldIsValid_ThenReturnParentFieldValue() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    Scribe scribe = Scribe.of(Opportunity.class)
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
    String parentName = parentEntry.getName();

    // Assert
    Assert.areEqual('Test Account', parentName, 'The parent name should match the expected value.');
  }

  @isTest
  static void testGetParentAndGet_WhenParentExistButFieldIsNotSelected_ThenThrowException() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .field('Name')
      .parentField(Scribe.asParent('AccountId').fields(new List<String>{ 'Id' })); // Name field is not selected for parent
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'AccountId' => new MockEntry(new Account(Id = '001000000000001', Name = 'Test Account'))
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      IEntry parentEntry = mockEntry.getParent('AccountId');
      String parentName = parentEntry.getName(); // Attempt to get Name field which is not selected in Scribe
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getName()'));
      Assert.isTrue(errorMessage.contains('Add the Name field to the Scribe definition for this object'));
    }
  }

  @isTest
  static void testGetParentAndGet_WhenparentExistButFieldIsNotSelectedWithoutFieldValidation_ThenNotThrowException() {
    // Arrange
    SObject record = new Opportunity(Id = '006000000000000', Name = 'Test Opportunity');
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .field('Name')
      .parentField(Scribe.asParent('AccountId').fields(new List<String>{ 'Id' })); // Name field is not selected for parent
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'AccountId' => new MockEntry(new Account(Id = '001000000000001', Name = 'Test Account'))
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);
    mockEntry = (MockEntry) MockEntry.withoutFieldValidation();

    // Act
    IEntry parentEntry = mockEntry.getParent('AccountId');
    String parentName = parentEntry.getName(); // Attempt to get Name field which is not selected in Scribe

    // Assert
    Assert.areEqual(
      'Test Account',
      parentName,
      'The parent name should match the expected value even when field validation is disabled.'
    );
  }

  @isTest
  static void testGetParent_WhenNestedParentExists_ThenReturnNestedParentEntry() {
    // Arrange
    SObject record = new OrderItem();
    Scribe scribe = Scribe.of(OrderItem.class)
      .fields(new List<String>{ 'Id' })
      .parentField(
        Scribe.asParent('OrderId')
          .fields(new List<String>{ 'Name' })
          .parentField(
            Scribe.asParent('ContractId')
              .fields(new List<String>{ 'Name' })
              .parentField(
                Scribe.asParent('AccountId')
                  .fields(new List<String>{ 'Name' })
                  .parentField(
                    Scribe.asParent('ParentId')
                      .fields(new List<String>{ 'Name' })
                      .parentField(Scribe.asParent('ParentId').fields(new List<String>{ 'Name' }))
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
          'ContractId' => new MockEntry(
            new Contract(Name = 'Test Contract'),
            new Map<String, Object>{
              'AccountId' => new MockEntry(
                new Account(Name = 'Test Account'),
                new Map<String, Object>{
                  'ParentId' => new MockEntry(
                    new Account(Name = 'Parent Account'),
                    new Map<String, Object>{ 'ParentId' => new MockEntry(new Account(Name = 'Grandparent Account')) }
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
    System.debug('get Contract');
    IEntry contractEntry = orderEnrty.getParent('ContractId');
    Assert.isNotNull(contractEntry, 'Contract entry should not be null.');
    Assert.areEqual('Test Contract', contractEntry.getName(), 'Contract name should match.');
    System.debug('get Account');
    IEntry accountEntry = contractEntry.getParent('AccountId');
    Assert.isNotNull(accountEntry, 'Account entry should not be null.');
    Assert.areEqual('Test Account', accountEntry.getName(), 'Account name should match.');
    System.debug('get Parent Account');
    IEntry parentEntry = accountEntry.getParent('ParentId');
    Assert.isNotNull(parentEntry, 'Parent account entry should not be null.');
    Assert.areEqual('Parent Account', parentEntry.getName(), 'Parent account name should match.');
    System.debug('get Grandparent Account');
    IEntry grandparentEntry = parentEntry.getParent('ParentId');
    Assert.isNotNull(grandparentEntry, 'Grandparent account entry should not be null.');
    Assert.areEqual('Grandparent Account', grandparentEntry.getName(), 'Grandparent account name should match.');
  }

  @isTest
  static void testGetChildren_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.class).fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class).setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildren(null);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildren(String childObjectName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetChildren_WhenApplyEmptyString_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.class).fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.class).setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildren('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildren(String childObjectName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetChildren_WhenChildrenExist_ThenReturnChildEntries() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.class).fields(new List<String>{ 'name' }));
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
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.class).fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Contract' => new List<Contract>{ new Contract() }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildren('Contract');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildren(String childObjectName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGetChildren_WhenChildObjectDoesNotExist_ThenReturnEmptyList() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.class).fields(new List<String>{ 'name' }));
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
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(
        Scribe.asChild(Contract.class).fields(new List<String>{ 'id' }) // 'name' field is not selected
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
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getName()'));
      Assert.isTrue(errorMessage.contains('Add the Name field to the Scribe definition for this object'));
    }
  }

  @isTest
  static void testGetChildren_WhenChildObjectFieldDoesNotSelectedWithoutFieldValidation_ThenNotThrowException() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(
        Scribe.asChild(Contract.class).fields(new List<String>{ 'id' }) // 'name' field is not selected
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Contract' => new List<IEntry>{
        new MockEntry(new Contract(Id = '800000000000001', Name = 'Test Contract 1')),
        new MockEntry(new Contract(Id = '800000000000002', Name = 'Test Contract 2'))
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);
    mockEntry = (MockEntry) MockEntry.withoutFieldValidation();

    // Act
    List<IEntry> children = mockEntry.getChildren('Contract');
    String childName1 = children[0].getName();
    String childName2 = children[1].getName();

    // Assert
    Assert.areEqual(
      'Test Contract 1',
      childName1,
      'First child name should match even when field validation is disabled.'
    );
    Assert.areEqual(
      'Test Contract 2',
      childName2,
      'Second child name should match even when field validation is disabled.'
    );
  }

  @isTest
  static void testGetChildren_WhenNestedChildrenExist_ThenReturnNestedChildEntries() {
    // Arrange
    Sobject accountEnery = new Account(Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'name' })
      .withChildren(
        Scribe.asChild(Contract.class)
          .fields(new List<String>{ 'name' })
          .withChildren(
            Scribe.asChild(Opportunity.class)
              .fields(new List<String>{ 'name' })
              .withChildren(
                Scribe.asChild(Order.class)
                  .fields(new List<String>{ 'name' })
                  .withChildren(Scribe.asChild(OrderItem.class).fields(new List<String>{ 'description' }))
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
  static void testGetChildren_WhenChildObjectIsAmbiguous_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(User.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Account.class).fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(User.class)
      .autoId(1)
      .setChildren('Account', MockEntry.of(Account.class).autoId('{#}').times(2));
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildren('Account');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildren(String childObjectName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
      Assert.isTrue(errorMessage.contains('ambiguous'));
    }
  }

  @isTest
  static void testGetChildren_WhenGivenRelationName_ThenFallbackResolveAndReturnChildren() {
    // For a mock built with Scribe.relationName('Contracts') / setChildren('Contracts', ...),
    // calling getChildren('Contracts') (the relationship name, not the SObject name) must work
    // via the fallback path so callers don't have to switch to getChildrenByRelationName.
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.class).relationName('Contracts').fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>{
      'Contracts' => new List<IEntry>{
        new MockEntry(new Contract(), new Map<String, Object>{ 'Name' => 'Test Contract 1' }),
        new MockEntry(new Contract(), new Map<String, Object>{ 'Name' => 'Test Contract 2' })
      }
    };
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act — calling getChildren with the relation name (instead of getChildrenByRelationName)
    List<IEntry> children = mockEntry.getChildren('Contracts');

    // Assert
    Assert.isNotNull(children, 'children should not be null');
    Assert.areEqual(2, children.size(), 'should return both mocked children');
    Assert.areEqual('Test Contract 1', children[0].getName());
    Assert.areEqual('Test Contract 2', children[1].getName());
  }

  @isTest
  static void testGetChildrenByRelationName_WhenRelationNameIsValid_ThenReturnChildEntries() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.class).relationName('Contracts').fields(new List<String>{ 'name' }));
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
    Scribe scribe = Scribe.of(Account.class)
      .fields(new List<String>{ 'id', 'name' })
      .withChildren(Scribe.asChild(Contract.class).relationName('Contract__r').fields(new List<String>{ 'name' }));
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = new MockEntry(record, fieldStructure, fieldToValue);

    // Act & Assert
    try {
      List<IEntry> children = mockEntry.getChildrenByRelationName('Contract__r');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildrenByRelationName(String childRelationName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGetThrough_WhenRelationIsValid_ThenReturnRelatedObject() {
    // Arrange
    SObject record = new Order(Id = '801000000000000', Name = 'Test Account');
    Scribe scribe = Scribe.of(Order.class)
      .fields(new List<String>{ 'id', 'name' })
      .through(Scribe.asThrough(OrderItem.class, 'Product2Id').fields(new List<String>{ 'id', 'name' }));
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
    Scribe scribe = Scribe.of(Order.class)
      .field('Id')
      .through(
        Scribe.asThrough(OrderItem.class, 'Product2Id').relationName('OrderItems').field('Id').field('Name')
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Order.class)
      .setChildren(
        'OrderItems',
        new List<MockEntry>{
          MockEntry.of(OrderItem.class)
            .setParent('Product2Id', MockEntry.of(Product2.class).autoId(1).set('Name', 'Last Modify 1')),
          MockEntry.of(OrderItem.class)
            .setParent('Product2Id', MockEntry.of(Product2.class).autoId(2).set('Name', 'Last Modify 2'))
        }
      );
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    List<IEntry> relatedObjects = mockEntry.getThroughByRelationName('OrderItems', 'Product2Id');

    // Assert
    Assert.isNotNull(relatedObjects, 'Related objects should not be null.');
    Assert.areEqual(2, relatedObjects.size(), 'There should be two related objects.');
    Assert.areEqual('Last Modify 1', relatedObjects[0].getName(), 'First related object name should match.');
    Assert.areEqual('Last Modify 2', relatedObjects[1].getName(), 'Second related object name should match.');
  }

  @isTest
  static void testAlias_WhenSetAlias_ThenNoErrorThrown() {
    // Arrange / Act
    MockEntry mockEntry = MockEntry.of(Account.class).alias('mockAccount').autoId(1).set('Name', 'Test Account');

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should not be null.');
  }

  @isTest
  static void testAlias_WhenApplyNull_ThenThrowException() {
    // Arrange / Act
    try {
      MockEntry mockEntry = MockEntry.of(Account.class).alias(null).autoId(1).set('Name', 'Test Account');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('alias(String alias)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAlias_WhenApplyEmptyString_ThenThrowException() {
    // Arrange / Act
    try {
      MockEntry mockEntry = MockEntry.of(Account.class).alias('').autoId(1).set('Name', 'Test Account');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('alias(String alias)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAlias_WhenSetAliasToChild_ThenNoErrorThrown() {
    // Arrange / Act
    MockEntry mockEntry = MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .setChildren(
        'contacts',
        new List<MockEntry>{
          MockEntry.of(Contact.class).alias('testContact').autoId(1).set('LastName', 'Test Contact')
        }
      );

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should not be null.');
  }

  @isTest
  static void testAlias_WhenSetAliasToParent_ThenNoErrorThrown() {
    // Arrange / Act
    MockEntry mockEntry = MockEntry.of(Contact.class)
      .autoId(1)
      .set('LastName', 'Test Contact')
      .setParent(
        'AccountId',
        MockEntry.of(Account.class).alias('testAccount').autoId(1).set('Name', 'Test Account')
      );

    // Assert
    Assert.isNotNull(mockEntry, 'MockEntry should not be null.');
  }

  @isTest
  static void testGetByAlias_WhenApplyNull_ThenThrowException() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class).alias('mockAccount').autoId(1).set('Name', 'Test Account');

    // Act & Assert
    try {
      MockEntry result = mockEntry.getByAlias(null);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getByAlias(String alias)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetByAlias_WhenApplyEmptyString_ThenThrowException() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class).alias('mockAccount').autoId(1).set('Name', 'Test Account');

    // Act & Assert
    try {
      MockEntry result = mockEntry.getByAlias('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getByAlias(String alias)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetByAlias_WhenAliasExistsInRoot_ThenReturnMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class).alias('mockAccount').autoId(1).set('Name', 'Test Account');

    // Act
    MockEntry result = mockEntry.getByAlias('mockAccount');

    // Assert
    Assert.isNotNull(result, 'Result should not be null.');
    Assert.areEqual('Test Account', result.getName(), 'The Name should match the expected value.');
  }

  @isTest
  static void testGetByAlias_WhenAliasExistsInChild_ThenReturnMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .setChildren(
        'contacts',
        new List<MockEntry>{
          MockEntry.of(Contact.class).alias('testContact').autoId(1).set('LastName', 'Test Contact')
        }
      );

    // Act
    MockEntry result = mockEntry.getByAlias('testContact');

    // Assert
    Assert.isNotNull(result, 'Result should not be null.');
    Assert.areEqual('Test Contact', result.get('LastName'), 'The LastName should match the expected value.');
  }

  @isTest
  static void testGetByAlias_WhenAliasExistsInParalellChildren_ThenReturnFirstMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .setChildren(
        'contacts',
        new List<MockEntry>{
          MockEntry.of(Contact.class).alias('testContact').autoId(1).set('LastName', 'Test Contact 1')
        }
      )
      .setChildren(
        'opportunities',
        new List<MockEntry>{
          MockEntry.of(Opportunity.class).alias('testOpportunity').autoId(3).set('Name', 'Test Opportunity')
        }
      );

    // Act
    MockEntry contactEntry = mockEntry.getByAlias('testContact');
    MockEntry opportunityEntry = mockEntry.getByAlias('testOpportunity');

    // Assert
    Assert.isNotNull(contactEntry, 'Result should not be null.');
    Assert.areEqual(
      'Test Contact 1',
      contactEntry.get('LastName'),
      'The LastName should match the first occurrence of the alias.'
    );
    Assert.isNotNull(opportunityEntry, 'Opportunity entry should not be null.');
    Assert.areEqual('Test Opportunity', opportunityEntry.getName(), 'The Name should match the expected value.');
  }

  @isTest
  static void testGetByAlias_WhenAliasExistsInNestedChild_ThenReturnMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .setChildren(
        'contacts',
        new List<MockEntry>{
          MockEntry.of(Contact.class)
            .autoId(1)
            .set('LastName', 'Test Contact')
            .setChildren(
              'cases',
              new List<MockEntry>{
                MockEntry.of(Case.class).alias('testCase').autoId(1).set('Subject', 'Test Case')
              }
            )
        }
      );

    // Act
    MockEntry result = mockEntry.getByAlias('testCase');

    // Assert
    Assert.isNotNull(result, 'Result should not be null.');
    Assert.areEqual('Test Case', result.get('Subject'), 'The Subject should match the expected value.');
  }

  @isTest
  static void testGetByAlias_WhenAliasExistInChildrenWithTimes_ThenReturnMockEntry() {
    // Arrange
    Integer times = 3;
    MockEntry mockEntry = MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .setChildren(
        'contacts',
        MockEntry.of(Contact.class)
          .alias('testContact_{#}')
          .autoId(1)
          .set('LastName', 'Test Contact {#}')
          .times(times)
      );

    // Act / Assert
    for (Integer i = 1; i <= times; i++) {
      MockEntry result = mockEntry.getByAlias('testContact_' + i);
      Assert.isNotNull(result, 'Result should not be null.');
      Assert.areEqual(
        'Test Contact ' + i,
        result.get('LastName'),
        'The LastName should match the first occurrence of the alias.'
      );
    }
  }

  @isTest
  static void testGetByAlias_WhenAliasExistsInParent_ThenReturnMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Contact.class)
      .autoId(1)
      .set('LastName', 'Test Contact')
      .setParent(
        'AccountId',
        MockEntry.of(Account.class).alias('testAccount').autoId(1).set('Name', 'Test Account')
      );

    // Act
    MockEntry result = mockEntry.getByAlias('testAccount');

    // Assert
    Assert.isNotNull(result, 'Result should not be null.');
    Assert.areEqual('Test Account', result.getName(), 'The Name should match the expected value.');
  }

  @isTest
  static void testGetByAlias_WhenAliasExistsInNestedParent_ThenReturnMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Opportunity.class)
      .autoId(1)
      .set('Name', 'Test Opportunity')
      .setParent(
        'ContractId',
        MockEntry.of(Contract.class)
          .autoId(1)
          .set('Name', 'Test Contract')
          .setParent(
            'AccountId',
            MockEntry.of(Account.class).alias('testParentAccount').autoId(1).set('Name', 'Test Parent Account')
          )
      );

    // Act
    MockEntry result = mockEntry.getByAlias('testParentAccount');

    // Assert
    Assert.isNotNull(result, 'Result should not be null.');
    Assert.areEqual('Test Parent Account', result.getName(), 'The Name should match the expected value.');
  }

  @isTest
  static void TestGetByAlias_WhenAliasExistsInParalellParents_ThenReturnFirstMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Opportunity.class)
      .autoId(1)
      .set('Name', 'Test Opportunity')
      .setParent(
        'ContractId',
        MockEntry.of(Contract.class).alias('testParent').autoId(1).set('Name', 'Test Contract')
      )
      .setParent(
        'AccountId',
        MockEntry.of(Account.class).alias('testParent').autoId(1).set('Name', 'Test Account')
      );

    // Act
    MockEntry contractResult = mockEntry.getByAlias('testParent');
    MockEntry accountResult = mockEntry.getByAlias('testParent');

    // Assert
    Assert.isNotNull(contractResult, 'Contract result should not be null.');
    Assert.areEqual(
      'Test Contract',
      contractResult.getName(),
      'The Name should match the first occurrence of the alias.'
    );
    Assert.isNotNull(accountResult, 'Account result should not be null.');
    Assert.areEqual(
      'Test Contract',
      accountResult.getName(),
      'The Name should match the first occurrence of the alias.'
    );
  }

  @isTest
  static void testGetByAlias_WhenAliasDoesNotExist_ThenThrowException() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class).autoId(1).set('Name', 'Test Account');

    // Act & Assert
    try {
      mockEntry.getByAlias('nonExistingAlias');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('MockEntry.getByAlias(String alias)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGetAliasId_WhenApplyNull_ThenThrowException() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class).alias('mockAccount').autoId(1).set('Name', 'Test Account');

    // Act & Assert
    try {
      Id resultId = mockEntry.getAliasId(null);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getAliasId(String alias)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetAliasId_WhenApplyEmptyString_ThenThrowException() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class).alias('mockAccount').autoId(1).set('Name', 'Test Account');

    // Act & Assert
    try {
      Id resultId = mockEntry.getAliasId('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getAliasId(String alias)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetAliasId_WhenAliasExists_ThenReturnId() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class).alias('testAccount').autoId(123).set('Name', 'Test Account');

    // Act
    Id resultId = mockEntry.getAliasId('testAccount');

    // Assert
    Assert.isNotNull(resultId, 'Result ID should not be null.');
    String idString = String.valueOf(resultId);
    Assert.isTrue(idString.contains('123'), 'Result ID should contain the expected value.');
  }

  @isTest
  static void testGetAliasId_WhenAliasInNestedChild_ThenReturnId() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class)
      .autoId(1)
      .set('Name', 'Test Account')
      .setChildren(
        'contacts',
        new List<MockEntry>{
          MockEntry.of(Contact.class)
            .autoId(1)
            .set('LastName', 'Test Contact')
            .setChildren(
              'cases',
              new List<MockEntry>{
                MockEntry.of(Case.class).alias('testCase').autoId(123).set('Subject', 'Test Case')
              }
            )
        }
      );

    // Act
    Id resultId = mockEntry.getAliasId('testCase');

    // Assert
    Assert.isNotNull(resultId, 'Result ID should not be null.');
    String idString = String.valueOf(resultId);
    Assert.isTrue(idString.contains('123'), 'Result ID should contain the expected value.');
  }

  @isTest
  static void testGetAliasId_WhenAliasInNestedParent_ThenReturnId() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Opportunity.class)
      .autoId(1)
      .set('Name', 'Test Opportunity')
      .setParent(
        'ContractId',
        MockEntry.of(Contract.class)
          .autoId(1)
          .set('Name', 'Test Contract')
          .setParent(
            'AccountId',
            MockEntry.of(Account.class).alias('testParentAccount').autoId(123).set('Name', 'Test Parent Account')
          )
      );

    // Act
    Id resultId = mockEntry.getAliasId('testParentAccount');

    // Assert
    Assert.isNotNull(resultId, 'Result ID should not be null.');
    String idString = String.valueOf(resultId);
    Assert.isTrue(idString.contains('123'), 'Result ID should contain the expected value.');
  }

  @isTest
  static void testGetAliasId_WhenAliasDoesNotExist_ThenThrowException() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.class).autoId(1).set('Name', 'Test Account');

    // Act & Assert
    try {
      mockEntry.getAliasId('nonExistingAlias');
      Assert.fail('Expected ApexEloquentException  to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('MockEntry.getAliasId(String alias)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  // ===========================================================================
  // SObject field-name typo detection at write time (issue_40)
  // ===========================================================================
  //
  // 設計メモ:
  // - 本番経路は既に Scribe.buildFieldStructure / Entry.validateFieldName で
  //   タイポが弾かれる。本物のバグはここではなく「MockEntry のセットアップで
  //   タイポしたフィールド名が fieldToValue に静かに格納され、SUT が正しい
  //   名前で get したら値が見つからず null 経路に流れて挙動が変わる」 という
  //   silent な mock 不整合。
  // - 対策として set / add / setParent / addParent の write 時点で
  //   SObject metadata に照らして fieldName をチェックする。
  // - エスケープは独立フラグ withoutSObjectFieldValidation()。既存の
  //   withoutFieldValidation() (Scribe FieldStructure 用) と混ぜると
  //   Scribe を緩めた瞬間にタイポも素通りするので、わざと別に分けている。

  @isTest
  static void testSet_WhenFieldNameIsTypo_ThenThrowException() {
    // Arrange & Act & Assert: this is the core scenario — a typo in mock
    // setup silently sat in fieldToValue before; now it surfaces immediately.
    try {
      MockEntry.of(Account.class).set('Naame', 'foo');
      Assert.fail('Expected ApexEloquentException for typo field name on set.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('Naame'), 'Error should mention the typo: ' + errorMessage);
      Assert.isTrue(errorMessage.contains('Account'), 'Error should mention the SObject: ' + errorMessage);
      Assert.isTrue(
        errorMessage.contains('set(String fieldName, Object value)'),
        'Error should mention the set method: ' + errorMessage
      );
    }
  }

  @isTest
  static void testSet_WhenFieldNameIsCorrect_ThenStoresValue() {
    // Arrange & Act
    MockEntry mock = (MockEntry) MockEntry.of(Account.class).set('Name', 'Acme').withoutFieldValidation();

    // Assert: read it back through the (Scribe-relaxed) get path to confirm storage
    Assert.areEqual('Acme', mock.get('Name'));
  }

  @isTest
  static void testSet_WhenFieldNameIsCaseInsensitive_ThenStoresValue() {
    // Arrange & Act: lowercase / uppercase / mixed all map to the same real field
    MockEntry mock = (MockEntry) MockEntry.of(Account.class).set('NAME', 'Acme').withoutFieldValidation();

    // Assert
    Assert.areEqual('Acme', mock.get('NAME'));
  }

  @isTest
  static void testSet_WhenFieldNameIsStandardLongField_ThenStoresValue() {
    // Arrange & Act: confirms the fieldMap includes more than just Id/Name
    MockEntry mock = (MockEntry) MockEntry.of(Account.class)
      .set('Description', 'long description')
      .withoutFieldValidation();

    // Assert
    Assert.areEqual('long description', mock.get('Description'));
  }

  @isTest
  static void testAdd_WhenFieldNameIsTypo_ThenThrowException() {
    try {
      MockEntry.of(Account.class).add('Naame', 'foo');
      Assert.fail('Expected ApexEloquentException for typo field name on add.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('Naame'), 'Error should mention the typo: ' + errorMessage);
      Assert.isTrue(
        errorMessage.contains('add(String fieldName, Object value)'),
        'Error should mention the add method: ' + errorMessage
      );
    }
  }

  @isTest
  static void testAdd_WhenFieldNameIsCorrect_ThenStoresValue() {
    MockEntry mock = (MockEntry) MockEntry.of(Account.class).add('Name', 'Acme').withoutFieldValidation();
    Assert.areEqual('Acme', mock.get('Name'));
  }

  @isTest
  static void testSetParent_WhenParentIdFieldNameIsTypo_ThenThrowException() {
    MockEntry parent = (MockEntry) MockEntry.of(Account.class).autoId(1).set('Name', 'Parent');
    try {
      MockEntry.of(Contact.class).setParent('AccountIddd', parent);
      Assert.fail('Expected ApexEloquentException for typo parentIdFieldName.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('AccountIddd'), 'Error should mention the typo: ' + errorMessage);
      Assert.isTrue(errorMessage.contains('Contact'), 'Error should mention the SObject: ' + errorMessage);
    }
  }

  @isTest
  static void testSetParent_WhenParentIdFieldNameIsCorrect_ThenStoresParent() {
    MockEntry parent = (MockEntry) MockEntry.of(Account.class).autoId(1).set('Name', 'Parent Acme');
    MockEntry child = (MockEntry) MockEntry.of(Contact.class)
      .setParent('AccountId', parent)
      .withoutFieldValidation();

    Assert.areEqual('Parent Acme', child.getParent('AccountId').get('Name'));
  }

  @isTest
  static void testAddParent_WhenParentIdFieldNameIsTypo_ThenThrowException() {
    MockEntry parent = (MockEntry) MockEntry.of(Account.class).autoId(1).set('Name', 'Parent');
    try {
      MockEntry.of(Contact.class).addParent('AccountIddd', parent);
      Assert.fail('Expected ApexEloquentException for typo parentIdFieldName.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('AccountIddd'), 'Error should mention the typo: ' + errorMessage);
      Assert.isTrue(
        errorMessage.contains('addParent(String parentIdFieldName, MockEntry parent)'),
        'Error should mention the addParent method: ' + errorMessage
      );
    }
  }

  @isTest
  static void testSet_WhenWithoutSObjectFieldValidation_ThenAcceptsTypo() {
    // Escape hatch: explicit opt-out must allow synthetic field names.
    MockEntry mock = (MockEntry) MockEntry.of(Account.class)
      .withoutSObjectFieldValidation()
      .set('Naame', 'foo')
      .withoutFieldValidation();

    Assert.areEqual('foo', mock.get('Naame'));
  }

  @isTest
  static void testSetParent_WhenWithoutSObjectFieldValidation_ThenAcceptsTypo() {
    MockEntry parent = (MockEntry) MockEntry.of(Account.class).autoId(1).set('Name', 'Parent');
    // Should NOT throw despite the typo
    MockEntry child = (MockEntry) MockEntry.of(Contact.class)
      .withoutSObjectFieldValidation()
      .setParent('AccountIddd', parent);

    Assert.areEqual('AccountIddd', 'AccountIddd', 'setup did not throw — escape hatch worked');
    // (We cannot read back via getParent because that path also requires a
    // FieldStructure with the typo'd relation; the storage step is what matters here.)
  }

  @isTest
  static void testWithoutFieldValidationAlone_DoesNotSkipSObjectCheck() {
    // Why this matters: the two flags are intentionally independent. Loosening
    // the Scribe (FieldStructure) check via withoutFieldValidation() must NOT
    // re-open the SObject typo hole this issue is closing.
    try {
      MockEntry.of(Account.class).withoutFieldValidation().set('Naame', 'foo');
      Assert.fail('withoutFieldValidation() alone should NOT bypass SObject metadata check.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('Naame'), 'Error should mention the typo.');
    }
  }

  @isTest
  static void testSet_WhenAggregateResultMode_ThenSkipSObjectCheck() {
    // AggregateResult mode has record=null; there is no SObjectType to validate
    // against, so set must remain lenient (no throw).
    MockEntry mock = (MockEntry) new MockEntry(new Map<String, Object>{ 'aliasA' => 1 })
      .set('aliasB', 2);

    Assert.isNotNull(mock, 'set on AggregateResult-mode MockEntry should not throw.');
  }

  @isTest
  static void testSet_WhenMultipleSObjectTypesUsedAcrossEntries_ThenEachValidatedAgainstOwnFieldMap() {
    // Cache key isolation: same Email field is valid on Contact, invalid on Account
    MockEntry contactMock = (MockEntry) MockEntry.of(Contact.class).set('Email', 'a@b.com');
    Assert.isNotNull(contactMock, 'Contact.Email set should succeed.');

    try {
      MockEntry.of(Account.class).set('Email', 'will-fail');
      Assert.fail('Account does not have an Email field — should have thrown.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('Email'), 'Error should mention Email field.');
      Assert.isTrue(e.getMessage().contains('Account'), 'Error should mention Account SObject.');
    }
  }

  // ===============================================================================
  // fetchedBy: bake a Scribe's SELECT contract into a directly-injected entry (issue #48)
  // ===============================================================================

  @isTest
  static void testFetchedBy_WhenFieldInContract_ThenReadable() {
    // Arrange - the same Scribe a Batchable's start() would use
    Scribe scope = Scribe.of(Account.class).field('Id').field('Name');
    MockEntry entry = MockEntry.of(Account.class).autoId(1).set('Name', 'Acme').fetchedBy(scope);

    // Act & Assert
    Assert.areEqual('Acme', entry.get('Name'));
  }

  @isTest
  static void testFetchedBy_WhenFieldOutsideContract_ThenThrows() {
    // Arrange - Industry is set on the mock but NOT selected by the Scribe
    Scribe scope = Scribe.of(Account.class).field('Id').field('Name');
    MockEntry entry = MockEntry.of(Account.class).autoId(1).set('Industry', 'Tech').fetchedBy(scope);

    // Act & Assert - reads outside the contract fail like a real query result would
    try {
      entry.get('Industry');
      Assert.fail('Expected ApexEloquentException for a field outside the SELECT contract');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('Industry'), e.getMessage());
    }
  }

  @isTest
  static void testFetchedBy_WhenParentRelationInContract_ThenParentReadable() {
    // Arrange - the contract includes the parent relation, so getParent round-trips
    Scribe scope = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name'));
    MockEntry entry = MockEntry.of(Opportunity.class)
      .autoId(1)
      .setParent('AccountId', MockEntry.of(Account.class).set('Name', 'Parent Co.'))
      .fetchedBy(scope);

    // Act & Assert
    Assert.areEqual('Parent Co.', entry.getParent('AccountId').get('Name'));
  }

  @isTest
  static void testFetchedBy_WhenParentRelationOutsideContract_ThenThrows() {
    // Arrange - the contract has no parent relation at all
    Scribe scope = Scribe.of(Opportunity.class).field('Id');
    MockEntry entry = MockEntry.of(Opportunity.class)
      .autoId(1)
      .setParent('AccountId', MockEntry.of(Account.class).set('Name', 'Parent Co.'))
      .fetchedBy(scope);

    // Act & Assert
    try {
      entry.getParent('AccountId');
      Assert.fail('Expected ApexEloquentException for a relation outside the SELECT contract');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('AccountId'), e.getMessage());
    }
  }

  @isTest
  static void testFetchedBy_WhenScribeIsNull_ThenThrowsRequired() {
    // Act & Assert
    try {
      MockEntry.of(Account.class).fetchedBy(null);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The `scribe` argument is required'), e.getMessage());
    }
  }
}
