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
  static void testOf_WhenAddSobjectType_ThenReturnMockEntry() {
    // Arrange
    MockEntry mockEntry = MockEntry.of(Account.getSObjectType());

    // Act & Assert
    Assert.isNotNull(mockEntry, 'MockEntry should be created successfully using of() method.');
  }

  @isTest
  static void testAdd_WhenAddFieldAndValue_ThenGetFieldValue() {
    // Arrange
    FieldStructure fieldStructure = scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.getSObjectType());
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    mockEntry = mockEntry.add('Name', 'Mock Account');

    // Assert
    String accountName = mockEntry.getName();
    Assert.areEqual('Mock Account', accountName, 'The Name should match the added value.');
  }

  @isTest
  static void testAddChildren_WhenAddChildren_ThenGetChildren() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType())
      .withChildren(Scribe.asChild(Contract.getSObjectType()).field('Name'))
      .buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.getSObjectType())
      .addChildren(
        'Contract',
        new List<MockEntry>{
          MockEntry.of(Contract.getSObjectType()).add('Name', 'Mock Contract 1'),
          MockEntry.of(Contract.getSObjectType()).add('Name', 'Mock Contract 2')
        }
      );
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
  static void testAddParent_WhenAddParent_ThenGetParent() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Opportunity.getSObjectType())
      .parentField(Scribe.asParent('AccountId').field('Name'))
      .buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Opportunity.getSObjectType())
      .addParent('AccountId', MockEntry.of(Account.getSObjectType()).add('Name', 'Mock Account'));
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    IEntry parent = mockEntry.getParent('AccountId');

    // Assert
    Assert.isNotNull(parent, 'Parent should not be null.');
    Assert.areEqual('Mock Account', parent.getName(), 'Parent name should match.');
  }

  @isTest
  static void testAutoId_WhenUsingAutoId_ThenGenerateId() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.getSObjectType());
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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.getSObjectType());
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act
    mockEntry = mockEntry.autoId(123);

    // Assert
    String accountId = mockEntry.getId();
    Assert.areEqual('001000000000123AAA', accountId, 'The Id should match the auto-generated value.');
  }

  @isTest
  static void testAutoId_WhenUsingAutoIdWithMinusInteger_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Account.getSObjectType());
    mockEntry = (MockEntry) mockEntry.setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry = mockEntry.autoId(-1);
      Assert.fail('Expected IllegalArgumentException to be thrown.');
    } catch (IllegalArgumentException e) {
      Assert.areEqual('suffix must be greater than or equal to 0', e.getMessage());
    }
  }

  @isTest
  static void testTimes_WhenAddNameTimes_ThenReturnMockEntriesWithNameTimes() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Name', 'Name-{#}').times(3);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('Name-1', mockEntries[0].getName(), 'First entry name should match.');
    Assert.areEqual('Name-2', mockEntries[1].getName(), 'Second entry name should match.');
    Assert.areEqual('Name-3', mockEntries[2].getName(), 'Third entry name should match.');
  }

  @isTest
  static void testTimes_WhenAddNameTimesWithStartAt_ThenReturnMockEntriesWithNameTimes() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Name', 'Name-{#}').times(3, 5);

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('Name-5', mockEntries[0].getName(), 'First entry name should match.');
    Assert.areEqual('Name-6', mockEntries[1].getName(), 'Second entry name should match.');
    Assert.areEqual('Name-7', mockEntries[2].getName(), 'Third entry name should match.');
  }

  @isTest
  static void testTimes_WhenAddAmountTimesWithStartAt_ThenReturnMOckEntriesWithAmountTimes() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(OrderItem.getSObjectType())
      .field('Quantity')
      .buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(OrderItem.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Quantity', '{#}').times(3, 50000, 10000);

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Id', '{#}').times(3, 1);

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Id', '{#}').times(3, 101);

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Name', 'Name-{A}').times(3);

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Name', 'Name-{A}').times(3, 26); // Start at 'Z'

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Id', '{A}').times(3);

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Id', '{A}').times(3, 26); // Start at 'Z'

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Name', 'Name-{a}').times(3);

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Name', 'Name-{a}').times(3, 26); // Start at 'z'

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Id', '{a}').times(3);

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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry templateEntry = MockEntry.of(Account.getSObjectType());
    templateEntry = (MockEntry) templateEntry.setFieldStructure(fieldStructure);

    // Act
    List<MockEntry> mockEntries = templateEntry.add('Id', '{a}').times(3, 26); // Start at 'z'

    // Assert
    Assert.isNotNull(mockEntries, 'MockEntries should not be null.');
    Assert.areEqual(3, mockEntries.size(), 'There should be three mock entries.');
    Assert.areEqual('00100000000000zAAA', mockEntries[0].getId(), 'First entry Id should match.');
    Assert.areEqual('0010000000000aaAAA', mockEntries[1].getId(), 'Second entry Id should match.');
    Assert.areEqual('0010000000000abAAA', mockEntries[2].getId(), 'Third entry Id should match.');
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
  static void testPut_WhenPutFieldValue_ThenGetFieldValue() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType())
      .fields(new List<String>{ 'id', 'name' })
      .buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.getSObjectType())
      .autoId(1)
      .add('Name', 'Test Account')
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
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.getSObjectType())
      .autoId(1)
      .setFieldStructure(fieldStructure);

    // Act
    mockEntry.put('Industry', 'Technology'); // 'Industry' is not selected in Scribe
    Object fieldValue = mockEntry.get('Industry');

    // Assert
    Assert.areEqual('Technology', fieldValue, 'The field value should match the put value.');
  }

  @isTest
  static void testPut_WhenPutNonExistField_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Name').buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.getSObjectType())
      .autoId(1)
      .setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.put('NonExistField', 'Some Value'); // 'NonExistField' does not exist in Account
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.isTrue(
        e.getMessage().contains('Failed to put value to the SObject. field name: NonExistField, value: Some Value')
      );
    }
  }

  @isTest
  static void testPut_WhenPutNonEditableField_ThenThrowException() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).field('Id').buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.getSObjectType())
      .autoId(1)
      .setFieldStructure(fieldStructure);

    // Act & Assert
    try {
      mockEntry.put('LastModifiedById', '005000000000AAA');
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      System.debug(e.getMessage());
      Assert.isTrue(
        e.getMessage()
          .contains('Failed to put value to the SObject. field name: LastModifiedById, value: 005000000000AAA')
      );
    }
  }

  @isTest
  static void testPut_WhenPutAggregateResult_ThenThrowException() {
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
      mockEntry.put('avgAmount', 2000); // Cannot put value to aggregate result
      Assert.fail('Expected QueryException to be thrown.');
    } catch (QueryException e) {
      Assert.areEqual('Cannot call put() on an AggregateResult record.', e.getMessage());
    }
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
  static void testGetRecord_WhenCalled_ThenReturnRecord() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id', 'name' }).buildFieldStructure();
    Map<String, Object> fieldToValue = new Map<String, Object>();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.getSObjectType())
      .autoId(1)
      .add('Name', 'Test Account')
      .setFieldStructure(fieldStructure);

    // Act
    Account acc = (Account) mockEntry.getRecord();

    // Assert
    Assert.areEqual('001000000000001AAA', acc.Id, 'The Id should match the expected value.');
    Assert.areEqual('Test Account', acc.Name, 'The Name should match the expected value');
  }

  @isTest
  static void testGetRecord_WhenAddNonExistFieldValue_ThenIgnoreNonExistField() {
    // Arrange
    FieldStructure fieldStructure = Scribe.source(Account.getSObjectType()).fields(new List<String>{ 'id', 'name' }).buildFieldStructure();
    MockEntry mockEntry = (MockEntry) MockEntry.of(Account.getSObjectType())
      .autoId(1)
      .add('Name', 'Test Account')
      .add('NonExistField', 'Some Value') // 'NonExistField' does not exist in Account
      .setFieldStructure(fieldStructure);

    // Act
    Account acc = (Account) mockEntry.getRecord();

    // Assert
    Assert.areEqual('001000000000001AAA', acc.Id, 'The Id should match the expected value.');
    Assert.areEqual('Test Account', acc.Name, 'The Name should match the expected value');
    // NonExistField is ignored
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
    Scribe scribe = Scribe.source(Order.getSObjectType())
      .field('Id')
      .through(
        Scribe.asThrough(OrderItem.getSObjectType(), 'Product2Id')
          .relationName('OrderItems')
          .field('Id')
          .field('Name')
      );
    FieldStructure fieldStructure = scribe.buildFieldStructure();
    MockEntry mockEntry = MockEntry.of(Order.getSObjectType())
      .addChildren(
        'OrderItems',
        new List<MockEntry>{
          MockEntry.of(OrderItem.getSObjectType())
            .addParent(
              'Product2Id',
              MockEntry.of(Product2.getSObjectType()).autoId(1).add('Name', 'Last Modify 1')
            ),
          MockEntry.of(OrderItem.getSObjectType())
            .addParent(
              'Product2Id',
              MockEntry.of(Product2.getSObjectType()).autoId(2).add('Name', 'Last Modify 2')
            )
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
}
