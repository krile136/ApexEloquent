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
public class InConditionClauseTest {
  @isTest
  static void testBuild_WhenValueIsStringList_ThenReturnsInClauseWithQuotes() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> names = new List<String>{ 'Corp A', 'Corp B' };
    IConditionClause clause = new InConditionClause(sObjectType, fieldMap, 'Name', names);

    // Act
    String result = clause.build();

    // Assert
    String expected = 'Name IN (\'Corp A\', \'Corp B\')';
    Assert.areEqual(expected, result, 'String values should be quoted and comma-separated.');
  }

  @isTest
  static void testBuild_WhenValueIsIdSet_ThenReturnsInClauseWithQuotes() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Id> accountIds = new Set<Id>{ '001xx0000000001AAA', '001xx0000000002AAA' };
    IConditionClause clause = new InConditionClause(sObjectType, fieldMap, 'Id', accountIds);

    // Act
    String result = clause.build();

    // Assert
    // The order might vary with a Set, so we check for presence instead of exact match.
    Assert.isTrue(result.startsWith('Id IN ('), 'Clause should start with IN operator.');
    Assert.isTrue(result.contains('\'001xx0000000001AAA\''), 'Clause should contain the first Id.');
    Assert.isTrue(result.contains('\'001xx0000000002AAA\''), 'Clause should contain the second Id.');
  }

  @isTest
  static void testBuild_WhenValueIsIntegerList_ThenReturnsInClauseWithoutQuotes() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<Integer> employees = new List<Integer>{ 100, 200 };
    IConditionClause clause = new InConditionClause(sObjectType, fieldMap, 'NumberOfEmployees', employees);

    // Act
    String result = clause.build();

    // Assert
    String expected = 'NumberOfEmployees IN (100, 200)';
    Assert.areEqual(expected, result, 'Integer values should not be quoted.');
  }

  @isTest
  static void testBuild_WhenListContainsNull_ThenReturnsInClauseWithNullLiteral() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> names = new List<String>{ 'Corp A', null };
    IConditionClause clause = new InConditionClause(sObjectType, fieldMap, 'Name', names);

    // Act
    String result = clause.build();

    // Assert
    String expected = 'Name IN (\'Corp A\', NULL)';
    Assert.areEqual(expected, result, 'Null values in the list should be converted to NULL literals.');
  }

  @isTest
  static void testBuild_WhenListIsEmpty_ThenReturnsAlwaysFalseCondition() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> names = new List<String>();
    IConditionClause clause = new InConditionClause(sObjectType, fieldMap, 'Name', names);

    // Act
    String result = clause.build();

    // Assert
    String expected = 'Id = null';
    Assert.areEqual(
      expected,
      result,
      'An empty IN list should be converted to a condition that always evaluates to false.'
    );
  }

  @isTest
  static void testImmutability_WhenOverrideMetaData_ThenReturnsNewInstance() {
    // Arrange
    Schema.SObjectType accountSObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> accountFieldMap = accountSObjectType.getDescribe().fields.getMap();
    List<String> values = new List<String>{ 'Value1' };
    IConditionClause originalClause = new InConditionClause(accountSObjectType, accountFieldMap, 'Name', values);

    // Act
    Schema.SObjectType oppSObjectType = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSObjectType.getDescribe().fields.getMap();
    IConditionClause newClause = originalClause.overrideMetaData(oppSObjectType, oppFieldMap);

    // Assert
    Assert.areNotEqual(originalClause, newClause, 'A new instance should be returned.');
    Assert.areEqual('Name IN (\'Value1\')', originalClause.build(), 'Original instance should not be modified.');
  }

  @isTest
  static void testImmutability_WhenOverrideField_ThenReturnsNewInstanceWithNewField() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> values = new List<String>{ 'Tech', 'Finance' };
    IConditionClause originalClause = new InConditionClause(sObjectType, fieldMap, 'Type', values);

    // Act
    IConditionClause newClause = originalClause.overrideField('Industry');

    // Assert
    Assert.areNotEqual(originalClause, newClause, 'A new instance should be returned.');
    Assert.areEqual(
      'Type IN (\'Tech\', \'Finance\')',
      originalClause.build(),
      'Original instance should not be modified.'
    );
    Assert.areEqual(
      'Industry IN (\'Tech\', \'Finance\')',
      newClause.build(),
      'New instance should reflect the overridden field name.'
    );
  }
}
