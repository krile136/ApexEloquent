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
 * @directory ApexEloquent/Entries/tests
 */
@isTest
public with sharing class EntryTest {
  @isTest
  static void testGet_WhenApplyNull_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.get(null);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGet_WhenApplyEmptyString_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.get('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGet_WhenFieldExists_ShouldReturnFieldValue() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act
    Object fieldValue = entry.get('Name');

    // Assert
    Assert.areEqual('Test Account', fieldValue, 'The field value should match the expected value.');
  }

  @isTest
  static void testGet_WhenFieldDoesNotExist_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.get('NonExistentField');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGet_WhenGetUserCount_ThenReutnCountResult() {
    // Arrange
    Scribe scribe = Scribe.of(User.class).field('IsActive').count('Id', 'UserCount').groupByField('IsActive');
    List<IEntry> entries = (new Eloquent()).get(scribe);

    // Act
    Entry entry = (Entry) entries[0];
    Integer count = (Integer) entry.get('UserCount');

    // Assert
    Assert.isTrue(count >= 0, 'The count should be non-negative.');
  }

  @isTest
  static void testGet_WhenGetNonExistAlias_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(User.class).field('IsActive').count('Id', 'UserCount').groupByField('IsActive');
    List<IEntry> entries = (new Eloquent()).get(scribe);
    Entry entry = (Entry) entries[0];

    // Act & Assert
    try {
      entry.get('NonExistAlias');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(String fieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testPut_WhenFieldExists_ShouldUpdateFieldValue() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);
    String newName = 'Updated Account';

    // Act
    entry.put('Name', newName);
    String updatedName = (String) entry.get('Name');

    // Assert
    Assert.areEqual(newName, updatedName, 'The field value should be updated to the new value.');
  }

  @isTest
  static void testPut_WhenFieldDoesNotExist_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);
    String newValue = 'Some Value';

    // Act & Assert
    try {
      entry.put('NonExistentField', newValue);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('put(String fieldName, Object value)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testPut_WhenCalledOnAggregateResult_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(User.class).field('IsActive').count('Id', 'UserCount').groupByField('IsActive');
    List<IEntry> entries = (new Eloquent()).get(scribe);
    Entry entry = (Entry) entries[0];
    String newValue = 'Some Value';

    // Act & Assert
    try {
      entry.put('IsActive', newValue);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('put(String fieldName, Object value)'));
      Assert.isTrue(errorMessage.contains('Invalid operation'));
    }
  }

  @isTest
  static void testGetId_WhenCalled_ShouldReturnId() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act
    Id id = entry.getId();

    // Assert
    Assert.areEqual('001000000000000', id, 'The Id should match the expected value.');
  }

  @isTest
  static void testGetName_WhenCalled_ShouldReturnName() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act
    String name = entry.getName();

    // Assert
    Assert.areEqual('Test Account', name, 'The Name should match the expected value.');
  }

  @isTest
  static void testGetRecord_WhenCalled_ShouldReturnSObject() {
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act
    SObject returnedRecord = entry.getRecord();

    // Assert
    Assert.areEqual(record, returnedRecord, 'The returned SObject should match the original record.');
  }

  @isTest
  static void testGetRecord_WhenEntryIsAggregateResultMode_ThenThrowApexEloquentException() {
    // Arrange: construct an Entry in AggregateResult mode (record == null).
    FieldStructure fieldStructure = Scribe.of(Opportunity.class).buildFieldStructure();
    Entry entry = new Entry((AggregateResult) null, fieldStructure);

    // Act & Assert
    try {
      entry.getRecord();
      Assert.fail('Expected ApexEloquentException to be thrown for AggregateResult-mode Entry');
    } catch (ApexEloquentException e) {
      String msg = e.getMessage();
      Assert.isTrue(msg.contains('Entry'), 'should contain class name');
      Assert.isTrue(msg.contains('getRecord()'), 'should contain method name');
      Assert.isTrue(msg.contains('AggregateResult'), 'should mention AggregateResult');
    }
  }

  @isTest
  static void testGetRecord_WhenMutatedExternally_ThenInternalRecordIsUnchanged() {
    // Defensive-copy regression: mutating the returned SObject must not leak into the cached internal record.
    // Arrange
    SObject record = new Account(Id = '001000000000000', Name = 'Original');
    Entry entry = new Entry(record);

    // Act
    Account first = (Account) entry.getRecord();
    first.Name = 'Mutated By Caller';
    Account second = (Account) entry.getRecord();

    // Assert
    Assert.areEqual('Original', second.Name, 'Mutating the returned SObject must not affect a subsequent getRecord() call');
    Assert.areNotEqual(first, second, 'Each getRecord() call should return a distinct SObject instance');
  }

  @isTest
  static void testGetParent_WhenApplyNull_ThenThrowException() {
    // Arrange
    SObject record = new Opportunity(Name = 'Test Opportunity');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getParent(null);
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
    SObject record = new Opportunity(Name = 'Test Opportunity');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getParent('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getParent(String parentIdFieldName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetParent_WhenParentExists_ShouldReturnParentEntry() {
    // Arrange
    SObject record = new Opportunity(Name = 'Test Opportunity', Id = '006000000000001');
    Account parentAccount = new Account(Name = 'Parent Account', Id = '001000000000001');
    record.putSObject('Account', parentAccount);
    Entry entry = new Entry(record);

    // Act
    IEntry parentEntry = entry.getParent('AccountId');

    // Assert
    Assert.isNotNull(parentEntry, 'The parent entry should not be null when a parent exists.');
    Assert.areEqual(
      parentAccount.Id,
      parentEntry.getId(),
      'The parent entry Id should match the expected parent Id.'
    );
  }

  @isTest
  static void testGetParent_WhenParentIsNull_ThenReturnNull() {
    // Arrange
    SObject record = new Opportunity(Name = 'Test Opportunity');
    Entry entry = new Entry(record);

    // Act
    IEntry parentEntry = entry.getParent('AccountId');

    // Assert
    Assert.isNull(parentEntry, 'The parent entry should be null when no parent exists.');
  }

  @isTest
  static void testGetParent_WhenParentIdFieldDoesNotExist_ThenThrowException() {
    // Arrange
    SObject record = new Opportunity(Name = 'Test Opportunity');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getParent('NonExistentParentIdField');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getParent(String parentIdFieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGetParent_WhenParentIdFieldIsExistButNotReferenceType_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getParent('Name'); // Name is not a reference field
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getParent(String parentIdFieldName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGetChildren_WhenApplyNull_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getChildren(null);
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
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getChildren('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildren(String childObjectName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetChildren_WhenChildrenAreNull_ShouldReturnEmptyList() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act
    List<IEntry> children = entry.getChildren('Contact');

    // Assert
    Assert.isTrue(children.isEmpty(), 'The children list should be empty when no children exist.');
  }

  @isTest
  static void testGetChildren_WhenGivenRelationName_ThenFallbackResolveAndReturnEmptyList() {
    // The argument is a relationship name (`Contacts`), not the SObject name (`Contact`).
    // getChildren should fall back to the relationship-name lookup so callers don't have
    // to switch to getChildrenByRelationName.
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act
    List<IEntry> children = entry.getChildren('Contacts');

    // Assert
    Assert.isTrue(children.isEmpty(), 'should resolve via relation-name fallback and return empty list');
  }

  @isTest
  static void testGetChildren_WhenChildObjectNameDoesNotExist_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getChildren('NonExistentChildObject');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildren(String childObjectName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGetChildrenByRelationName_WhenApplyNull_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getChildrenByRelationName(null);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildrenByRelationName(String childRelationName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetChildrenByRelationName_WhenApplyEmptyString_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getChildrenByRelationName('');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildrenByRelationName(String childRelationName)'));
      Assert.isTrue(errorMessage.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGetChildrenByRelationName_WhenApplyNonExistRelationName_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act & Assert
    try {
      entry.getChildrenByRelationName('NonExistentRelation');
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getChildrenByRelationName(String childRelationName)'));
      Assert.isTrue(errorMessage.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testGetChildrenByRelationName_WhenChildrenAreNull_ShouldReturnEmptyList() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act
    List<IEntry> children = entry.getChildrenByRelationName('Contacts');

    // Assert
    Assert.isTrue(children.isEmpty(), 'The children list should be empty when no children exist.');
  }

  @isTest
  static void testGetRecord_WhenCalled_ThenReturnSObject() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);

    // Act
    SObject returnedRecord = entry.getRecord();

    // Assert
    Assert.areEqual(record, returnedRecord, 'The returned SObject should match the original record.');
  }

  @isTest
  static void testSetRecord_WhenCalled_ThenSetSObject() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);
    SObject newRecord = new Account(Name = 'Updated Account');

    // Act
    IEntry newEntry = entry.setRecord(newRecord);
    SObject returnedRecord = newEntry.getRecord();

    // Assert
    Assert.areEqual(newRecord, returnedRecord, 'The SObject should be updated to the new record.');
  }

  @isTest
  static void testSetFieldStructure_WhenCalled_ThenThrowException() {
    // Arrange
    SObject record = new Account(Name = 'Test Account');
    Entry entry = new Entry(record);
    FieldStructure fieldStructure = new FieldStructure();

    // Act & Assert
    try {
      entry.setFieldStructure(fieldStructure);
      Assert.fail('Expected ApexEloquentException to be thrown.');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('setFieldStructure(FieldStructure fieldStructure)'));
      Assert.isTrue(errorMessage.contains('Invalid operation'));
    }
  }

  // ===============================================================================
  // describeResult: transient serialization safety (issue #68) and the warm-cache
  // NPE in the unknown-field diagnostic (issue #69).
  // The Database.Stateful SerializationException itself cannot be reproduced in
  // test context (synchronous executeBatch skips serialization — measured), so
  // these tests cover the post-deserialization state (describeResult = null) and
  // the diagnostic path; the batch behavior is verified on a real org run (#68).
  // ===============================================================================

  @isTest
  static void testGet_WhenSecondEntryGivenUnknownField_ThenDiagnosisNotNpe() {
    // issue #69: the field map comes from the warm per-type cache, so the second
    // entry never populates describeResult — the unknown-field diagnostic must
    // ensure it instead of dereferencing null
    new Entry(new Account(Name = 'first')).get('Name'); // warms FIELD_MAP_CACHE(Account)
    Entry second = new Entry(new Account(Name = 'second'));

    try {
      second.get('NoSuchField__c');
      Assert.fail('Expected ApexEloquentException for the unknown field');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('NoSuchField__c'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('Account'), 'Error must name the SObject: ' + e.getMessage());
    }
  }

  @isTest
  static void testGet_WhenDescribeResultCleared_ThenFieldErrorStillReadable() {
    // issue #68: simulates the post-deserialization state (transient field = null)
    // with a warm cache — the diagnostic path must re-derive the describe
    new Entry(new Account(Name = 'warm')).get('Name'); // warm FIELD_MAP_CACHE for Account
    Entry entry = new Entry(new Account(Name = 'x'));
    entry.setDescribeResult(null);

    try {
      entry.get('NoSuchField__c');
      Assert.fail('Expected ApexEloquentException for the unknown field');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('NoSuchField__c'), e.getMessage());
      Assert.isTrue(e.getMessage().contains('Account'), 'Error must name the SObject: ' + e.getMessage());
    }
  }

  @isTest
  static void testGetChildren_WhenDescribeResultCleared_ThenRederivedOnDemand() {
    // issue #68: post-deserialization state — relationship resolution must
    // re-derive the describe on demand
    Entry entry = new Entry(new Account(Name = 'x'));
    entry.setDescribeResult(null);

    Assert.areEqual(0, entry.getChildren('Contact').size(), 'Valid child lookup works with a cleared describe.');

    entry.setDescribeResult(null);
    try {
      entry.getChildren('NoSuchChild__c');
      Assert.fail('Expected ApexEloquentException for the unknown child object');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('Account'), 'Error must name the parent SObject: ' + e.getMessage());
    }
  }

}
