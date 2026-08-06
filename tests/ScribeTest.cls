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
@isTest(seeAllData=false)
public with sharing class ScribeTest {
  @isTest
  static void testScribeIsImmutableTest() {
    // Arrange
    Scribe scribeOriginal = Scribe.of(Account.class);

    // Act
    Scribe scribeAfterAddingId = scribeOriginal.field('Id');

    // Assert
    Assert.areEqual(0, scribeOriginal.selectFields.size());
    Assert.areEqual(1, scribeAfterAddingId.selectFields.size());

    // Additional Act
    Scribe scribeAfterAddingName = scribeAfterAddingId.field('Name');
    scribeOriginal = scribeOriginal.fields(new List<String>{ 'Name', 'StageName', 'CloseDate' });

    // Additional Assert
    Assert.areEqual(3, scribeOriginal.selectFields.size());
    Assert.areEqual(1, scribeAfterAddingId.selectFields.size());
    Assert.areEqual(2, scribeAfterAddingName.selectFields.size());
  }

  @isTest
  static void testOf_WhenApplyNull_ThenThrowException() {
    // Act & Assert
    try {
      Scribe scribe = Scribe.of(null);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('of(System.Type recordType)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testOf_WhenApplyString_ThenThrowException() {
    // Act & Assert
    try {
      Scribe scribe = Scribe.of(String.class);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('of(System.Type recordType)'));
      Assert.isTrue(error.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testAsParent_WhenApplyNull_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.asParent(null);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('asParent(String parentRelationIdFieldName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAsParent_WhenApplyVoidString_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.asParent('');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('asParent(String parentRelationIdFieldName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAsChild_WhenApplyNull_ThenThrowException() {
    // Arrange
    System.Type childRecordType = null;

    // Act & Assert
    try {
      Scribe scribe = Scribe.asChild(childRecordType);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('asChild(System.Type childRecordType)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAsChild_WhenApplyStringClass_ThenThrowException() {
    // Arrange
    System.Type childRecordType = String.class;

    // Act & Assert
    try {
      Scribe scribe = Scribe.asChild(childRecordType);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('asChild(System.Type childRecordType)'));
      Assert.isTrue(error.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testAsThrough_WhenApplyNullToJunctionType_ThenThrowException() {
    // Arrange
    System.Type junctionType = null;
    String targetLookupField = 'Target__c';

    // Act & Assert
    try {
      Scribe scribe = Scribe.asThrough(junctionType, targetLookupField);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('asThrough(System.Type junctionType, String targetLookupField)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAsThrough_WhenApplyStringClassToJunctionType_ThenThrowException() {
    // Arrange
    System.Type junctionType = String.class;
    String targetLookupField = 'Target__c';

    // Act & Assert
    try {
      Scribe scribe = Scribe.asThrough(junctionType, targetLookupField);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('asThrough(System.Type junctionType, String targetLookupField)'));
      Assert.isTrue(error.contains('argument is Invalid'));
    }
  }

  @isTest
  static void testAsThrough_WhenApplyNullToTargetLookupField_ThenThrowException() {
    // Arrange
    System.Type junctionType = Account.class;
    String targetLookupField = null;

    // Act & Assert
    try {
      Scribe scribe = Scribe.asThrough(junctionType, targetLookupField);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('asThrough(System.Type junctionType, String targetLookupField)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAsThrough_WhenApplyVoidStringToTargetLookupField_ThenThrowException() {
    // Arrange
    System.Type junctionType = Account.class;
    String targetLookupField = '';

    // Act & Assert
    try {
      Scribe scribe = Scribe.asThrough(junctionType, targetLookupField);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('asThrough(System.Type junctionType, String targetLookupField)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testField_WhenApplyNullAsString_WhenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class);
    String fieldName = null;

    // Act & Assert
    try {
      scribe.field(fieldName);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('field(String fieldName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testField_WhenApplyVoidStringAsString_WhenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class);
    String fieldName = '';

    // Act & Assert
    try {
      scribe.field(fieldName);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('field(String fieldName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testField_WhenUsedWithAsGroup_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.asGroup().field('Id');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('field(String fieldName)'));
      Assert.isTrue(error.contains('Field Addition Forbidden'));
    }
  }

  @isTest
  static void testField_WhenUsedWithAsHaving_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.asHaving().field('Id');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('field(String fieldName)'));
      Assert.isTrue(error.contains('Field Addition Forbidden'));
    }
  }

  @isTest
  static void testField_WhenAddField_ThenAddFieldToSelect() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testField_WhenAddMultiFieldsUsingFieldMethod_ThenAddFieldsToSelect() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').field('Name').field('StageName');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, name, stagename FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testField_WhenAddNonExistField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('NonExistField');

    // Act & Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Field Selection Failed'));
    }
  }

  @isTest
  static void testFields_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class);
    List<String> fields = null;

    // Act & Assert
    try {
      scribe.fields(fields);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('fields(List<String> fieldNames)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testFields_WhenApplyEmptyList_ThenNoErrorThrown() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class);
    List<String> fields = new List<String>();

    // Act
    scribe.fields(fields);

    // Assert
    String soql = scribe.toSoql();
    String expectedSoql = 'SELECT id FROM Account';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testFields_WhenUsedWithAsGroup_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.asGroup().fields(new List<String>{ 'Id', 'Name' });
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('fields(List<String> fieldNames)'));
      Assert.isTrue(error.contains('Field Addition Forbidden'));
    }
  }

  @isTest
  static void testFields_WhenUsedWithAsHaving_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.asHaving().fields(new List<String>{ 'Id', 'Name' });
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('fields(List<String> fieldNames)'));
      Assert.isTrue(error.contains('Field Addition Forbidden'));
    }
  }

  @isTest
  static void testFields_WhenAddList_ThenAddFieldsToSelect() {
    // Arrange
    List<String> fields = new List<String>{ 'Id', 'Name', 'StageName' };
    Scribe scribe = Scribe.of(Opportunity.class).fields(fields);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, name, stagename FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testAllFields_WhenUsedWithAsGroup_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.asGroup().allFields();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('allFields()'));
      Assert.isTrue(error.contains('Field Addition Forbidden'));
    }
  }

  @isTest
  static void testAllFields_WhenUsedWithAsHaving_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.asHaving().allFields();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('allFields()'));
      Assert.isTrue(error.contains('Field Addition Forbidden'));
    }
  }

  @isTest
  static void testAllFields_WhenAddAllFields_ThenAddAllFieldsToSelect() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).allFields();

    // Act
    String soql = scribe.toSoql();

    // Assert
    Assert.isTrue(soql.contains('id'));
    Assert.isTrue(soql.contains('name'));
    Assert.isTrue(soql.contains('stagename'));
  }

  @isTest
  static void testEqual_WhenApplyNullToFieldName_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class);
    String fieldName = null;

    // Act & Assert
    try {
      scribe.whereEqual(fieldName, 'Test Account');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereEqual(String fieldName, Object value)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testEqual_WhenApplyVoidStringToFieldName_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class);
    String fieldName = '';

    // Act & Assert
    try {
      scribe.whereEqual(fieldName, 'Test Account');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereEqual(String fieldName, Object value)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testEqual_WhenValueIsNotNull_ThenAddEqualCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testEqual_WhenValueIsNull_ThenAddIsNullCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').whereEqual('Name', null);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = NULL';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testEqual_WhenAddAndConditionAfterOrCondition_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class)
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .orCondition()
        .whereEqual('Name', 'Or Account Name')
        .whereEqual('Name', 'And Account Name');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereEqual(String fieldName, Object value)'));
      Assert.isTrue(error.contains('Illegal Logical Transition'));
    }
  }

  @isTest
  static void testEqual_WhenAddOrConditionAfterOrCondition_ThenAddOrCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'Test Account')
      .orCondition()
      .whereEqual('Name', 'Or Account Name')
      .orCondition()
      .whereEqual('Name', 'Another Or Account Name');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = \'Test Account\' OR Name = \'Or Account Name\' OR Name = \'Another Or Account Name\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testNotEqual_WhenValueIsNotNull_ThenAddEqualCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name != \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testNotEqual_WhenValueIsNull_ThenAddIsNotNullCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotEqual('Name', null);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name != NULL';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testGreaterThan_WhenValueIsNotNull_ThenAddGreaterThanCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereGreaterThan('TotalOpportunityQuantity', 1000);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE TotalOpportunityQuantity > 1000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testGreaterThan_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    Object value = null;

    // Arrange & Act & Assert
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereGreaterThan('TotalOpportunityQuantity', value);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereGreaterThan(String fieldName, Object value)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGreaterThan_WhenTypeOfValueIsDatetime_ThenAddGreaterThanCondition() {
    // Arrange
    Datetime dt = Datetime.newInstance(2023, 1, 1, 0, 0, 0);
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereGreaterThan('LastModifiedDate', dt);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedDatetime = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    String expectedSoql = 'SELECT id FROM Opportunity WHERE LastModifiedDate > ' + expectedDatetime;
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testGreaterThanOrEqual_WhenValueIsNotNull_ThenAddGreaterThanCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereGreaterThanOrEqual('TotalOpportunityQuantity', 1000);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE TotalOpportunityQuantity >= 1000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testGreaterThanOrEqual_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    Object value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .whereGreaterThanOrEqual('TotalOpportunityQuantity', value);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereGreaterThanOrEqual(String fieldName, Object value)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testLessThan_WhenValueIsNotNull_ThenAddLessThanCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereLessThan('TotalOpportunityQuantity', 1000);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE TotalOpportunityQuantity < 1000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testLessThan_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    Object value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereLessThan('TotalOpportunityQuantity', null);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereLessThan(String fieldName, Object value)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testLessThanOrEqual_WhenValueIsNotNull_ThenAddLessThanOrEqualCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereLessThanOrEqual('TotalOpportunityQuantity', 1000);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE TotalOpportunityQuantity <= 1000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testLessThanOrEqual_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    Object value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .whereLessThanOrEqual('TotalOpportunityQuantity', value);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereLessThanOrEqual(String fieldName, Object value)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testLike_WhenValueIsNotNull_ThenAddLikeCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').whereLike('Name', '%Test%');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name LIKE \'%Test%\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testLike_WhenValueContainsSingleQuote_ThenPreventInjection() {
    // Arrange
    String dengerousInput = 'Test\' OR Name != \'';
    Scribe scribe = Scribe.of(Account.class).field('Id').whereLike('Name', dengerousInput);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name LIKE \'Test\\\' OR Name != \\\'\'';
  }

  @isTest
  static void testLike_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    Object value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Account.class).field('Id').whereLike('Name', null);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereLike(String fieldName, String value)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testNotLike_WhenValueIsNotNull_ThenAddNotLikeCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotLike('Name', '%Test%');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE (NOT Name LIKE \'%Test%\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testNotLike_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    Object value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotLike('Name', null);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereNotLike(String fieldName, String value)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testIn_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    Object value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIn('Name', value);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereIn(String fieldName, Object values)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testIn_WhenValueIsList_ThenAddInCondition() {
    // Arrange
    List<String> values = new List<String>{ 'Test Account 1', 'Test Account 2' };
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name IN (\'Test Account 1\', \'Test Account 2\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIn_WhenValueIsIdSet_ThenAddInCondition() {
    // Arrange
    Set<Id> values = new Set<Id>{ '001000000000000AAA', '001000000000000AAB' };
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIn('Id', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Id IN (\'001000000000000AAA\', \'001000000000000AAB\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIn_WhenValueIncludeNull_ThenAddInConditionWithNull() {
    // Arrange
    List<String> values = new List<String>{ 'Test Account 1', null };
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name IN (\'Test Account 1\', NULL)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIn_WhenValueIsEmptyList_ThenAddConditionThatAlwaysFalse() {
    // Arrange
    List<String> values = new List<String>();
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Id = null';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIn_WhenApplyNullAsSubquery_ThenThrowAtBuildTime() {
    // Arrange
    Scribe subquery = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereIn('AccountId', subquery);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereIn(String fieldName, Scribe subQuery)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testIn_WhenUsingSubquery_ThenAddInSubQueryCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereIn('AccountId', Scribe.of(Account.class).field('Id').whereEqual('Name', 'Test Account'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE AccountId IN (SELECT id FROM Account WHERE Name = \'Test Account\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIn_WhenUsingSubqueryWithOrCondition_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .whereLike('Name', '%Test%')
        .orCondition()
        .whereIn('AccountId', Scribe.of(Account.class).field('Id').whereLike('Name', '%Test%'));

      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage(); 
      Assert.isTrue(error.contains('whereIn(String fieldName, Scribe subQuery)'));
      Assert.isTrue(error.contains('SOQL Semi-Join Restriction'));
    }
  }

  @isTest
  static void testNotIn_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    Object value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotIn('Name', value);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereNotIn(String fieldName, Object values)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testNotIn_WhenValueIsList_ThenAddNotInCondition() {
    // Arrange
    List<String> values = new List<String>{ 'Test Account 1', 'Test Account 2' };
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name NOT IN (\'Test Account 1\', \'Test Account 2\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testNotIn_WhenValueIsIdSet_ThenAddNotInCondition() {
    // Arrange
    Set<Id> values = new Set<Id>{ '001000000000000AAA', '001000000000000AAB' };
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotIn('Id', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Id NOT IN (\'001000000000000AAA\', \'001000000000000AAB\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testNotIn_WhenValueIncludeNull_ThenAddNotInConditionWithNull() {
    // Arrange
    List<String> values = new List<String>{ 'Test Account 1', null };
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotIn('Name', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name NOT IN (\'Test Account 1\', NULL)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testNotIn_WhenValueIsEmptyList_ThenIgnoreNotInCondition() {
    // Arrange
    List<String> values = new List<String>();
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereNotIn('Name', values)
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testNotIn_WhenApplyNullAsSubquery_ThenThrowAtBuildTime() {
    // Arrange
    Scribe subquery = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereNotIn('AccountId', subquery);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereNotIn(String fieldName, Scribe subQuery)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testNotIn_WhenUsingSubquery_ThenAddNotInSubQueryCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereNotIn('AccountId', Scribe.of(Account.class).field('Id').whereEqual('Name', 'Test Account'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE AccountId NOT IN (SELECT id FROM Account WHERE Name = \'Test Account\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testNotIn_WhenUsingSubqueryWithOrCondition_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .whereLike('Name', '%Test%')
        .orCondition()
        .whereNotIn('AccountId', Scribe.of(Account.class).field('Id').whereLike('Name', '%Test%'));

      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage(); 
      Assert.isTrue(error.contains('whereNotIn(String fieldName, Scribe subQuery)'));
      Assert.isTrue(error.contains('SOQL Semi-Join Restriction'));
    }
  }

  @isTest
  static void testIncludes_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    List<String> value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIncludes('Type', value);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereIncludes(String fieldName, List<String> values)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testIncludes_WhenValueIsList_ThenAddIncludesCondition() {
    // Arrange
    List<String> values = new List<String>{ 'Type1', 'Type2' };
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIncludes('Type', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    // Note: this test assert soql building with INCUDES condition is success.
    // If you execute below expected soql, Type field is not multi picklist field, so it will throw exception.
    String expectedSoql = 'SELECT id FROM Account WHERE Type INCLUDES (\'Type1\', \'Type2\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testExcludes_WhenValueIsNull_ThenThrowAtBuildTime() {
    // Arrange
    List<String> value = null;

    // Act & Assert
    Scribe scribe = Scribe.of(Account.class).field('Id').whereExcludes('Type', value);

    // null no longer throws at chain time — the error is deferred to build time,
    // so ignoreWhen() gets a chance to retract the condition first (issue #71)
    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereExcludes(String fieldName, List<String> values)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testExcludes_WhenValueIsList_ThenAddExcludesCondition() {
    // Arrange
    List<String> values = new List<String>{ 'Type1', 'Type2' };
    Scribe scribe = Scribe.of(Account.class).field('Id').whereExcludes('Type', values);

    // Act
    String soql = scribe.toSoql();

    // Assert
    // Note: this test assert soql building with EXCLUDES condition is success.
    // If you execute below expected soql, Type field is not multi picklist field, so it will throw exception.
    String expectedSoql = 'SELECT id FROM Account WHERE Type EXCLUDES (\'Type1\', \'Type2\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIsNull_WhenFieldIsNull_ThenThrowException() {
    // Arrange
    String fieldName = null;

    // Act & Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').whereNull(fieldName);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereNull(String fieldName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testIsNull_WhenFieldIsNotNull_ThenAddIsNullCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNull('Name');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = NULL';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIsNotNull_WhenFieldIsNull_ThenThrowException() {
    // Arrange
    String fieldName = null;

    // Act & Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').whereNotNull(fieldName);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereNotNull(String fieldName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testIsNotNull_WhenFieldIsNotNull_ThenAddIsNotNullCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotNull('Name');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name != NULL';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIgnoreWhen_WhenTrue_ThenPrecedingConditionDropped() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'Test Account')
      .ignoreWhen(true);

    // Act
    String soql = scribe.toSoql();

    // Assert: the preceding WHERE condition is dropped entirely
    String expectedSoql = 'SELECT id FROM Account';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIgnoreWhen_WhenFalse_ThenPrecedingConditionKept() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'Test Account')
      .ignoreWhen(false);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIgnoreWhen_WhenOrConditionIgnored_ThenSoqlDropsIt() {
    // Arrange: the OR condition itself is the ignoreWhen target
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'A')
      .orCondition()
      .whereEqual('Industry', 'B')
      .ignoreWhen(true);

    // Act
    String soql = scribe.toSoql();

    // Assert: the ignored OR condition leaves no trace in the SOQL
    Assert.areEqual('SELECT id FROM Account WHERE Name = \'A\'', soql);
  }

  @isTest
  static void testIgnoreWhen_WhenOrConditionIgnored_ThenAndConditionCanFollow() {
    // Arrange & Act: ignoring the only OR condition must also retract the OR-only mode,
    // so a plain (AND) condition can follow — the query no longer contains any OR
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'A')
      .orCondition()
      .whereEqual('Industry', 'B')
      .ignoreWhen(true)
      .whereEqual('Phone', 'C');

    // Assert
    Assert.areEqual('SELECT id FROM Account WHERE Name = \'A\' AND Phone = \'C\'', scribe.toSoql());
  }

  @isTest
  static void testIgnoreWhen_WhenOrConditionIgnored_ThenExplicitOrStillWorks() {
    // Arrange & Act: an explicit orCondition() after the ignore keeps working
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'A')
      .orCondition()
      .whereEqual('Industry', 'B')
      .ignoreWhen(true)
      .orCondition()
      .whereEqual('Phone', 'C');

    // Assert
    Assert.areEqual('SELECT id FROM Account WHERE Name = \'A\' OR Phone = \'C\'', scribe.toSoql());
  }

  @isTest
  static void testIgnoreWhen_WhenOrConditionRemains_ThenOrOnlyModeIsKept() {
    // Arrange & Act & Assert: A OR B OR C, ignoring C — an OR part still remains,
    // so a plain (AND) condition must still be rejected
    try {
      Scribe.of(Account.class)
        .field('Id')
        .whereEqual('Name', 'A')
        .orCondition()
        .whereEqual('Industry', 'B')
        .orCondition()
        .whereEqual('Phone', 'C')
        .ignoreWhen(true)
        .whereEqual('Fax', 'D');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('orCondition'), e.getMessage());
    }
  }

  @isTest
  static void testOrCondition_WhenFirstConditionIgnored_ThenSurvivorIsSoleCondition() {
    // Arrange & Act: "A OR B" where A is dynamically retracted — the OR degrades
    // to a no-op and B becomes the sole (plain) condition
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'A')
      .ignoreWhen(true)
      .orCondition()
      .whereEqual('Industry', 'B');

    // Assert
    Assert.areEqual('SELECT id FROM Account WHERE Industry = \'B\'', scribe.toSoql());
  }

  @isTest
  static void testOrCondition_WhenBothSidesIgnored_ThenNoWhereClause() {
    // Arrange & Act: both sides of the OR vanish — no WHERE clause at all
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'A')
      .ignoreWhen(true)
      .orCondition()
      .whereEqual('Industry', 'B')
      .ignoreWhen(true);

    // Assert
    Assert.areEqual('SELECT id FROM Account', scribe.toSoql());
  }

  @isTest
  static void testOrCondition_WhenBothSidesKept_ThenOrQuery() {
    // Arrange & Act: the branch-free dynamic form with nothing retracted keeps the OR
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'A')
      .ignoreWhen(false)
      .orCondition()
      .whereEqual('Industry', 'B')
      .ignoreWhen(false);

    // Assert
    Assert.areEqual('SELECT id FROM Account WHERE Name = \'A\' OR Industry = \'B\'', scribe.toSoql());
  }

  @isTest
  static void testOrCondition_WhenNoOp_ThenPlainAndCanFollow() {
    // Arrange & Act: a no-op orCondition() must not raise the OR-only mode —
    // the survivor is a plain first condition and AND conditions may follow
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'A')
      .ignoreWhen(true)
      .orCondition()
      .whereEqual('Industry', 'B')
      .whereEqual('Phone', 'C');

    // Assert
    Assert.areEqual('SELECT id FROM Account WHERE Industry = \'B\' AND Phone = \'C\'', scribe.toSoql());
  }

  @isTest
  static void testIgnoreWhen_WhenNoPrecedingCondition_ThenThrows() {
    // Arrange & Act & Assert: ignoreWhen() before any where...() is a structural misuse
    try {
      Scribe.of(Account.class).field('Id').ignoreWhen(true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('ignoreWhen'));
    }
  }

  @isTest
  static void testIgnoreWhen_WhenNotDirectlyAfterWhere_ThenThrows() {
    // Arrange & Act & Assert: a non-where builder (orderBy) between the where and ignoreWhen is misuse
    try {
      Scribe.of(Account.class)
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .orderBy('Name', 'ASC')
        .ignoreWhen(true);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('ignoreWhen'));
    }
  }

  @isTest
  static void testIgnoreWhen_WhenMultipleConditions_ThenOnlyLastDropped() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Name', 'Test Account')
      .whereEqual('Industry', 'Tech')
      .ignoreWhen(true);

    // Act
    String soql = scribe.toSoql();

    // Assert: only the last-added condition (Industry) is dropped
    String expectedSoql = 'SELECT id FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testIgnoreWhen_WhenAfterWhereGroup_ThenGroupDropped() {
    // Arrange: a grouped condition is also a valid target for ignoreWhen
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('Name', 'Test Opportunity')
      .whereGroup(
        Scribe.asGroup()
          .whereGreaterThan('TotalOpportunityQuantity', 10000)
          .orCondition()
          .whereEqual('Type', 'Test Type')
      )
      .ignoreWhen(true);

    // Act
    String soql = scribe.toSoql();

    // Assert: the whole group is dropped; the preceding condition remains
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Name = \'Test Opportunity\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testOrCondition_WhenAddOrConditionAtFirst_ThenNoOp() {
    // Arrange / Act: since v2.2.0 a leading orCondition() is a no-op (conditions can
    // vanish dynamically via ignoreWhen, so "no condition yet" is a legitimate state) —
    // the following condition simply starts the WHERE clause
    Scribe scribe = Scribe.of(Account.class).field('Id').orCondition().whereEqual('Name', 'Test Account');

    // Assert
    Assert.areEqual('SELECT id FROM Account WHERE Name = \'Test Account\'', scribe.toSoql());
  }

  @isTest
  static void testWhereGroup_WhenApplyNullAsGroup_ThenThrowException() {
    // Arrange
    Scribe groupScribe = null;

    // Act & Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').whereGroup(groupScribe);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereGroup(Scribe groupScribe)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testWhereGroup_WhenAddGroup_ThenAddGroupCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('Name', 'Test Opportunity')
      .whereGroup(
        Scribe.asGroup()
          .whereGreaterThan('TotalOpportunityQuantity', 10000)
          .orCondition()
          .whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Name = \'Test Opportunity\' AND (TotalOpportunityQuantity > 10000 OR Type = \'Test Type\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testWhereGroup_WhenAddOrGroup_ThenAddOrGroupCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('Name', 'Test Opportunity')
      .orCondition()
      .whereGroup(
        Scribe.asGroup()
          .whereGreaterThan('TotalOpportunityQuantity', 10000)
          .orCondition()
          .whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Name = \'Test Opportunity\' OR (TotalOpportunityQuantity > 10000 OR Type = \'Test Type\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testWhereGroup_WhenAddMultiGroup_ThenAddMultiGroupCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('Name', 'Test Opportunity')
      .whereGroup(
        Scribe.asGroup()
          .whereGreaterThan('TotalOpportunityQuantity', 10000)
          .orCondition()
          .whereEqual('Type', 'Test Type')
      )
      .whereGroup(
        Scribe.asGroup()
          .whereLessThan('CloseDate', Date.newInstance(2030, 12, 31))
          .orCondition()
          .whereEqual('StageName', 'Closed Won')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Name = \'Test Opportunity\' AND (TotalOpportunityQuantity > 10000 OR Type = \'Test Type\') AND (CloseDate < 2030-12-31 OR StageName = \'Closed Won\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testWhereGroup_WhenAddAndConditionAfterOrConditionInGroup_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class)
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .whereGroup(
          Scribe.asGroup()
            .whereGreaterThan('TotalOpportunityQuantity', 10000)
            .orCondition()
            .whereEqual('Type', 'Test Type')
            .whereEqual('StageName', 'Closed Won') // This should throw an exception
        );

      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereEqual(String fieldName, Object value)'));
      Assert.isTrue(error.contains('Illegal Logical Transition'));
    }
  }

  @isTest
  static void testWhereGroup_WhenAddAndGroupAfterOrGroup_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class)
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .orCondition()
        .whereGroup(
          Scribe.asGroup()
            .whereGreaterThan('TotalOpportunityQuantity', 10000)
            .orCondition()
            .whereEqual('Type', 'Test Type')
        )
        .whereGroup(
          Scribe.asGroup().whereEqual('StageName', 'Closed Won') // This should throw an exception
        );

      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereGroup(Scribe groupScribe)'));
      Assert.isTrue(error.contains('Illegal Logical Transition'));
    }
  }

  @isTest
  static void testWhereGroup_WhenGroupConditionIsEmpty_ThenIgnoreGroupCondition() {
    // Arrange
    List<Id> Ids = new List<Id>();
    List<String> stages = new List<String>();
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereGroup(Scribe.asGroup().whereNotIn('Id', Ids).whereNotIn('StageName', stages)) // Empty group condition
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testRelationName_WhenApplyNull_ThenThrowException() {
    // Arrange
    String relationName = null;

    // Act & Assert
    try {
      Scribe scribe = Scribe.of(Account.class)
        .field('Id')
        .withChildren(Scribe.asChild(Opportunity.class).relationName(relationName).field('Id').whereNotNull('Name'))
        .whereEqual('Name', 'Test Account');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('relationName(String relationName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testWithChildren_WhenApplyNullAsChildScribe_ThenThrowException() {
    // Arrange
    Scribe childScribe = null;

    // Act & Assert
    try {
      Scribe scribe = Scribe.of(Account.class)
        .field('Id')
        .withChildren(childScribe)
        .whereEqual('Name', 'Test Account');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('withChildren(Scribe childScribe)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testWithChildren_WhenAddNonChildScribe_ThenThrowException() {
    // Arrange
    Scribe nonChildScribe = Scribe.of(Opportunity.class).field('Id').whereNotNull('Name');

    // Act & Assert
    try {
      Scribe scribe = Scribe.of(Account.class)
        .field('Id')
        .withChildren(nonChildScribe)
        .whereEqual('Name', 'Test Account');
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('withChildren(Scribe childScribe)'));
      Assert.isTrue(error.contains('Invalid Scribe Context'));
    }
  }

  @isTest
  static void testWithChildren_ThenAddWithChildrenCondition_ThenAddWithChildrenCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(
        Scribe.asChild(Opportunity.class).relationName('Opportunities').field('Id').whereNotNull('Name')
      )
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT id FROM Opportunities WHERE Name != NULL) FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testWithChildren_WhenNoSelectFieldInRootScribe_ThenGenerateOnlyChildField() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .withChildren(
        Scribe.asChild(Opportunity.class).relationName('Opportunities').field('Id').whereNotNull('Name')
      )
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT (SELECT id FROM Opportunities WHERE Name != NULL) FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testWithChildren_WhenAddParallelWithChildrenCondition_ThenAddParallelWithChildrenCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(
        Scribe.asChild(Opportunity.class).relationName('Opportunities').field('Id').whereNotNull('Name')
      )
      .withChildren(Scribe.asChild(Contact.class).field('Id').whereNotNull('Email'))
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT id FROM Opportunities WHERE Name != NULL), (SELECT id FROM Contacts WHERE Email != NULL) FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testWithChildren_WhenAddNestedWithChildrenCondition_ThenAddNestedWithChildrenCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(
        Scribe.asChild(Contact.class)
          .field('Id')
          .whereNotNull('Name')
          .withChildren(Scribe.asChild(Opportunity.class).field('Id').whereNotNull('Email'))
      )
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT id, (SELECT id FROM Opportunities WHERE Email != NULL) FROM Contacts WHERE Name != NULL) FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testWithChildren_WhenAddWithChildrenConditionAfterOrCondition_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class)
        .field('Id')
        .whereEqual('Name', 'Test Account')
        .orCondition()
        .withChildren(Scribe.asChild(Opportunity.class).field('Id').whereNotNull('Name'));

      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('withChildren(Scribe childScribe)'));
      Assert.isTrue(error.contains('Incomplete Logical Expression'));
    }
  }

  @isTest
  static void testWithChildren_WhenAddOverFourNestChildren_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(
        Scribe.asChild(Contact.class)
          .field('Id')
          .withChildren(
            Scribe.asChild(Case.class)
              .field('Id')
              .withChildren(
                Scribe.asChild(Case.class)
                  .field('Id')
                  .withChildren(
                    Scribe.asChild(Case.class)
                      .field('Id')
                      .withChildren(Scribe.asChild(Case.class).field('Id'))
                  )
              )
          )
      );

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Query Nesting Limit Exceeded'));
    }
  }

  @isTest
  static void testWithChildren_WhenAddOverFourNestChildrenUsingOtherScribeInstance_ThenThrowException() {
    // Arrange
    Scribe caseScribe = Scribe.asChild(Case.class)
      .field('Id')
      .withChildren(
        Scribe.asChild(Case.class)
          .field('Id')
          .withChildren(
            Scribe.asChild(Case.class).field('Id').withChildren(Scribe.asChild(Case.class).field('Id'))
          )
      );

    Scribe accountScribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(Scribe.asChild(Contact.class).field('Id').withChildren(caseScribe));

    // Act / Assert
    try {
      String soql = accountScribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Query Nesting Limit Exceeded'));
    }
  }

  @isTest
  static void testWithChildren_WhenAddRelationName_ThenAddedRelationNameUsed() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(
        Scribe.asChild(Opportunity.class).relationName('Opportunities').field('Id').whereNotNull('Name')
      )
      .whereEqual('Name', 'Test Account');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT id FROM Opportunities WHERE Name != NULL) FROM Account WHERE Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testWithChildren_WhenAddInvalidRelationName_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(
        Scribe.asChild(Opportunity.class).relationName('Opporrunity__r').field('Id').whereNotNull('Name')
      )
      .whereEqual('Name', 'Test Account');

    try {
      // Act
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Invalid Relationship Name'));
    }
  }

  @isTest
  static void testWithChildren_WhenAddNonExistChildObject_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(Scribe.asChild(Product2.class).field('Id').whereNotNull('Name')) // Account does not have Product2 as child object
      .whereEqual('Name', 'Test Account');

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('No Child Relationship Found'));
    }
  }

  @isTest
  static void testWithChildren_WhenMultiRelationFieldWithSameParentExist_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(User.class)
      .field('Id')
      .withChildren(Scribe.asChild(Contract.class).field('Id').whereNotNull('Name'));

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Ambiguous Relationship'));
    }
  }


  @isTest
  static void testWithChildren_WhenUsingAggregateFunction_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class)
      .count('Id', 'NumberOfIds')
      .withChildren(
        Scribe.asChild(Opportunity.class).relationName('Opportunities').field('Id').whereNotNull('Name')
      )
      .whereEqual('Name', 'Test Account');

      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('withChildren(Scribe childScribe)'));
      Assert.isTrue(error.contains('SOQL Aggregate Restriction'));
    }
  }

  @isTest
  static void testParentField_WhenApplyNullAsParentScribe_ThenThrowException() {
    // Arrange
    Scribe parentScribe = null;

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .parentField(parentScribe)
        .whereEqual('Name', 'Test Opportunity');

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('parentField(Scribe parentScribe)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testParentField_WhenApplyNonParentScribe_ThenThrowException() {
    // Arrange
    Scribe nonParentScribe = Scribe.of(Account.class).field('Id').whereNotNull('Name');

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .parentField(nonParentScribe)
        .whereEqual('Name', 'Test Opportunity');

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('parentField(Scribe parentScribe)'));
      Assert.isTrue(error.contains('Invalid Scribe Context'));
    }
  }

  @isTest
  static void testParentField_WhenAddParentScribe_ThenGenerateParentField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParenfField_WhenNoSelectFieldInRootScribe_ThenGenerateOnlyParentField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentField_WhenApplyGroupScribe_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .parentField(Scribe.asGroup())
        .whereEqual('Name', 'Test Opportunity');

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('parentField(Scribe parentScribe)'));
      Assert.isTrue(error.contains('Invalid Scribe Context'));
    }
  }

  @isTest
  static void testParentCondition_WhenAppluNulAsParentScribe_ThenThrowException() {
    // Arrange
    Scribe parentScribe = null;

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .parentCondition(parentScribe)
        .whereEqual('Name', 'Test Opportunity');

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('parentCondition(Scribe parentScribe)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testParentCondition_WhenApplyNonParentScribe_ThenThrowException() {
    // Arrange
    Scribe nonParentScribe = Scribe.of(Account.class).field('Id').whereNotNull('Name');

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .parentCondition(nonParentScribe)
        .whereEqual('Name', 'Test Opportunity');

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('parentCondition(Scribe parentScribe)'));
      Assert.isTrue(error.contains('Invalid Scribe Context'));
    }
  }

  @isTest
  static void testParentCondition_AddParentScribe_ThenAddParentCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentCondition(Scribe.asParent('AccountId').whereEqual('Name', 'Test Account'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Account.Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentCondition_AddGroupScribe_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .parentCondition(Scribe.asGroup().whereEqual('Name', 'Test Account'));

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('parentCondition(Scribe parentScribe)'));
      Assert.isTrue(error.contains('Invalid Scribe Context'));
    }
  }

  @isTest
  static void testParentFieldAndCondition_WhenAddWithParentCondition_ThenAddWithParentCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(Scribe.asParent('AccountId').whereEqual('Name', 'Test Account'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Account.Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentFieldAndCondition_WhenAddWithParentMultipleCondition_ThenAddWithParentMultipleCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        Scribe.asParent('AccountId').whereEqual('Name', 'Test Account').whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Account.Name = \'Test Account\' AND Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentCondition_WhenAddWithParentMultipleConditionByAnotherMethod_ThenAddWithParentMultipleCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(Scribe.asParent('AccountId').whereEqual('Name', 'Test Account'))
      .parentCondition(Scribe.asParent('AccountId').whereEqual('Type', 'Test Type'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Account.Name = \'Test Account\' AND Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentCondition_WhenAddOrConditionParent_ThenAddOrConditionParent() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        Scribe.asParent('AccountId')
          .whereEqual('Name', 'Test Account')
          .orCondition()
          .whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Account.Name = \'Test Account\' OR Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentCondition_WhenAddParentConditionAfterOrCondition_ThenThrownError() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
        .whereEqual('Name', 'Test Opportunity')
        .orCondition()
        .parentCondition(
          Scribe.asParent('AccountId')
            .whereEqual('Name', 'Test Account')
            .orCondition()
            .whereEqual('Type', 'Test Type')
        );

      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('parentCondition(Scribe parentScribe)'));
      Assert.isTrue(error.contains('Incomplete Logical Expression'));
    }
  }

  @isTest
  static void testParentCondition_WhenAddParentOrConditionAfterOrCondition_ThenAddOrParentCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        Scribe.asParent('AccountId')
          .orCondition()
          .whereEqual('Name', 'Test Account')
          .orCondition()
          .whereEqual('Type', 'Test Type')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' OR Account.Name = \'Test Account\' OR Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentCondition_WhenAddOrConditionAtFirstInParentCondition_ThenAddOrParentCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(Scribe.asParent('AccountId').orCondition().whereEqual('Name', 'Test Account'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' OR Account.Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentCondition_WhenAddOrConditionParentAsGroup_ThenAddOrConditionParentAsasGroup() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity')
      .whereGroup(
        Scribe.asGroup()
          .parentCondition(
            Scribe.asParent('AccountId')
              .whereEqual('Name', 'Test Account')
              .orCondition()
              .whereEqual('Type', 'Test Type')
          )
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Account.name, Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND (Account.Name = \'Test Account\' OR Account.Type = \'Test Type\')';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentFieldAndCondition_WhenAddNestedParent_ThenAddNestedParentCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(
        Scribe.asParent('ContractId')
          .field('Id')
          .field('Name')
          .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      )
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        Scribe.asParent('ContractId')
          .whereEqual('Name', 'Test Contract')
          .parentCondition(Scribe.asParent('AccountId').whereEqual('Name', 'Test Account'))
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Contract.id, Contract.name, Contract.Account.name, Contract.Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Contract.Name = \'Test Contract\' AND Contract.Account.Name = \'Test Account\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentFieldAndCondition_WhenAddThreeNestedParentOrCondition_ThenAddNestedParentCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(
        Scribe.asParent('ContractId')
          .field('Id')
          .field('Name')
          .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      )
      .whereEqual('Name', 'Test Opportunity')
      .parentCondition(
        Scribe.asParent('ContractId')
          .whereEqual('Name', 'Test Contract')
          .parentCondition(
            Scribe.asParent('AccountId').whereEqual('Name', 'Test Account').whereEqual('Type', 'Test Type')
          )
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, Contract.id, Contract.name, Contract.Account.name, Contract.Account.id FROM Opportunity WHERE Name = \'Test Opportunity\' AND Contract.Name = \'Test Contract\' AND Contract.Account.Name = \'Test Account\' AND Contract.Account.Type = \'Test Type\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentCondition_WhenAddAndConditionAfterOrParentCondition_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .parentCondition(
        Scribe.asParent('AccountId')
          .whereEqual('Name', 'Test Account')
          .orCondition()
          .whereEqual('Type', 'Test Type')
      )
      .whereEqual('Name', 'Test Opportunity');

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Logical Operator Mismatch'));
      Assert.isTrue(error.contains('A condition following an orWhere() must also be an OR condition to maintain logical consistency.'));
    }
  }

  @isTest
  static void testParentCondition_WhenAddAndConditionAfterNestedOrParentCondition_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .parentCondition(
        Scribe.asParent('ContractId')
          .whereEqual('Name', 'Test Contract')
          .parentCondition(
            Scribe.asParent('AccountId')
              .whereEqual('Name', 'Test Account')
              .orCondition()
              .whereEqual('Type', 'Test Type')
          )
      )
      .whereEqual('Name', 'Test Opportunity');

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Logical Operator Mismatch'));
      Assert.isTrue(error.contains('A condition following an orWhere() must also be an OR condition to maintain logical consistency.'));
    }
  }

  @isTest
  static void testParentCondition_WhenAddEmptyList_ThenInogreParentCondition() {
    // Arrange
    Scribe scribe = Scribe.of(OpportunityLineItem.class)
      .field('Id')
      .whereEqual('Name', 'Test OLI')
      .parentCondition(Scribe.asParent('OpportunityId').whereNotIn('Id', new List<Id>()));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM OpportunityLineItem WHERE Name = \'Test OLI\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentCondition_WhenAddEmptyLists_ThenInogreParentCondition_2() {
    // Arrange
    Scribe scribe = Scribe.of(OpportunityLineItem.class)
      .field('Id')
      .whereEqual('Name', 'Test OLI')
      .parentCondition(
        Scribe.asParent('OpportunityId')
          .whereNotIn('Id', new List<Id>())
          .whereNotIn('StageName', new List<String>())
          .WhereLike('Name', 'Test%')
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM OpportunityLineItem WHERE Name = \'Test OLI\' AND Opportunity.Name LIKE \'Test%\'';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testParentField_WhenAddOverFourNestedParentField_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(OrderItem.class)
      .field('Id')
      .parentField(
        Scribe.asParent('OrderId')
          .field('Id')
          .parentField(
            Scribe.asParent('OriginalOrderId')
              .field('Id')
              .parentField(
                Scribe.asParent('ContractId')
                  .field('Id')
                  .parentField(
                    Scribe.asParent('AccountId')
                      .field('Id')
                      .parentField(
                        Scribe.asParent('ParentId')
                          .field('Id')
                          .parentField(Scribe.asParent('ParentId').field('Id'))
                      )
                  )
              )
          )
      );

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('Maximum nesting depth for parent queries reached'), 'should mention nesting depth limit');
      Assert.isTrue(error.contains('[maxDepth => 5]'), 'should include the max depth limit');
      Assert.isTrue(error.contains('[objectName => \'Account\']'), 'should include the object name');
    }
  }

  @isTest
  static void testBuildFieldStructure_WhenAddField_ThenReturnFieldStructure() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').field('Name').field('Type');

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasField('name'));
    Assert.isTrue(fieldStructure.hasField('type'));
    Assert.isFalse(fieldStructure.hasField('nonSelectedField'));
  }

  @isTest
  static void testBuildFieldStructure_WhenAddParentField_ThenReturnFieldStructureWithParentFields() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .parentField(Scribe.asParent('AccountId').field('Name').field('Id'))
      .parentField(Scribe.asParent('ContractId').field('Name').field('Id'))
      .whereEqual('Name', 'Test Opportunity');

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasRelation('accountid'));
    FieldStructure accountFieldStructure = fieldStructure.getRelationFieldStructure('accountid');
    Assert.isTrue(accountFieldStructure.hasField('name'));
    Assert.isTrue(accountFieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasRelation('contractid'));
    FieldStructure contractFieldStructure = fieldStructure.getRelationFieldStructure('contractid');
    Assert.isTrue(contractFieldStructure.hasField('name'));
    Assert.isTrue(contractFieldStructure.hasField('id'));
  }

  @isTest
  static void testBuildFieldStructure_WhenAddNestedParentField_ThenReturnFieldStructureWithNestedParentFields() {
    // Arrange
    List<String> fields = new List<String>{ 'Id', 'Name' };
    Scribe scribe = Scribe.of(OrderItem.class)
      .field('id')
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

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasField('listprice'));
    Assert.isTrue(fieldStructure.hasRelation('orderid'));
    FieldStructure orderFieldStructure = fieldStructure.getRelationFieldStructure('orderid');
    Assert.isTrue(orderFieldStructure.hasField('id'));
    Assert.isTrue(orderFieldStructure.hasField('name'));
    Assert.isTrue(orderFieldStructure.hasRelation('originalorderid'));
    FieldStructure originalOrderFieldStructure = orderFieldStructure.getRelationFieldStructure('originalorderid');
    Assert.isTrue(originalOrderFieldStructure.hasField('id'));
    Assert.isTrue(originalOrderFieldStructure.hasField('name'));
    Assert.isTrue(originalOrderFieldStructure.hasRelation('contractid'));
    FieldStructure contractFieldStructure = originalOrderFieldStructure.getRelationFieldStructure('contractid');
    Assert.isTrue(contractFieldStructure.hasField('id'));
    Assert.isTrue(contractFieldStructure.hasField('name'));
    Assert.isTrue(contractFieldStructure.hasRelation('accountid'));
    FieldStructure accountFieldStructure2 = contractFieldStructure.getRelationFieldStructure('accountid');
    Assert.isTrue(accountFieldStructure2.hasField('id'));
    Assert.isTrue(accountFieldStructure2.hasField('name'));
    Assert.isTrue(accountFieldStructure2.hasRelation('parentid'));
    FieldStructure parentFieldStructure = accountFieldStructure2.getRelationFieldStructure('parentid');
    Assert.isTrue(parentFieldStructure.hasField('id'));
    Assert.isTrue(parentFieldStructure.hasField('name'));
  }

  @isTest
  static void testBuildFieldStructure_WhenAddWithChildren_ThenReturnFieldStructureWithChildren() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .withChildren(Scribe.asChild(Opportunity.class).field('Id').field('Name'))
      .withChildren(Scribe.asChild(Contact.class).field('Id').field('Email'));

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasRelation('opportunity'));
    FieldStructure opportunitiesFieldStructure = fieldStructure.getRelationFieldStructure('opportunity');
    Assert.isTrue(opportunitiesFieldStructure.hasField('id'));
    Assert.isTrue(opportunitiesFieldStructure.hasField('name'));
    Assert.isTrue(fieldStructure.hasRelation('contact'));
    FieldStructure contactsFieldStructure = fieldStructure.getRelationFieldStructure('contact');
    Assert.isTrue(contactsFieldStructure.hasField('id'));
    Assert.isTrue(contactsFieldStructure.hasField('email'));
    Assert.isFalse(contactsFieldStructure.hasField('name'));
  }

  @isTest
  static void testBuildFieldStructure_WhenAddNestedChildrenField_ThenReturnFieldStructureWithNestedChildren() {
    // Arrange
    List<String> fields = new List<String>{ 'Id', 'OwnerId' };
    Scribe scribe = Scribe.of(Account.class)
      .fields(fields)
      .withChildren(
        Scribe.asChild(Contact.class)
          .fields(fields)
          .withChildren(
            Scribe.asChild(Case.class)
              .fields(fields)
              .withChildren(
                Scribe.asChild(Case.class).fields(fields).withChildren(Scribe.asChild(Case.class).fields(fields))
              )
          )
      );

    // Act
    FieldStructure fieldStructure = scribe.buildFieldStructure();

    // Assert
    Assert.isTrue(fieldStructure.hasField('id'));
    Assert.isTrue(fieldStructure.hasField('ownerid'));
    Assert.isTrue(fieldStructure.hasRelation('contact'));
    FieldStructure contactFieldStructure = fieldStructure.getRelationFieldStructure('contact');
    Assert.isTrue(contactFieldStructure.hasField('id'));
    Assert.isTrue(contactFieldStructure.hasField('ownerid'));
    Assert.isTrue(contactFieldStructure.hasRelation('case'));
    FieldStructure caseFieldStructure1 = contactFieldStructure.getRelationFieldStructure('case');
    Assert.isTrue(caseFieldStructure1.hasField('id'));
    Assert.isTrue(caseFieldStructure1.hasField('ownerid'));
    Assert.isTrue(caseFieldStructure1.hasRelation('case'));
    FieldStructure caseFieldStructure2 = caseFieldStructure1.getRelationFieldStructure('case');
    Assert.isTrue(caseFieldStructure2.hasField('id'));
    Assert.isTrue(caseFieldStructure2.hasField('ownerid'));
    Assert.isTrue(caseFieldStructure2.hasRelation('case'));
    FieldStructure caseFieldStructure3 = caseFieldStructure2.getRelationFieldStructure('case');
    Assert.isTrue(caseFieldStructure3.hasField('id'));
    Assert.isTrue(caseFieldStructure3.hasField('ownerid'));
    Assert.isFalse(caseFieldStructure3.hasField('email'));
  }

  @isTest
  static void testTake_WhenApplyNull_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').take(null);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('take(Integer limitNumber)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testTake_WhenAddTake_ThenReturnLimitSoql() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').take(10);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account LIMIT 10';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testTake_WhenAddZeroTake_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').take(0);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('take(Integer limitNumber)'));
      Assert.isTrue(error.contains('The limit number cannot be negative.'));
    }
  }

  @isTest
  static void testOrderBy_WhenAddField_ThenReturnOrderByField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('Id', '006000000000000')
      .orderBy('CloseDate');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Id = \'006000000000000\' ORDER BY CloseDate ASC';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testOrderBy_WhenAddFieldAndOrder_ThenReturnOrderByFieldAndOrder() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('Id', '006000000000000')
      .orderBy('CloseDate', 'DESC');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Id = \'006000000000000\' ORDER BY CloseDate DESC';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testOrderBy_WhenAddFieldAndOrderAndNullsOperator_ThenReturnOrderByFieldAndOrderAndNullsOperator() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('Id', '006000000000000')
      .orderBy('CloseDate', 'ASC', 'FIRST');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE Id = \'006000000000000\' ORDER BY CloseDate ASC NULLS FIRST';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testOrderBy_WhenAddMultipleOrderBy_ThenReturnMultipleOrderBy_1() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('StageName', 'prospecting')
      .orderBy('CloseDate', 'ASC', 'FIRST')
      .orderBy('Amount', 'DESC', 'LAST');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE StageName = \'prospecting\' ORDER BY CloseDate ASC NULLS FIRST, Amount DESC NULLS LAST';
    Assert.areEqual(expectedSoql, soql);
  }
  @isTest
  static void testOrderBy_WhenAddMultipleOrderBy_ThenReturnMultipleOrderBy_2() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereEqual('StageName', 'prospecting')
      .orderBy('CloseDate')
      .orderBy('Amount');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE StageName = \'prospecting\' ORDER BY CloseDate ASC, Amount ASC';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testOrderBy_WhenAddBlankField_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).field('Id').whereEqual('Id', '006000000000000').orderBy('');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('Scribe.OrderByClause'), 'should locate in Scribe.OrderByClause');
      Assert.isTrue(error.contains('Missing required parameter'), 'should indicate required-parameter violation');
    }
  }

  @isTest
  static void testOrderBy_WhenaddInvalidOrder_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .whereEqual('Id', '006000000000000')
        .orderBy('CloseDate', 'INVALID');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('Scribe.OrderByClause'), 'should locate in Scribe.OrderByClause');
      Assert.isTrue(error.contains('Invalid order direction'), 'should mention the invalid direction');
      Assert.isTrue(error.contains('[order => \'INVALID\']'), 'should include the rejected value');
    }
  }

  @isTest
  static void testOrderBy_WhenaddInvalidNullsOperator_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id')
        .whereEqual('Id', '006000000000000')
        .orderBy('CloseDate', 'ASC', 'INVALID');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('Scribe.OrderByClause'), 'should locate in Scribe.OrderByClause');
      Assert.isTrue(error.contains('Invalid nulls operator'), 'should mention invalid nulls operator');
      Assert.isTrue(error.contains('[nullsOperator => \'INVALID\']'), 'should include the rejected value');
    }
  }

  @isTest
  static void testOffset_WhenApplyNull_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').offset(null);
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('offset(Integer offsetNumber)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testOffset_WhenAddOffset_ThenReturnOffsetSoql() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').offset(10);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account OFFSET 10';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testOffset_WhenAddNegativeOffset_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').offset(-1);
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('offset(Integer offsetNumber)'));
      Assert.isTrue(error.contains('The offset number cannot be negative.'));
    }
  }

  @isTest
  static void testOffset_WhenAddOffsetOver2000_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').offset(2001);
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('offset(Integer offsetNumber)'));
      Assert.isTrue(error.contains('Salesforce SOQL has a maximum offset limit of 2000 records.'));
    }
  }

  @isTest
  static void testForUpdate_WhenAddForUpdate_ThenReturnForUpdateSoql() {
    // Arrange
    Scribe scribe = Scribe.of(Account.class).field('Id').forUpdate();

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Account FOR UPDATE';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testSoqlClauseOrder_WhenAddVariousClauses_ThenReturnCorrectClauseOrder_1() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .forUpdate()
      .take(10)
      .field('Id')
      .whereEqual('StageName', 'prospecting');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE StageName = \'prospecting\' LIMIT 10 FOR UPDATE';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testSoqlClauseOrder_WhenAddVariousClauses_ThenReturnCorrectClauseOrder_2() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .offset(5)
      .take(10)
      .field('Id')
      .orderBy('CloseDate', 'ASC', 'FIRST')
      .whereEqual('StageName', 'prospecting');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id FROM Opportunity WHERE StageName = \'prospecting\' ORDER BY CloseDate ASC NULLS FIRST LIMIT 10 OFFSET 5';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testForUpdate_WhenWithOrderByClause_ThenThrowException_1() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').orderBy('Name').forUpdate();
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Order By Conflict'));
    }
  }

  @isTest
  static void testForUpdate_WhenWithOrderByClause_ThenThrowException_2() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').forUpdate().orderBy('Name');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Order By Conflict'));
    }
  }

  @isTest
  static void testForUpdate_WhenWithOffsetClause_ThenThrowException_1() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').offset(10).forUpdate();
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Offset Conflict'));
    }
  }

  @isTest
  static void testForUpdate_WhenWithOffsetClause_ThenThrowException_2() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Account.class).field('Id').forUpdate().offset(10);
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Offset Conflict'));
    }
  }

  @isTest
  static void testAverage_WhenApplyNullToFieldName_ThenThrowException() {
    // Arrange
    String fieldName = null;
    String alias = 'amountAvg';

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).average(fieldName, alias);
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('average(String fieldName, String alias)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAverage_WhenAplyVoidStringToFieldName_ThenThrowException() {
    // Arrange
    String fieldName = '';
    String alias = 'amountAvg';

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).average(fieldName, alias);
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('average(String fieldName, String alias)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAverage_WhenApplyNullToAlias_ThenThrowException() {
    // Arrange
    String fieldName = 'Amount';
    String alias = null;

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).average(fieldName, alias);
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('average(String fieldName, String alias)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAverage_WhenApplyVoidStringToAlias_ThenThrowException() {
    // Arrange
    String fieldName = 'Amount';
    String alias = '';

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).average(fieldName, alias);
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('average(String fieldName, String alias)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testAverage_WhenUsedWithAsChild_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.asChild(Opportunity.class).average('Amount', 'amountAvg');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('average(String fieldName, String alias)'));
      Assert.isTrue(error.contains('Aggregate Function Forbidden'));
    }
  }

  @isTest
  static void testAverage_WhenUsedWithAsHaving_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.asHaving().average('Amount', 'amountAvg');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('average(String fieldName, String alias)'));
      Assert.isTrue(error.contains('Aggregate Function Forbidden'));
    }
  }

  @isTest
  static void testAverage_WhenAddAverageField_ThenReturnAverageField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).average('Amount', 'amountAvg');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT AVG(Amount) amountAvg FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testAverage_WhenAddNonExistFieldToAverage_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).average('NonExistField', 'amountAvg');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('AbstractAggregateClause'), 'should locate in AbstractAggregateClause');
      Assert.isTrue(error.contains('fieldName'), 'should mention fieldName param');
      Assert.isTrue(error.contains('NonExistField'), 'should include the provided field name');
    }
  }

  @isTest
  static void testAverage_WhenAddNonSupportedFieldToAverage_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).average('Name', 'nameAvg');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('AverageClause'), 'should locate in AverageClause');
      Assert.isTrue(error.contains('AVG()'), 'should mention AVG()');
      Assert.isTrue(error.contains('STRING'), 'should include the rejected field type');
    }
  }

  @isTest
  static void testAverage_WhenAddAfterWithChildren_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .withChildren(Scribe.asChild(Contact.class).field('Id').field('Email'))
        .average('Amount', 'amountAvg');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('average(String fieldName, String alias)'));
      Assert.isTrue(error.contains('SOQL Aggregate Restriction'));
    }
  }

  @isTest
  static void testCount_WhenApplyNullToFieldName_ThenThrowException() {
    // Arrange
    String fieldName = null;
    String alias = 'oppCount';

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).count(fieldName, alias);
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('count(String fieldName, String alias)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testCount_WhenAddCountField_ThenReturnCountField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).count('Id', 'oppCount');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT COUNT(Id) oppCount FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testToSoql_WhenCalledTwiceWithCount_ThenReturnsSameSoqlIdempotently() {
    // Reproduces the "Duplicate Alias Error" that occurred when toSoql() was called twice
    // on an aggregate query. Mirrors the MockEloquent scenario where the framework calls
    // toSoql() once internally and the test then calls it a second time for assertions.
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).count('Id', 'oppCount');
    String expectedSoql = 'SELECT COUNT(Id) oppCount FROM Opportunity';

    // Act
    String firstSoql = scribe.toSoql();
    String secondSoql = scribe.toSoql();

    // Assert
    Assert.areEqual(expectedSoql, firstSoql, 'First toSoql() should return the expected SOQL');
    Assert.areEqual(expectedSoql, secondSoql, 'Second toSoql() should return the same SOQL (idempotent)');
  }

  @isTest
  static void testToSoql_WhenCalledTwiceWithoutExplicitFields_ThenReturnsSameSoql() {
    // Confirms that the side effect in validateAndInitialize() — auto-adding 'Id' to
    // selectFields when no field is specified — does not break idempotency of a second toSoql() call.
    // Arrange
    Scribe scribe = Scribe.of(Account.class);

    // Act
    String firstSoql = scribe.toSoql();
    String secondSoql = scribe.toSoql();

    // Assert
    Assert.areEqual(firstSoql, secondSoql, 'toSoql() should be idempotent without explicit fields');
  }

  @isTest
  static void testToSoql_WhenCalledTwiceWithMultipleAggregates_ThenReturnsSameSoql() {
    // Confirms that calling toSoql() twice with multiple aggregates (sum + count) returns the same SOQL.
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .sum('Amount', 'totalAmount')
      .count('Id', 'oppCount');

    // Act
    String firstSoql = scribe.toSoql();
    String secondSoql = scribe.toSoql();

    // Assert
    Assert.areEqual(firstSoql, secondSoql, 'toSoql() with multiple aggregates should be idempotent');
  }

  @isTest
  static void testToSoql_WhenCalledTwiceWithAggregateAndHaving_ThenReturnsSameSoql() {
    // Confirms idempotency when aggregate is combined with HAVING.
    // HAVING reads aggregateAliasMap after buildSelectFields populates it, so this path is
    // particularly sensitive to the map being reset properly on each toSoql() call.
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .sum('Amount', 'totalAmount')
      .groupByField('StageName')
      .havingCondition(Scribe.asHaving().whereGreaterThan('totalAmount', 1000));

    // Act
    String firstSoql = scribe.toSoql();
    String secondSoql = scribe.toSoql();

    // Assert
    Assert.areEqual(firstSoql, secondSoql, 'toSoql() with aggregate + HAVING should be idempotent');
  }

  @isTest
  static void testToSoql_WhenCalledTwiceWithParentField_ThenReturnsSameSoql() {
    // Confirms idempotency for a query with a parent field (parentField path).
    // Verifies that the map state inside ParentScribe.buildSelectClause is also reset between calls.
    // Arrange
    Scribe scribe = Scribe.of(OpportunityLineItem.class)
      .field('Id')
      .parentField(Scribe.asParent('OpportunityId').field('Name'));

    // Act
    String firstSoql = scribe.toSoql();
    String secondSoql = scribe.toSoql();

    // Assert
    Assert.areEqual(firstSoql, secondSoql, 'toSoql() with parent field should be idempotent');
  }

  @isTest
  static void testCount_WhenAddNonExistFieldToCount_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).count('NonExistField', 'oppCount');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('AbstractAggregateClause'), 'should locate in AbstractAggregateClause');
      Assert.isTrue(error.contains('fieldName'), 'should mention fieldName param');
      Assert.isTrue(error.contains('NonExistField'), 'should include the provided field name');
    }
  }

  @isTest
  static void testCount_WhenAddNonSupportedFieldToCount_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).count('IsPrivate', 'countIsPrivate');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('CountClause'), 'should locate in CountClause');
      Assert.isTrue(error.contains('COUNT()'), 'should mention COUNT()');
      Assert.isTrue(error.contains('BOOLEAN'), 'should include the rejected field type');
    }
  }

  @isTest
  static void testCountDistinct_WhenAddCountDistinctField_ThenReturnCountDistinctField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).countDistinct('AccountId', 'accountCount');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT COUNT_DISTINCT(AccountId) accountCount FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testCountDistinct_WhenAddNonExistFieldToCountDistinct_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).countDistinct('NonExistField', 'accountCount');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('AbstractAggregateClause'), 'should locate in AbstractAggregateClause');
      Assert.isTrue(error.contains('fieldName'), 'should mention fieldName param');
      Assert.isTrue(error.contains('NonExistField'), 'should include the provided field name');
    }
  }

  @isTest
  static void testCountDistinct_WhenAddNonSupportedFieldToCountDistinct_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).countDistinct('IsPrivate', 'countDistinctIsPrivate');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('CountDistinctClause'), 'should locate in CountDistinctClause');
      Assert.isTrue(error.contains('COUNT_DISTINCT()'), 'should mention COUNT_DISTINCT()');
      Assert.isTrue(error.contains('BOOLEAN'), 'should include the rejected field type');
    }
  }

  @isTest
  static void testMax_WhenAddMaxField_ThenReturnMaxField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).max('Amount', 'amountMax');

    // ActionLinkGroupTemplate
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT MAX(Amount) amountMax FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testMax_WhenAddNonExistFieldToMax_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).max('NonExistField', 'amountMax');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('AbstractAggregateClause'), 'should locate in AbstractAggregateClause');
      Assert.isTrue(error.contains('fieldName'), 'should mention fieldName param');
      Assert.isTrue(error.contains('NonExistField'), 'should include the provided field name');
    }
  }

  @isTest
  static void testMax_WhenAddNonSupportedFieldToMax_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).max('IsPrivate', 'maxIsPrivate');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('MaxClause'), 'should locate in MaxClause');
      Assert.isTrue(error.contains('MAX()'), 'should mention MAX()');
      Assert.isTrue(error.contains('BOOLEAN'), 'should include the rejected field type');
    }
  }

  @isTest
  static void testMin_WhenAddMinField_ThenReturnMinField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).min('Amount', 'amountMin');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT MIN(Amount) amountMin FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testMin_WhenAddNonExistFieldToMin_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).min('NonExistField', 'amountMin');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('AbstractAggregateClause'), 'should locate in AbstractAggregateClause');
      Assert.isTrue(error.contains('fieldName'), 'should mention fieldName param');
      Assert.isTrue(error.contains('NonExistField'), 'should include the provided field name');
    }
  }

  @isTest
  static void testMin_WhenAddNonSupportedFieldToMin_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).min('IsPrivate', 'minIsPrivate');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('MinClause'), 'should locate in MinClause');
      Assert.isTrue(error.contains('MIN()'), 'should mention MIN()');
      Assert.isTrue(error.contains('BOOLEAN'), 'should include the rejected field type');
    }
  }

  @isTest
  static void testSum_WhenAddSumField_ThenReturnSumField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class).sum('Amount', 'amountSum');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT SUM(Amount) amountSum FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testSum_WhenAddNonExistFieldToSum_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).sum('NonExistField', 'amountSum');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('AbstractAggregateClause'), 'should locate in AbstractAggregateClause');
      Assert.isTrue(error.contains('fieldName'), 'should mention fieldName param');
      Assert.isTrue(error.contains('NonExistField'), 'should include the provided field name');
    }
  }

  @isTest
  static void testSum_WhenAddNonSupportedFieldToSum_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).sum('Name', 'nameSum');
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('SumClause'), 'should locate in SumClause');
      Assert.isTrue(error.contains('SUM()'), 'should mention SUM()');
      Assert.isTrue(error.contains('STRING'), 'should include the rejected field type');
    }
  }

  @isTest
  static void testAllAggregateFunctions_WhenAddAllAggregateFunctions_ThenReturnAllAggregateFunctions() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .average('Amount', 'amountAvg')
      .count('Id', 'oppCount')
      .countDistinct('AccountId', 'accountCount')
      .max('Amount', 'amountMax')
      .min('Amount', 'amountMin')
      .sum('Amount', 'amountSum');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT AVG(Amount) amountAvg, COUNT(Id) oppCount, COUNT_DISTINCT(AccountId) accountCount, MAX(Amount) amountMax, MIN(Amount) amountMin, SUM(Amount) amountSum FROM Opportunity';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testAggregateFunctions_WhenAddSameAlias_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class).average('Amount', 'amountAlias').count('Id', 'amountAlias'); // Duplicate alias
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Duplicate Alias Error'));
    }
  }

  @isTest
  static void testGroupByField_WhenApplyNull_ThenThrowException() {
    // Arrange
    String fieldName = null;

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByField(fieldName);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('groupByField(String fieldName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGroupByField_WhenApplyVoidString_ThenThrowException() {
    // Arrange
    String fieldName = '';

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByField(fieldName);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('groupByField(String fieldName)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGroupByField_WhenAddGroupByField_ThenReturnGroupByField() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'amountAvg')
      .groupByField('StageName');

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT stagename, AVG(Amount) amountAvg FROM Opportunity GROUP BY StageName';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testGroupByField_WhenSelectedFieldNotInGroupBy_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('Id') // Id is not in GROUP BY
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByField('StageName');

      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('There are fields in the SELECT clause that are not included in the GROUP BY clause'), 'should mention the SELECT/GROUP BY mismatch');
      Assert.isTrue(error.contains('[nonGroupedFields => \'id\']'), 'should include the non-grouped fields list');
    }
  }

  @isTest
  static void testGroupByFields_WhenApplyNull_ThenThrowException() {
    // Arrange
    List<String> fieldNames = null;

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByFields(fieldNames);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('groupByFields(List<String> fieldNames)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGroupByFields_WhenApplyEmptyList_ThenThrowException() {
    // Arrange
    List<String> fieldNames = new List<String>();

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByFields(fieldNames);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('groupByFields(List<String> fieldNames)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGroupByFields_WhenApplyNullInList_ThenThrowException() {
    // Arrange
    List<String> fieldNames = new List<String>{ 'StageName', null };

    // Act / Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByFields(fieldNames);
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('groupByFields(List<String> fieldNames)'));
      Assert.isTrue(error.contains('string value in fieldnames argument must not be null or blank'));
    }
  }

  @isTest
  static void testGroupByFields_WhenAddGroupByFields_ThenReturnGroupByFields() {
    // Arrange
    List<String> fields = new List<String>{ 'StageName', 'CloseDate' };
    Scribe scribe = Scribe.of(Opportunity.class)
      .fields(fields)
      .average('Amount', 'amountAvg')
      .groupByFields(fields);

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT stagename, closedate, AVG(Amount) amountAvg FROM Opportunity GROUP BY StageName, CloseDate';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testGroupByFields_WhenSelectedFieldNotInGroupBy_ThenThrowException() {
    // Arrange
    List<String> fields = new List<String>{ 'StageName', 'CloseDate' };
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id') // Id is not in GROUP BY
      .fields(fields)
      .average('Amount', 'amountAvg')
      .groupByFields(fields);

    // Act & Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('There are fields in the SELECT clause that are not included in the GROUP BY clause'), 'should mention the SELECT/GROUP BY mismatch');
      Assert.isTrue(error.contains('[nonGroupedFields => \'id\']'), 'should include the non-grouped fields list');
    }
  }

  @isTest
  static void testGroupByField_WhenUsingAfterWithChildrenMethod_ThenThrownException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .withChildren(Scribe.asChild(Contact.class).field('Id').field('Email'))
        .groupByField('StageName')
        .average('Amount', 'amountAvg');
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('groupByField(String fieldName)'));
      Assert.isTrue(error.contains('SOQL Aggregate Restriction'));
    }
  }

  @isTest
  static void testHavingCondition_WhenApplyNull_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'amountAvg')
      .groupByField('StageName');

    // Act & Assert
    try {
      scribe.havingCondition(null);
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('havingCondition(Scribe havingScribe)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testHavingCondition_WhenUsedWithoutGroupByMethod_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .havingCondition(Scribe.asHaving().whereGreaterThan('amountAvg', 10000));
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('havingCondition(Scribe havingScribe)'));
      Assert.isTrue(error.contains('Missing Required Clause: GROUP BY'));
    }
  }

  @isTest
  static void testHavingCondition_WhenScribeNotCreatedAsHaving_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByField('StageName')
        .havingCondition(Scribe.of(Opportunity.class).whereGreaterThan('amountAvg', 10000));
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('havingCondition(Scribe havingScribe)'));
      Assert.isTrue(error.contains('The provided Scribe instance was not initialized asHaving()'));
    }
  }

  @isTest
  static void testHavingCondition_WhenAddHavingCondition_ThenReturnHavingCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'amountAvg')
      .groupByField('StageName')
      .havingCondition(Scribe.asHaving().whereGreaterThan('amountAvg', 10000));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT stagename, AVG(Amount) amountAvg FROM Opportunity GROUP BY StageName HAVING AVG(Amount) > 10000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testHavingCondition_WhenAddMultiHavingCondition_ThenReturnHavingCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'amountAvg')
      .groupByField('StageName')
      .havingCondition(Scribe.asHaving().whereGreaterThan('amountAvg', 10000).whereLessThan('amountAvg', 50000));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT stagename, AVG(Amount) amountAvg FROM Opportunity GROUP BY StageName HAVING AVG(Amount) > 10000 AND AVG(Amount) < 50000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testHavingCondition_WhenAddMultiHavingConditionUsingOr_ThenReturnHavingCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'amountAvg')
      .groupByField('StageName')
      .havingCondition(
        Scribe.asHaving().whereGreaterThan('amountAvg', 10000).orCondition().whereLessThan('amountAvg', 50000)
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT stagename, AVG(Amount) amountAvg FROM Opportunity GROUP BY StageName HAVING AVG(Amount) > 10000 OR AVG(Amount) < 50000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testHavingCondition_WhenMaxAndCount_ThenMaxIsCastAndCountIsNotCast() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .max('Name', 'maxName')
      .count('Name', 'nameCount')
      .groupByField('StageName')
      .havingCondition(
        Scribe.asHaving().whereGreaterThan('maxName', 'lastOppName').whereGreaterThan('nameCount', 10)
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT stagename, MAX(Name) maxName, COUNT(Name) nameCount FROM Opportunity GROUP BY StageName HAVING MAX(Name) > \'lastOppName\' AND COUNT(Name) > 10';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testHavingCondition_WhenHavingNonExistAlias_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByField('StageName')
        .havingCondition(Scribe.asHaving().whereGreaterThan('nonExistAlias', 10000));
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Aggregate Alias Not Found'));
    }
  }

  @isTest
  static void testHavingCondition_WhenAddMultiAggregateClauseAndMultiHavingCondition_ThenReturnHavingCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'amountAvg')
      .max('CloseDate', 'lastCloseDate')
      .groupByField('StageName')
      .havingCondition(
        Scribe.asHaving()
          .whereGreaterThan('amountAvg', 10000)
          .whereLessThanOrEqual('lastCloseDate', Date.newInstance(2030, 12, 31))
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT stagename, AVG(Amount) amountAvg, MAX(CloseDate) lastCloseDate FROM Opportunity GROUP BY StageName HAVING AVG(Amount) > 10000 AND MAX(CloseDate) <= 2030-12-31';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testHavingCondition_WhenAddHavingConditionWithNonExistAlias_ThenThrowException() {
    // Arrange & Act & Assert
    try {
      Scribe scribe = Scribe.of(Opportunity.class)
        .field('StageName')
        .average('Amount', 'amountAvg')
        .groupByField('StageName')
        .havingCondition(Scribe.asHaving().whereGreaterThan('nonExistAlias', 10000));
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Aggregate Alias Not Found'));
    }
  }

  @isTest
  static void testHavingCondition_WhenWithGroupCondition_ThenReturnGroupedHavingCondition() {
    // Arrange
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('StageName')
      .average('Amount', 'avgAmount')
      .count('Id', 'countId')
      .max('TotalOpportunityQuantity', 'maxQuantity')
      .groupByField('StageName')
      .havingCondition(
        Scribe.asHaving()
          .whereGreaterThan('avgAmount', 100)
          .orCondition()
          .whereGroup(Scribe.asGroup().whereGreaterThan('countId', 10).whereGreaterThan('maxQuantity', 100))
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT stagename, AVG(Amount) avgAmount, COUNT(Id) countId, MAX(TotalOpportunityQuantity) maxQuantity FROM Opportunity GROUP BY StageName HAVING AVG(Amount) > 100 OR (COUNT(Id) > 10 AND MAX(TotalOpportunityQuantity) > 100)';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testAverageInParent_WhenAddAverageInParent_ThenReturnAverageInParent() {
    // Arrange
    Scribe scribe = Scribe.of(OpportunityLineItem.class)
      .parentField(Scribe.asParent('OpportunityId').average('Amount', 'avgAmount'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT AVG(Opportunity.Amount) avgAmount FROM OpportunityLineItem';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testAverageInParent_WhenAddTwoNestedAverageInParent_ThenReturnNestedAverageInParent() {
    // Arrange
    Scribe scribe = Scribe.of(Order.class)
      .parentField(
        Scribe.asParent('ContractId').parentField(Scribe.asParent('AccountId').average('AnnualRevenue', 'avgRevenue'))
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT AVG(Contract.Account.AnnualRevenue) avgRevenue FROM Order';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testAggregateFunctionsInParent_WhenAddAggregateFunctionsToTwoNestedParent_ThenReturnAggregateFunctionsInParent() {
    // Arrange
    Scribe scribe = Scribe.of(Order.class)
      .parentField(
        Scribe.asParent('ContractId')
          .parentField(
            Scribe.asParent('AccountId')
              .average('AnnualRevenue', 'revenueAvg')
              .count('Id', 'accCount')
              .countDistinct('ParentId', 'parentCount')
              .max('AnnualRevenue', 'revenueMax')
              .min('AnnualRevenue', 'revenueMin')
              .sum('AnnualRevenue', 'revenueSum')
          )
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT AVG(Contract.Account.AnnualRevenue) revenueAvg, COUNT(Contract.Account.Id) accCount, COUNT_DISTINCT(Contract.Account.ParentId) parentCount, MAX(Contract.Account.AnnualRevenue) revenueMax, MIN(Contract.Account.AnnualRevenue) revenueMin, SUM(Contract.Account.AnnualRevenue) revenueSum FROM Order';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testAggregateFunctionsInParent_WhenAddDuplicateAliasBetWeenParentAndCurrent_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Order.class)
        .count('Id', 'countIdAlias')
        .parentField(
          Scribe.asParent('ContractId')
            .parentField(
              Scribe.asParent('AccountId').count('Id', 'countIdAlias') // Duplicate alias
            )
        );
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Duplicate Alias Error'));
    }
  }

  @isTest
  static void testGroupByParent_WhenApplyNull_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(OpportunityLineItem.class)
        .field('Product2Id')
        .sum('TotalPrice', 'totalPrice')
        .parentField(Scribe.asParent('OpportunityId').field('Id').max('Amount', 'maxAmount'))
        .groupByField('Product2Id')
        .groupByParent(null); // null is not allowed
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('groupByParent(Scribe parentScribe)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testGroupByParent_WhenAddNonParentScribe_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(OpportunityLineItem.class)
        .field('Product2Id')
        .sum('TotalPrice', 'totalPrice')
        .parentField(Scribe.asParent('OpportunityId').field('Id').max('Amount', 'maxAmount'))
        .groupByField('Product2Id')
        .groupByParent(Scribe.of(Opportunity.class).field('Id')); // must use asParent()
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Contextual Violation: groupByParent() Forbidden'));
    }
  }

  @isTest
  static void testGroupByParent_WhenAddParentGroup_ThenReturnGroupByParent() {
    // Arrange
    Scribe scribe = Scribe.of(OpportunityLineItem.class)
      .field('Product2Id')
      .sum('TotalPrice', 'totalPrice')
      .parentField(Scribe.asParent('OpportunityId').field('Id').max('Amount', 'maxAmount'))
      .groupByField('Product2Id')
      .groupByParent(Scribe.asParent('OpportunityId').groupByField('Id'));

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT product2id, SUM(TotalPrice) totalPrice, Opportunity.id, MAX(Opportunity.Amount) maxAmount FROM OpportunityLineItem GROUP BY Product2Id, Opportunity.Id';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testGroupByParent_WhenAddNonGroupedSelectFields_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(OpportunityLineItem.class)
      .field('Product2Id')
      .field('Id') // Id is not in GROUP BY
      .sum('TotalPrice', 'totalPrice')
      .parentField(Scribe.asParent('OpportunityId').field('Id').field('Name').max('Amount', 'maxAmount')) // Name is not in GROUP BY
      .groupByField('Product2Id')
      .groupByParent(Scribe.asParent('OpportunityId').groupByField('Id'));

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('There are fields in the SELECT clause that are not included in the GROUP BY clause'), 'should mention the SELECT/GROUP BY mismatch');
      Assert.isTrue(error.contains('[nonGroupedFields => \'id, opportunityid.name\']'), 'should include the non-grouped fields list');
    }
  }

  @isTest
  static void testGroupByParent_WhenAddNestedParentGroup_ThenReturnNestedParentGroup() {
    // Arrange
    Scribe scribe = Scribe.of(OrderItem.class)
      .count('Id', 'itemCount')
      .groupByParent(
        Scribe.asParent('OrderId')
          .groupByParent(
            Scribe.asParent('OriginalOrderId')
              .groupByParent(
                Scribe.asParent('ContractId')
                  .groupByParent(
                    Scribe.asParent('AccountId').groupByParent(Scribe.asParent('ParentId').groupByField('Id'))
                  )
              )
          )
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT COUNT(Id) itemCount FROM OrderItem GROUP BY Order.OriginalOrder.Contract.Account.Parent.Id';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testGroupByParent_WhenAddNonGroupedNestedSelectFields_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(OrderItem.class)
      .field('Id') // Id is not in GROUP BY
      .count('Id', 'itemCount')
      .parentField(
        Scribe.asParent('OrderId')
          .parentField(
            Scribe.asParent('OriginalOrderId')
              .parentField(
                Scribe.asParent('ContractId')
                  .parentField(
                    Scribe.asParent('AccountId')
                      .parentField(
                        Scribe.asParent('ParentId').field('Id').field('Name') // Name is not in GROUP BY
                      )
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
                    Scribe.asParent('AccountId').groupByParent(Scribe.asParent('ParentId').groupByField('Id'))
                  )
              )
          )
      );

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (Exception e) {
      System.debug('Expected exception: ' + e.getMessage());
      String error = e.getMessage();
      Assert.isTrue(error.contains('There are fields in the SELECT clause that are not included in the GROUP BY clause'), 'should mention the SELECT/GROUP BY mismatch');
      Assert.isTrue(error.contains('[nonGroupedFields => \'id, orderid.originalorderid.contractid.accountid.parentid.name\']'), 'should include the non-grouped fields list');
    }
  }

  @isTest
  static void testHavingCondition_WhenAddHavingConditionWithParentField_ThenReturnHavingConditionWithParentField() {
    // Arrange
    Scribe scribe = Scribe.of(OpportunityLineItem.class)
      .field('Product2Id')
      .sum('TotalPrice', 'totalPrice')
      .parentField(Scribe.asParent('OpportunityId').field('Id').max('Amount', 'maxAmount'))
      .groupByField('Product2Id')
      .groupByParent(Scribe.asParent('OpportunityId').groupByField('Id'))
      .havingCondition(
        Scribe.asHaving().whereGreaterThan('totalPrice', 1000).whereLessThanOrEqual('maxAmount', 50000)
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT product2id, SUM(TotalPrice) totalPrice, Opportunity.id, MAX(Opportunity.Amount) maxAmount FROM OpportunityLineItem GROUP BY Product2Id, Opportunity.Id HAVING SUM(TotalPrice) > 1000 AND MAX(Opportunity.Amount) <= 50000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testHavingCondition_WhenAddNestedParentHavingCondition_ThenReturnNestedParentHavingCondition() {
    // Arrange
    Scribe scribe = Scribe.of(OrderItem.class)
      .count('Id', 'itemcount')
      .parentField(
        Scribe.asParent('OrderId')
          .parentField(
            Scribe.asParent('OriginalOrderId')
              .parentField(
                Scribe.asParent('ContractId')
                  .parentField(
                    Scribe.asParent('AccountId').field('ParentId').average('AnnualRevenue', 'avgRevenue')
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
                  .groupByParent(Scribe.asParent('AccountId').groupByField('ParentId'))
              )
          )
      )
      .havingCondition(
        Scribe.asHaving().whereGreaterThan('itemcount', 10).whereLessThanOrEqual('avgRevenue', 50000)
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT COUNT(Id) itemcount, Order.OriginalOrder.Contract.Account.parentid, AVG(Order.OriginalOrder.Contract.Account.AnnualRevenue) avgRevenue FROM OrderItem GROUP BY Order.OriginalOrder.Contract.Account.ParentId HAVING COUNT(Id) > 10 AND AVG(Order.OriginalOrder.Contract.Account.AnnualRevenue) <= 50000';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testThrough_WhenApplyNull_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Order.class)
        .field('Id')
        .through(null); // null is not allowed
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('through(Scribe throughScribe)'));
      Assert.isTrue(error.contains('Missing required parameter'));
    }
  }

  @isTest
  static void testThrough_WhenAddNonThroughScribe_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Order.class)
        .field('Id')
        .through(Scribe.asChild(OrderItem.class).field('Name')); // must use asThrough()
      String soql = scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('through(Scribe throughScribe)'));
      Assert.isTrue(error.contains('Invalid Scribe Context'));
    }
  }

  @isTest
  static void testThrough_WhenAddThroughScribe_ThenReturnSoqlWithThrough() {
    Scribe scribe = Scribe.of(Order.class)
      .field('Id')
      .through(
        Scribe.asThrough(OrderItem.class, 'Product2Id')
          .field('Name')
          .field('ProductCode')
          .whereEqual('IsActive', true)
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT product2id, Product2.name, Product2.productcode FROM OrderItems WHERE Product2.IsActive = true) FROM Order';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testThrough_WhenAddOtherScribeType_ThenThrowException() {
    // Arrange / Act / Assert
    try {
      Scribe scribe = Scribe.of(Order.class)
        .field('Id')
        .through(
          Scribe.asChild(OrderItem.class) // should use asThrough() instead of asChild()
            .field('Name')
            .field('ProductCode')
            .whereEqual('IsActive', true)
        );
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('through(Scribe throughScribe)'));
      Assert.isTrue(error.contains('Invalid Scribe Context'));
    }
  }

  @isTest
  static void testThrough_WhenAddRelationName_ThenAddedRelationNameUsed() {
    Scribe scribe = Scribe.of(Order.class)
      .field('Id')
      .through(
        Scribe.asThrough(OrderItem.class, 'Product2Id')
          .relationName('OrderItems')
          .field('Name')
          .field('ProductCode')
          .whereEqual('IsActive', true)
      );

    // Act
    String soql = scribe.toSoql();

    // Assert
    String expectedSoql = 'SELECT id, (SELECT product2id, Product2.name, Product2.productcode FROM OrderItems WHERE Product2.IsActive = true) FROM Order';
    Assert.areEqual(expectedSoql, soql);
  }

  @isTest
  static void testThrough_WhenAddInvalidRelationName_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(Order.class)
      .field('Id')
      .through(
        Scribe.asThrough(OrderItem.class, 'Product2Id')
          .relationName('OrderItems__r') // invalid relation name
          .field('Name')
          .field('ProductCode')
          .whereEqual('IsActive', true)
      );

    // Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Invalid Relationship Name'));
    }
  }

  @isTest
  static void testThrough_WhenMultiRelationFieldWithSameParentExist_ThenThrowException() {
    // Arrange
    Scribe scribe = Scribe.of(User.class)
      .field('Id')
      .through(Scribe.asThrough(Contract.class, 'LastModifiedById').field('Name'));
    //  Act / Assert
    try {
      String soql = scribe.toSoql();
      Assert.fail('Expected exception to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('Ambiguous Relationship'));
    }
  }

  // ===============================================================================
  // Deferred null-value validation (issue #71): a null value no longer throws at
  // chain time — an InvalidConditionClause is recorded, so a following ignoreWhen()
  // can retract it. If it survives to toSoql(), the original required-argument
  // error fires, naming the originating method and field.
  // ===============================================================================

  @isTest
  static void testIgnoreWhen_WhenWhereInValuesAreNull_ThenConditionDropped() {
    // the motivating case: 「値が null なら絞り込まない」を1チェーンで書ける
    Set<String> names = null;
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIn('Name', names).ignoreWhen(names == null);

    Assert.areEqual('SELECT id FROM Account', scribe.toSoql());
  }

  @isTest
  static void testIgnoreWhen_WhenWhereNotInValuesAreNull_ThenConditionDropped() {
    Set<String> names = null;
    Scribe scribe = Scribe.of(Account.class).field('Id').whereNotIn('Name', names).ignoreWhen(names == null);

    Assert.areEqual('SELECT id FROM Account', scribe.toSoql());
  }

  @isTest
  static void testIgnoreWhen_WhenComparisonValueIsNull_ThenConditionDropped() {
    // representative of the comparison/LIKE family (all 12 null-rejecting sites share the mechanism)
    Object amount = null;
    Scribe scribe = Scribe.of(Opportunity.class)
      .field('Id')
      .whereGreaterThan('Amount', amount)
      .ignoreWhen(amount == null);

    Assert.areEqual('SELECT id FROM Opportunity', scribe.toSoql());
  }

  @isTest
  static void testIgnoreWhen_WhenNullConditionDroppedAmongOthers_ThenSurvivorsKeepWorking() {
    // retraction of the invalid condition must leave a clean chain behind
    Set<String> names = null;
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereEqual('Industry', 'Tech')
      .whereIn('Name', names)
      .ignoreWhen(names == null)
      .whereLike('Phone', '03-%');

    Assert.areEqual('SELECT id FROM Account WHERE Industry = \'Tech\' AND Phone LIKE \'03-%\'', scribe.toSoql());
  }

  @isTest
  static void testIgnoreWhen_WhenNullConditionInsideGroupDropped_ThenGroupIgnored() {
    // a group whose only condition was retracted is an empty group → ignored entirely
    Set<String> names = null;
    Scribe scribe = Scribe.of(Account.class)
      .field('Id')
      .whereGroup(Scribe.asGroup().whereIn('Name', names).ignoreWhen(names == null));

    Assert.areEqual('SELECT id FROM Account', scribe.toSoql());
  }

  @isTest
  static void testWhereIn_WhenNullValuesSurviveInsideGroup_ThenThrowAtBuildTime() {
    // an un-retracted invalid condition inside a group still fires the deferred error
    Set<String> names = null;
    Scribe scribe = Scribe.of(Account.class).field('Id').whereGroup(Scribe.asGroup().whereIn('Name', names));

    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('whereIn(String fieldName, Object values)'), e.getMessage());
    }
  }

  @isTest
  static void testWhereIn_WhenNullValuesNotIgnored_ThenErrorNamesMethodAndField() {
    // the deferred error must keep the offending where...() identifiable
    Set<String> names = null;
    Scribe scribe = Scribe.of(Account.class).field('Id').whereIn('Name', names);

    try {
      scribe.toSoql();
      Assert.fail('Expected ApexEloquentException to be thrown');
    } catch (ApexEloquentException e) {
      String error = e.getMessage();
      Assert.isTrue(error.contains('whereIn(String fieldName, Object values)'), error);
      Assert.isTrue(error.contains('Missing required parameter'), error);
      Assert.isTrue(error.contains('Name'), 'Error must name the field: ' + error);
      Assert.isTrue(error.contains('ignoreWhen'), 'Error must hint the retraction path: ' + error);
    }
  }

  // ===============================================================================
  // ignoreWhen combination matrix (issue #72): what remains after a retraction must
  // stay a well-formed chain — across value states (normal/empty/null), groups,
  // OR marks, and subqueries. Table-driven: one row per combination.
  // ===============================================================================

  private class MatrixCase {
    String name;
    Scribe scribe;
    String expected;
    MatrixCase(String name, Scribe scribe, String expected) {
      this.name = name;
      this.scribe = scribe;
      this.expected = expected;
    }
  }

  @isTest
  static void testIgnoreWhenMatrix_CombinationRows_ThenExpectedSoql() {
    Set<String> vals = new Set<String>{ 'A' };
    Set<String> emptySet = new Set<String>();
    Set<String> nullSet = null;
    Scribe subQuery = Scribe.of(Account.class).field('Id').whereEqual('Name', 'X');
    Scribe nullSubQuery = null;

    List<MatrixCase> cases = new List<MatrixCase>{
      // --- value states × whereIn/whereNotIn × ignoreWhen ---
      new MatrixCase(
        'in/normal/kept',
        Scribe.of(Account.class).field('Id').whereIn('Name', vals),
        'SELECT id FROM Account WHERE Name IN (\'A\')'
      ),
      new MatrixCase(
        'in/normal/ignoreWhen(false) keeps',
        Scribe.of(Account.class).field('Id').whereIn('Name', vals).ignoreWhen(false),
        'SELECT id FROM Account WHERE Name IN (\'A\')'
      ),
      new MatrixCase(
        'in/empty/kept = always false',
        Scribe.of(Account.class).field('Id').whereIn('Name', emptySet),
        'SELECT id FROM Account WHERE Id = null'
      ),
      new MatrixCase(
        'notIn/empty/kept = condition ignored',
        Scribe.of(Account.class).field('Id').whereNotIn('Name', emptySet),
        'SELECT id FROM Account'
      ),
      new MatrixCase(
        'in/empty/ignored',
        Scribe.of(Account.class).field('Id').whereIn('Name', emptySet).ignoreWhen(true),
        'SELECT id FROM Account'
      ),
      new MatrixCase(
        'in/null/ignored',
        Scribe.of(Account.class).field('Id').whereIn('Name', nullSet).ignoreWhen(true),
        'SELECT id FROM Account'
      ),
      new MatrixCase(
        'notIn/null/ignored',
        Scribe.of(Account.class).field('Id').whereNotIn('Name', nullSet).ignoreWhen(true),
        'SELECT id FROM Account'
      ),
      // --- OR interactions ---
      new MatrixCase(
        'or-mid retraction leaves A OR C',
        Scribe.of(Account.class)
          .field('Id')
          .whereEqual('Industry', 'A')
          .orCondition()
          .whereEqual('Industry', 'B')
          .ignoreWhen(true)
          .orCondition()
          .whereEqual('Industry', 'C'),
        'SELECT id FROM Account WHERE Industry = \'A\' OR Industry = \'C\''
      ),
      new MatrixCase(
        'empty-IN as OR member keeps always-false semantics',
        Scribe.of(Account.class).field('Id').whereEqual('Industry', 'A').orCondition().whereIn('Name', emptySet),
        'SELECT id FROM Account WHERE Industry = \'A\' OR Id = null'
      ),
      new MatrixCase(
        'null-IN as OR member retracted → OR marker cleaned up',
        Scribe.of(Account.class)
          .field('Id')
          .whereEqual('Industry', 'A')
          .orCondition()
          .whereIn('Name', nullSet)
          .ignoreWhen(true),
        'SELECT id FROM Account WHERE Industry = \'A\''
      ),
      // --- groups ---
      new MatrixCase(
        'group partial retraction keeps survivor',
        Scribe.of(Account.class)
          .field('Id')
          .whereGroup(Scribe.asGroup().whereEqual('Industry', 'T').whereIn('Name', nullSet).ignoreWhen(true)),
        'SELECT id FROM Account WHERE (Industry = \'T\')'
      ),
      new MatrixCase(
        'group OR-member retraction → AND can follow inside group',
        Scribe.of(Account.class)
          .field('Id')
          .whereGroup(
            Scribe.asGroup()
              .whereEqual('Industry', 'A')
              .orCondition()
              .whereEqual('Industry', 'B')
              .ignoreWhen(true)
              .whereEqual('Rating', 'C')
          ),
        'SELECT id FROM Account WHERE (Industry = \'A\' AND Rating = \'C\')'
      ),
      new MatrixCase(
        'fully retracted group is ignored, later conditions still attach',
        Scribe.of(Account.class)
          .field('Id')
          .whereGroup(Scribe.asGroup().whereIn('Name', nullSet).ignoreWhen(true))
          .whereEqual('Industry', 'T'),
        'SELECT id FROM Account WHERE Industry = \'T\''
      ),
      // --- subqueries ---
      new MatrixCase(
        'subquery condition retracted',
        Scribe.of(Opportunity.class).field('Id').whereIn('AccountId', subQuery).ignoreWhen(true),
        'SELECT id FROM Opportunity'
      ),
      new MatrixCase(
        'null subquery retracted',
        Scribe.of(Opportunity.class).field('Id').whereIn('AccountId', nullSubQuery).ignoreWhen(true),
        'SELECT id FROM Opportunity'
      )
    };

    for (MatrixCase c : cases) {
      Assert.areEqual(c.expected, c.scribe.toSoql(), c.name);
    }
  }

  @isTest
  static void testIgnoreWhenMatrix_SurvivingInvalidRows_ThenThrowAtBuildTime() {
    Set<String> nullSet = null;

    // expected: the message names the originating method
    List<MatrixCase> cases = new List<MatrixCase>{
      new MatrixCase(
        'null-IN as surviving OR member',
        Scribe.of(Account.class).field('Id').whereEqual('Industry', 'A').orCondition().whereIn('Name', nullSet),
        'whereIn(String fieldName, Object values)'
      ),
      new MatrixCase(
        'null-NOT-IN surviving after another retraction',
        Scribe.of(Account.class)
          .field('Id')
          .whereEqual('Industry', 'A')
          .ignoreWhen(true)
          .whereNotIn('Name', nullSet),
        'whereNotIn(String fieldName, Object values)'
      )
    };

    for (MatrixCase c : cases) {
      try {
        c.scribe.toSoql();
        Assert.fail('Expected ApexEloquentException: ' + c.name);
      } catch (ApexEloquentException e) {
        Assert.isTrue(e.getMessage().contains(c.expected), c.name + ' / ' + e.getMessage());
      }
    }
  }
}
