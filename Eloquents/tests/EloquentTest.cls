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
public with sharing class EloquentTest {
  @isTest
  static void testUserModeSystemMode_WhenToggled_ThenAccessLevelSwitches() {
    // Arrange
    Eloquent eloquent = new Eloquent();

    // Act & Assert: default is user mode (secure-by-default)
    Assert.areEqual(
      System.AccessLevel.USER_MODE,
      eloquent.accessLevel,
      'Default access mode should be USER_MODE'
    );

    // user -> system
    IEloquent afterSystem = eloquent.systemMode();
    Assert.areEqual(
      System.AccessLevel.SYSTEM_MODE,
      eloquent.accessLevel,
      'systemMode() should switch the access mode to SYSTEM_MODE'
    );
    Assert.areEqual(eloquent, afterSystem, 'systemMode() should be chainable (return the same instance)');

    // system -> user : must switch back
    IEloquent afterUser = eloquent.userMode();
    Assert.areEqual(
      System.AccessLevel.USER_MODE,
      eloquent.accessLevel,
      'userMode() should switch the access mode back to USER_MODE'
    );
    Assert.areEqual(eloquent, afterUser, 'userMode() should be chainable (return the same instance)');

    // toggle once more to confirm it stays re-switchable
    eloquent.systemMode();
    Assert.areEqual(
      System.AccessLevel.SYSTEM_MODE,
      eloquent.accessLevel,
      'systemMode() should switch to SYSTEM_MODE again after a prior userMode()'
    );
  }

  @isTest
  static void testGet_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = null;

    // Act & Assert
    try {
      (new Eloquent()).get(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('get(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testGet_WhenApplyScribe_ThenSuccess() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000');

    // Act
    List<IEntry> oppEntries = (new Eloquent()).get(scribe);

    // Assert
    Assert.isTrue(oppEntries.isEmpty(), 'Expected no records to be returned');
  }

  @isTest
  static void testGet_WhenApplyAggregateScribe_ThenSuccess() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'AvgAmount')
      .groupByField('StageName');

    // Act
    List<IEntry> oppEntries = (new Eloquent()).get(scribe);

    // Assert
    Assert.isTrue(oppEntries.isEmpty(), 'Expected no records to be returned');
  }

  @isTest
  static void testRawSoql_WhenSoqlIsBlank_ThenThrowException() {
    // Note: Real-DML success path is intentionally not covered here — the same as the
    // other Eloquent tests, organization-specific object permissions make execution
    // assertions brittle. Only the input-validation contract is covered.
    try {
      (new Eloquent()).rawSoql(null);
      Assert.fail('Expected ApexEloquentException when SOQL is null');
    } catch (ApexEloquentException e) {
      String msg = e.getMessage();
      Assert.isTrue(msg.contains('rawSoql(String soql)'), 'should mention rawSoql method');
      Assert.isTrue(msg.contains('argument is required'), 'should indicate required-parameter violation');
    }

    try {
      (new Eloquent()).rawSoql('');
      Assert.fail('Expected ApexEloquentException when SOQL is empty');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('rawSoql(String soql)'), 'should mention rawSoql method');
    }
  }

  @isTest
  static void testGetAsSObject_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = null;

    // Act & Assert
    try {
      (new Eloquent()).getAsSObject(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('getAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testGetAsSObject_WhenApplyScribe_ThenSuccess() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000');

    // Act
    List<SObject> oppSObjects = (new Eloquent()).getAsSObject(scribe);

    // Assert
    Assert.isTrue(oppSObjects.isEmpty(), 'Expected no records to be returned');
  }

  @isTest
  static void testGetFirst_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = null;

    // Act & Assert
    try {
      (new Eloquent()).first(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('first(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testFirst_WhenApplyScribe_ThenSuccess() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000');

    // Act
    IEntry oppEntry = (new Eloquent()).first(scribe);

    // Assert
    Assert.isNull(oppEntry, 'Expected no record to be returned');
  }

  @isTest
  static void testFirstAsSObject_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = null;

    // Act & Assert
    try {
      (new Eloquent()).firstAsSObject(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testFirstAsSObject_WhenApplyScribe_ThenSuccess() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000');

    // Act
    SObject oppSObject = (new Eloquent()).firstAsSObject(scribe);

    // Assert
    Assert.isNull(oppSObject, 'Expected no record to be returned');
  }

  @isTest
  static void testFirstOrFail_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = null;

    // Act & Assert
    try {
      (new Eloquent()).firstOrFail(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstOrFail(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testFirstOrFail_WhenApplyScribe_ThenSuccess() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000');

    // Act & Assert
    try {
      IEntry oppEntry = (new Eloquent()).firstOrFail(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      System.debug(e.getMessage());
      Assert.isTrue(e.getMessage().contains('No records were found'));
    }
  }

  @isTest
  static void testFirstOrFailAsSObject_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = null;

    // Act & Assert
    try {
      (new Eloquent()).firstOrFailAsSObject(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('firstOrFailAsSObject(Scribe scribe)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testFirstOrFailAsSObject_WhenApplyScribe_ThenSuccess() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000');
    // Act & Assert
    try {
      SObject oppSObject = (new Eloquent()).firstOrFailAsSObject(scribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('No records were found'));
    }
  }

  @isTest
  static void testDoInsert_WhenApplyNull_ThenThrowException() {
    // Arrange
    SObject opp = null;

    // Act & Assert
    try {
      (new Eloquent()).doInsert(opp);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doInsert(SObject record)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoInsert_WhenApplySingleRecord_ThenExcuteInsert() {
    // Arrange
    Opportunity opp = new Opportunity();
    opp.Name = 'Test';

    // Act & Assert
    try {
      opp = (Opportunity) (new Eloquent()).doInsert(opp);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to insert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoInsert_WhenApplyNullList_ThenThrowException() {
    // Arrange
    List<SObject> opps = null;

    // Act & Assert
    try {
      (new Eloquent()).doInsert(opps);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doInsert(List<SObject> records)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoInsert_WhenApplyMultipleRecords_ThenExcuteInsert() {
    // Arrange
    Opportunity opp1 = new Opportunity(Name = 'Test1');
    Opportunity opp2 = new Opportunity(Name = 'Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act & Assert
    try {
      opps = (List<Opportunity>) (new Eloquent()).doInsert(opps);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to insert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullSObject_ThenThrowException() {
    // Arrange
    SObject opp = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(opp);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(SObject record)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplySObject_ThenThrowException() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Updated Test');

    // Act & Assert
    try {
      opp = (Opportunity) (new Eloquent()).doUpdate(opp);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to update operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullSObjectWithAllOrNone_ThenThrowException() {
    // Arrange
    SObject opp = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(opp, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(SObject record, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplySObjectWithAllOrNoneIsTrue_ThenThrowException() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Updated Test');

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(opp, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to update operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplySObjectWithAllOrNoneIsFalse_ThenThrowException() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Updated Test');

    // Act
    Database.SaveResult saveResult = (new Eloquent()).doUpdate(opp, false);

    // Assert
    Assert.isFalse(saveResult.isSuccess(), 'Expected update to fail');
  }

  @isTest
  static void testDoUpdate_WhenApplyNullEntry_ThenThrowException() {
    // Arrange
    IEntry entry = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(entry);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(IEntry entry)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEntry_ThenExcuteUpdate() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Updated Test');
    IEntry entry = new Entry(opp);

    // Act & Assert
    try {
      entry = (new Eloquent()).doUpdate(entry);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to update operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullAsEntryWithAllOrNone_ThenThrowException() {
    // Arrange
    IEntry entry = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(entry, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(IEntry entry, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEntryWithAllOrNoneIsTrue_ThenThrowException() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Updated Test');
    IEntry entry = new Entry(opp);

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(entry, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to update operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEntryWithAllOrNoneIsFalse_ThenThrowException() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Updated Test');
    IEntry entry = new Entry(opp);

    // Act
    Database.SaveResult saveResult = (new Eloquent()).doUpdate(entry, false);

    // Assert
    Assert.isFalse(saveResult.isSuccess(), 'Expected update to fail');
  }


  @isTest
  static void testDoUpdate_WhenApplyNullSObjectList_ThenThrowException() {
    // Arrange
    List<SObject> opps = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(opps);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<SObject> records)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplySObjectList_ThenExecuteUpdate() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Updated Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Updated Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act & Assert
    try {
      opps = (List<Opportunity>) (new Eloquent()).doUpdate(opps);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to update operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullEntryList_ThenThrowException() {
    // Arrange
    List<IEntry> entries = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(entries);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<IEntry> entries)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEntryList_ThenExecuteUpdate() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Updated Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Updated Test2');
    List<IEntry> entries = new List<IEntry>{ new Entry(opp1), new Entry(opp2) };
    // Act & Assert
    try {
      entries = (List<IEntry>) (new Eloquent()).doUpdate(entries);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to update operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullSObjectListWithAllOrNone_ThenThrowException() {
    // Arrange
    List<SObject> opps = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(opps, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<SObject> records, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplySObjectListWithAllOrNoneIsTrue_ThenThrowException() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Updated Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Updated Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(opps, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to update operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplySObjectListWithAllOrNoneIsFalse_ThenReturnFailedSaveResults() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Updated Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Updated Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act
    List<Database.SaveResult> saveResults = (new Eloquent()).doUpdate(opps, false);

    // Assert
    Assert.areEqual(2, saveResults.size(), 'Expected 2 save results');
    for (Database.SaveResult sr : saveResults) {
      Assert.isFalse(sr.isSuccess(), 'Expected update to fail');
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyNullEntryListWithAllOrNone_ThenThrowException() {
    // Arrange
    List<IEntry> entries = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(entries, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpdate(List<IEntry> entries, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEntryListWithAllOrNoneIsTrue_ThenThrowException() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Updated Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Updated Test2');
    List<IEntry> entries = new List<IEntry>{ new Entry(opp1), new Entry(opp2) };

    // Act & Assert
    try {
      (new Eloquent()).doUpdate(entries, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to update operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEntryListWithAllOrNoneIsFalse_ThenReturnFailedSaveResults() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Updated Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Updated Test2');
    List<IEntry> entries = new List<IEntry>{ new Entry(opp1), new Entry(opp2) };

    // Act
    List<Database.SaveResult> saveResults = (new Eloquent()).doUpdate(entries, false);

    // Assert
    Assert.areEqual(2, saveResults.size(), 'Expected 2 save results');
    for (Database.SaveResult sr : saveResults) {
      Assert.isFalse(sr.isSuccess(), 'Expected update to fail');
    }
  }

  @isTest
  static void testDoUpdate_WhenApplyEmptyEntryListWithAllOrNone_ThenReturnEmptySaveResults() {
    // Arrange
    List<IEntry> entries = new List<IEntry>();

    // Act
    List<Database.SaveResult> saveResults = (new Eloquent()).doUpdate(entries, false);

    // Assert
    Assert.isTrue(saveResults.isEmpty(), 'Expected no save results');
  }

  @isTest
  static void testUpdateEmptyEntries() {
    // Arrange
    List<IEntry> entries = new List<IEntry>();

    // Act
    List<IEntry> updatedEntries = (new Eloquent()).doUpdate(entries);

    // Assert
    Assert.isTrue(updatedEntries.isEmpty(), 'Expected no entries to be updated');
  }

  @isTest
  static void testDoUpsert_WhenApplyNullSObject_ThenThrowException() {
    // Arrange
    SObject opp = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpsert(opp);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(SObject record)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsert_WhenApplySObject_ThenExecuteUpsert() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Upserted Test');

    // Act & Assert
    try {
      opp = (Opportunity) (new Eloquent()).doUpsert(opp);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to upsert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpsert_WhenApplyNullEntry_ThenThrowException() {
    // Arrange
    IEntry entry = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpsert(entry);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(IEntry entry)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsert_WhenApplyEntry_ThenExecuteUpsert() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Upserted Test');
    IEntry entry = new Entry(opp);
    // Act & Assert
    try {
      entry = (new Eloquent()).doUpsert(entry);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to upsert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpsert_WhenApplyNullSObjectList_ThenThrowException() {
    // Arrange
    List<SObject> opps = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpsert(opps);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(List<SObject> records)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsert_WhenApplyMultipleSObjectList_ThenExecuteUpsert() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Upserted Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Upserted Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };
    // Act & Assert
    try {
      opps = (List<Opportunity>) (new Eloquent()).doUpsert(opps);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to upsert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpsert_WhenApplyNullEntryList_ThenThrowException() {
    // Arrange
    List<IEntry> entries = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpsert(entries);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsert(List<IEntry> entries)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testUpser_WhenApplyEmptyEntryList_ThenReturnEmptyEntryList() {
    // Arrange
    List<IEntry> entries = new List<IEntry>();
    // Act
    List<IEntry> upsertedEntries = (new Eloquent()).doUpsert(entries);
    // Assert
    Assert.isTrue(upsertedEntries.isEmpty(), 'Expected no entries to be upserted');
  }

  @isTest
  static void testDoUpsert_WhenApplyMultipleEntryList_ThenExecuteUpsert() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Upserted Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Upserted Test2');
    List<IEntry> entries = new List<IEntry>{ new Entry(opp1), new Entry(opp2) };

    // Act & Assert
    try {
      entries = (List<IEntry>) (new Eloquent()).doUpsert(entries);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to upsert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyNullSObject_ThenThrowException() {
    // Arrange
    SObject opp = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpsertByExternalId(opp, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(SObject record, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplySObjectWithAllOrNoneIsTrue_ThenThrowException() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Upserted Test');

    // Act & Assert
    try {
      (new Eloquent()).doUpsertByExternalId(opp, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to upsert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplySObjectWithAllOrNoneIsFalse_ThenReturnFailedUpsertResult() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Upserted Test');

    // Act
    Database.UpsertResult result = (new Eloquent()).doUpsertByExternalId(opp, Opportunity.Id, false);

    // Assert
    Assert.isFalse(result.isSuccess(), 'Expected upsert to fail');
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyNullEntry_ThenThrowException() {
    // Arrange
    IEntry entry = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpsertByExternalId(entry, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(IEntry entry, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyEntryWithAllOrNoneIsTrue_ThenThrowException() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Upserted Test');
    IEntry entry = new Entry(opp);

    // Act & Assert
    try {
      (new Eloquent()).doUpsertByExternalId(entry, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to upsert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyEntryWithAllOrNoneIsFalse_ThenReturnFailedUpsertResult() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000', Name = 'Upserted Test');
    IEntry entry = new Entry(opp);

    // Act
    Database.UpsertResult result = (new Eloquent()).doUpsertByExternalId(entry, Opportunity.Id, false);

    // Assert
    Assert.isFalse(result.isSuccess(), 'Expected upsert to fail');
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyNullSObjectList_ThenThrowException() {
    // Arrange
    List<SObject> opps = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpsertByExternalId(opps, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplySObjectListWithAllOrNoneIsTrue_ThenThrowException() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Upserted Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Upserted Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act & Assert
    try {
      (new Eloquent()).doUpsertByExternalId(opps, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to upsert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplySObjectListWithAllOrNoneIsFalse_ThenReturnFailedUpsertResults() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Upserted Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Upserted Test2');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act
    List<Database.UpsertResult> results = (new Eloquent()).doUpsertByExternalId(opps, Opportunity.Id, false);

    // Assert
    Assert.areEqual(2, results.size(), 'Expected 2 upsert results');
    for (Database.UpsertResult r : results) {
      Assert.isFalse(r.isSuccess(), 'Expected upsert to fail');
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyNullEntryList_ThenThrowException() {
    // Arrange
    List<IEntry> entries = null;

    // Act & Assert
    try {
      (new Eloquent()).doUpsertByExternalId(entries, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doUpsertByExternalId(List<IEntry> entries, Schema.SObjectField externalIdField, Boolean allOrNone)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyEntryListWithAllOrNoneIsTrue_ThenThrowException() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Upserted Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Upserted Test2');
    List<IEntry> entries = new List<IEntry>{ new Entry(opp1), new Entry(opp2) };

    // Act & Assert
    try {
      (new Eloquent()).doUpsertByExternalId(entries, Opportunity.Id, true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to upsert operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyEntryListWithAllOrNoneIsFalse_ThenReturnFailedUpsertResults() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000', Name = 'Upserted Test1');
    Opportunity opp2 = new Opportunity(Id = '006000000000001', Name = 'Upserted Test2');
    List<IEntry> entries = new List<IEntry>{ new Entry(opp1), new Entry(opp2) };

    // Act
    List<Database.UpsertResult> results = (new Eloquent()).doUpsertByExternalId(entries, Opportunity.Id, false);

    // Assert
    Assert.areEqual(2, results.size(), 'Expected 2 upsert results');
    for (Database.UpsertResult r : results) {
      Assert.isFalse(r.isSuccess(), 'Expected upsert to fail');
    }
  }

  @isTest
  static void testDoUpsertByExternalId_WhenApplyEmptyEntryList_ThenReturnEmptyUpsertResults() {
    // Arrange
    List<IEntry> entries = new List<IEntry>();

    // Act
    List<Database.UpsertResult> results = (new Eloquent()).doUpsertByExternalId(entries, Opportunity.Id, false);

    // Assert
    Assert.isTrue(results.isEmpty(), 'Expected no upsert results');
  }

  @isTest
  static void testDoDelete_WhenApplyNullSObject_ThenThrowException() {
    // Arrange
    SObject opp = null;

    // Act & Assert
    try {
      (new Eloquent()).doDelete(opp);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(SObject record)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoDelete_WhenApplySObject_ThenExecuteDelete() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000');

    // Act & Assert
    try {
      (new Eloquent()).doDelete(opp);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to delete operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoDelete_WhenApplyNullEntry_ThenThrowException() {
    // Arrange
    IEntry entry = null;

    // Act & Assert
    try {
      (new Eloquent()).doDelete(entry);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(IEntry entry)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoDelete_WhenApplyEntry_ThenExecuteDelete() {
    // Arrange
    Opportunity opp = new Opportunity(Id = '006000000000000');
    IEntry entry = new Entry(opp);

    // Act & Assert
    try {
      (new Eloquent()).doDelete(entry);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to delete operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoDelete_WhenApplyNullSObjectList_ThenThrowException() {
    // Arrange
    List<SObject> opps = null;

    // Act & Assert
    try {
      (new Eloquent()).doDelete(opps);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(List<SObject> records)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoDelete_WhenApplySObjectList_ThenExecuteDelete() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000');
    Opportunity opp2 = new Opportunity(Id = '006000000000001');
    List<Opportunity> opps = new List<Opportunity>{ opp1, opp2 };

    // Act & Assert
    try {
      (new Eloquent()).doDelete(opps);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to delete operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDoDelete_WhenApplyNullEntryList_ThenThrowException() {
    // Arrange
    List<IEntry> entries = null;

    // Act & Assert
    try {
      (new Eloquent()).doDelete(entries);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String errorMessage = e.getMessage();
      Assert.isTrue(errorMessage.contains('doDelete(List<IEntry> entries)'));
      Assert.isTrue(errorMessage.contains('argument is required'));
    }
  }

  @isTest
  static void testDoDelete_WhenApplyEntryList_ThenExecuteDelete() {
    // Arrange
    Opportunity opp1 = new Opportunity(Id = '006000000000000');
    Opportunity opp2 = new Opportunity(Id = '006000000000001');
    List<IEntry> entries = new List<IEntry>{ new Entry(opp1), new Entry(opp2) };

    // Act & Assert
    try {
      (new Eloquent()).doDelete(entries);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Failed to delete operation'));
      Assert.isTrue(error.contains('DML failed with'));
    }
  }

  @isTest
  static void testDeleteEmptyEntries() {
    // Arrange
    List<IEntry> entries = new List<IEntry>();

    // Act
    (new Eloquent()).doDelete(entries);

    // Assert
    // No exception should be thrown
  }

  // ===========================================================================
  // label() (issue_42)
  // ===========================================================================

  @isTest
  static void testLabel_WhenChained_ThenReturnSelf() {
    Eloquent eloquent = new Eloquent();
    IEloquent result = eloquent.label('foo');
    Assert.areEqual(eloquent, result, 'label() should return the same instance for chaining.');
  }

  @isTest
  static void testLabel_WhenNull_ThenThrowException() {
    try {
      (new Eloquent()).label(null);
      Assert.fail('Expected ApexEloquentException for null label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('label(String label)'));
      Assert.isTrue(e.getMessage().contains('argument is required'));
    }
  }

  @isTest
  static void testLabel_WhenBlank_ThenThrowException() {
    try {
      (new Eloquent()).label('   ');
      Assert.fail('Expected ApexEloquentException for blank label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('label(String label)'));
      Assert.isTrue(e.getMessage().contains('argument is required'));
    }
  }

  // ===========================================================================
  // strict mode (issue_39)
  // ===========================================================================

  @isTest
  static void testLabel_AfterLabelCall_NoLabelOpThrows() {
    // After the first .label() call the IEloquent enters strict mode. Subsequent
    // ops without .label() must throw — even in production. We trigger a first
    // op that fails with a normal DML error (invalid Id), then call again with
    // no label — that must throw the strict-mode error, not the DML error.
    Eloquent eloquent = new Eloquent();
    try {
      eloquent.label('first').doUpdate(new Opportunity(Id = '006000000000000', Name = 'X'));
    } catch (ApexEloquentException e) {
      // expected — invalid Id failure on the first op. 'first' is now consumed.
    }
    try {
      eloquent.doUpdate(new Opportunity(Id = '006000000000001', Name = 'Y'));
      Assert.fail('Expected strict-mode exception for label-less op after strict mode entered.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(
        e.getMessage().contains('strict mode required'),
        'Expected the strict-mode message, got: ' + e.getMessage()
      );
    }
  }

  @isTest
  static void testLabel_AfterSuccessfulOp_ReusingSameLabelThrows() {
    // consume-once guards one SUCCESSFUL operation per label, so the first op
    // must succeed for the reuse to be a violation (a failed op releases its label)
    Eloquent eloquent = new Eloquent();
    eloquent.label('dup').doInsert(buildGroup('consumeOnce'));
    try {
      eloquent.label('dup').doUpdate(new Opportunity(Id = '006000000000001', Name = 'Y'));
      Assert.fail('Expected consume-once exception when reusing label.');
    } catch (ApexEloquentException e) {
      Assert.isTrue(
        e.getMessage().contains('already been consumed'),
        'Expected consume-once message, got: ' + e.getMessage()
      );
      Assert.isTrue(e.getMessage().contains('dup'), 'Should mention the label name.');
    }
  }

  @isTest
  static void testLabel_WhenOpFails_ThenLabelReleasedForRetry() {
    // a failed op releases its label, so a retry loop can reuse the same
    // label — the 2nd attempt must fail with the DML error, not consume-once
    Eloquent eloquent = new Eloquent();
    for (Integer attempt = 1; attempt <= 2; attempt++) {
      try {
        eloquent.label('upd').doUpdate(new Opportunity(Id = '006000000000000', Name = 'X'));
        Assert.fail('Expected DML failure (invalid Id) on attempt ' + attempt + '.');
      } catch (ApexEloquentException e) {
        Assert.isTrue(
          e.getMessage().contains('Failed to update operation'),
          'Attempt ' + attempt + ' must fail with the DML error, not consume-once. Got: ' + e.getMessage()
        );
      }
    }
  }

  @isTest
  static void testLabel_AfterLabelCall_NewLabelOk() {
    Eloquent eloquent = new Eloquent();
    try {
      eloquent.label('a').doUpdate(new Opportunity(Id = '006000000000000', Name = 'X'));
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('Failed to update operation'), 'First failure should be DML, not strict-mode.');
    }
    // Different label — should NOT throw strict-mode/consume-once; only the
    // underlying DML failure.
    try {
      eloquent.label('b').doUpdate(new Opportunity(Id = '006000000000001', Name = 'Y'));
      Assert.fail('Expected DML failure (invalid Id).');
    } catch (ApexEloquentException e) {
      Assert.isTrue(
        e.getMessage().contains('Failed to update operation'),
        'Second failure should be the DML one, not strict-mode. Got: ' + e.getMessage()
      );
    }
  }

  // ===============================================================================
  // Real DML / SOQL success paths (issue #52)
  // Group / GroupMember are platform-frozen (no triggers, validation rules, record
  // types, or custom fields are possible), so these round-trips cannot be broken
  // by consumer-org customization. Each test touches only setup objects, avoiding
  // mixed DML with the rest of the suite.
  // ===============================================================================

  private static Group buildGroup(String seed) {
    return new Group(
      Name = 'EloquentRT ' + seed,
      DeveloperName = 'EloquentRT_' + seed + '_' + Datetime.now().getTime()
    );
  }

  @isTest
  static void testDoInsert_WhenValidSingleRecord_ThenIdIsAssignedAndPersisted() {
    // Act
    Group grp = (Group) (new Eloquent()).doInsert(buildGroup('ins'));

    // Assert
    Assert.isNotNull(grp.Id, 'doInsert must return the record with its Id assigned');
    Assert.areEqual('EloquentRT ins', [SELECT Name FROM Group WHERE Id = :grp.Id].Name);
  }

  @isTest
  static void testDoInsert_WhenValidList_ThenAllPersisted() {
    // Act
    List<Group> groups = (List<Group>) (new Eloquent()).doInsert(
      new List<Group>{ buildGroup('insA'), buildGroup('insB') }
    );

    // Assert
    Assert.isNotNull(groups[0].Id);
    Assert.isNotNull(groups[1].Id);
    Assert.areEqual(2, [SELECT COUNT() FROM Group WHERE Id IN :new List<Id>{ groups[0].Id, groups[1].Id }]);
  }

  @isTest
  static void testDoUpsert_WhenEntryGiven_ThenReturnedEntryCarriesId() {
    // Act - doUpsert is the IEntry-accepting insert path (doInsert has no IEntry overload)
    IEntry inserted = (new Eloquent()).doUpsert(new Entry(buildGroup('insEntry')));

    // Assert
    Assert.isNotNull(inserted.getId(), 'IEntry round-trip must expose the assigned Id');
  }

  @isTest
  static void testDoUpdate_WhenValidRecord_ThenChangeIsPersisted() {
    // Arrange
    Group grp = buildGroup('upd');
    insert grp;
    grp.Name = 'EloquentRT upd changed';

    // Act
    (new Eloquent()).doUpdate(grp);

    // Assert
    Assert.areEqual('EloquentRT upd changed', [SELECT Name FROM Group WHERE Id = :grp.Id].Name);
  }

  @isTest
  static void testDoUpsert_WhenNewThenExisting_ThenInsertsThenUpdates() {
    // Act - upsert without Id inserts
    Group grp = (Group) (new Eloquent()).doUpsert(buildGroup('ups'));
    Assert.isNotNull(grp.Id);

    // Act - upsert with Id updates the same row
    grp.Name = 'EloquentRT ups changed';
    (new Eloquent()).doUpsert(grp);

    // Assert
    Assert.areEqual('EloquentRT ups changed', [SELECT Name FROM Group WHERE Id = :grp.Id].Name);
    Assert.areEqual(1, [SELECT COUNT() FROM Group WHERE Id = :grp.Id]);
  }

  @isTest
  static void testDoDelete_WhenValidRecord_ThenRemoved() {
    // Arrange
    Group grp = buildGroup('del');
    insert grp;

    // Act
    (new Eloquent()).doDelete(grp);

    // Assert
    Assert.areEqual(0, [SELECT COUNT() FROM Group WHERE Id = :grp.Id]);
  }

  @isTest
  static void testGet_WhenRealQuery_ThenRowsAndValuesReturned() {
    // Arrange
    Group grp = buildGroup('get');
    insert grp;
    insert new GroupMember(GroupId = grp.Id, UserOrGroupId = UserInfo.getUserId());

    // Act
    Scribe memberScribe = Scribe.of(GroupMember.class)
      .field('Id')
      .field('UserOrGroupId')
      .whereEqual('GroupId', grp.Id);
    List<IEntry> members = (new Eloquent()).get(memberScribe);

    // Assert
    Assert.areEqual(1, members.size());
    Assert.areEqual(UserInfo.getUserId(), (Id) members[0].get('UserOrGroupId'));
  }

  @isTest
  static void testFirstOrFail_WhenRowExists_ThenReturnsEntry() {
    // Arrange
    Group grp = buildGroup('fof');
    insert grp;

    // Act
    Scribe groupScribe = Scribe.of(Group.class).field('Id').field('Name').whereEqual('Id', grp.Id);
    IEntry entry = (new Eloquent()).firstOrFail(groupScribe);

    // Assert
    Assert.areEqual(grp.Id, entry.getId());
    Assert.areEqual('EloquentRT fof', (String) entry.get('Name'));
  }

  @isTest
  static void testGetParent_WhenParentFieldQueried_ThenParentValuesReadable() {
    // Arrange
    Group grp = buildGroup('parent');
    insert grp;
    insert new GroupMember(GroupId = grp.Id, UserOrGroupId = UserInfo.getUserId());

    // Act
    Scribe memberScribe = Scribe.of(GroupMember.class)
      .field('Id')
      .parentField(Scribe.asParent('GroupId').field('Name'))
      .whereEqual('GroupId', grp.Id);
    IEntry member = (new Eloquent()).firstOrFail(memberScribe);
    IEntry parentGroup = member.getParent('GroupId');

    // Assert
    Assert.areEqual('EloquentRT parent', (String) parentGroup.get('Name'));
  }

  @isTest
  static void testGetChildren_WhenSubqueryQueried_ThenChildrenReadable() {
    // Arrange
    Group grp = buildGroup('children');
    insert grp;
    insert new GroupMember(GroupId = grp.Id, UserOrGroupId = UserInfo.getUserId());

    // Act
    // Group has two relationships to GroupMember (GroupId / UserOrGroupId), so the
    // relationship name must be given explicitly on both the query and the getter
    Scribe groupScribe = Scribe.of(Group.class)
      .field('Id')
      .withChildren(
        Scribe.asChild(GroupMember.class).relationName('GroupMembers').field('Id').field('UserOrGroupId')
      )
      .whereEqual('Id', grp.Id);
    IEntry groupEntry = (new Eloquent()).firstOrFail(groupScribe);
    List<IEntry> members = groupEntry.getChildren('GroupMembers');

    // Assert
    Assert.areEqual(1, members.size());
    Assert.areEqual(UserInfo.getUserId(), (Id) members[0].get('UserOrGroupId'));
  }

  @isTest
  static void testAggregate_WhenCountGroupBy_ThenCountsReturned() {
    // Arrange
    Group grp = buildGroup('agg');
    insert grp;
    insert new GroupMember(GroupId = grp.Id, UserOrGroupId = UserInfo.getUserId());

    // Act
    Scribe aggScribe = Scribe.of(GroupMember.class)
      .field('GroupId')
      .count('Id', 'memberCount')
      .whereEqual('GroupId', grp.Id)
      .groupByField('GroupId');
    List<IEntry> results = (new Eloquent()).get(aggScribe);

    // Assert
    Assert.areEqual(1, results.size());
    Assert.areEqual(grp.Id, (Id) results[0].get('GroupId'));
    Assert.areEqual(1, ((Decimal) results[0].get('memberCount')).intValue());
  }

  @isTest
  static void testGet_WhenFieldNotSelected_ThenRealRowThrowsSObjectException() {
    // Arrange - a real SOQL row is strict by itself: reading an unqueried field throws.
    // (This is why production Entry needs no FieldStructure — see MockEntry.fetchedBy for tests.)
    Group grp = buildGroup('leak');
    insert grp;

    // Act
    Scribe idOnlyScribe = Scribe.of(Group.class).field('Id').whereEqual('Id', grp.Id);
    IEntry entry = (new Eloquent()).firstOrFail(idOnlyScribe);

    // Assert
    try {
      entry.get('Name');
      Assert.fail('Expected SObjectException for a field missing from the real SOQL row');
    } catch (SObjectException e) {
      Assert.isTrue(e.getMessage().contains('retrieved via SOQL'), e.getMessage());
    }
  }

  private class RoundTripNotFoundException extends Exception {
  }

  @isTest
  static void testFirstOrFail_WhenCustomExceptionAndRowExists_ThenReturnsEntry() {
    // Arrange
    Group grp = buildGroup('fofCustomHit');
    insert grp;

    // Act
    Scribe groupScribe = Scribe.of(Group.class).field('Id').whereEqual('Id', grp.Id);
    IEntry entry = (new Eloquent()).firstOrFail(groupScribe, new RoundTripNotFoundException('not used'));

    // Assert
    Assert.areEqual(grp.Id, entry.getId());
  }

  @isTest
  static void testFirstOrFail_WhenCustomExceptionAndNoRow_ThenThrowsItAsIs() {
    // Arrange - a query that matches nothing
    Scribe groupScribe = Scribe.of(Group.class)
      .field('Id')
      .whereEqual('DeveloperName', 'EloquentRT_never_exists_' + Datetime.now().getTime());

    // Act & Assert - the given exception is thrown as-is (type and message preserved)
    try {
      (new Eloquent()).firstOrFail(groupScribe, new RoundTripNotFoundException('business-facing message'));
      Assert.fail('Expected RoundTripNotFoundException to be thrown');
    } catch (RoundTripNotFoundException e) {
      Assert.areEqual('business-facing message', e.getMessage());
    }
  }

  @isTest
  static void testFirstOrFail_WhenCustomExceptionIsNull_ThenThrowsRequired() {
    // Act & Assert
    try {
      (new Eloquent()).firstOrFail(Scribe.of(Group.class).field('Id'), null);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('The `orFail` argument is required'), e.getMessage());
    }
  }
}
