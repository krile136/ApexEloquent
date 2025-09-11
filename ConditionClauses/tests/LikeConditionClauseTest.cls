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
public class LikeConditionClauseTest {
  @isTest
  static void testBuild_WhenValueIsValidString_ThenReturnsLikeClause() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    IConditionClause clause = new LikeConditionClause(sObjectType, fieldMap, 'Name', '%Test Corp%');

    // Act
    String result = clause.build();

    // Assert
    Assert.areEqual(
      'Name LIKE \'%Test Corp%\'',
      result,
      'The LIKE condition string should be correctly formatted.'
    );
  }

  @isTest
  static void testBuild_WhenValueIsNull_ThenThrowException() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    IConditionClause clause = new LikeConditionClause(sObjectType, fieldMap, 'Name', null);

    // Act & Assert
    try {
      clause.build();
      Assert.fail('Expected a QueryException to be thrown for null value.');
    } catch (QueryException e) {
      String expectedMessage = 'Value cannot be null for LIKE condition. field: Name';
      Assert.areEqual(expectedMessage, e.getMessage(), 'The exception message should match.');
    }
  }

  @isTest
  static void testImmutability_WhenOverrideMetaData_ThenReturnsNewInstance() {
    // Arrange
    Schema.SObjectType accountSObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> accountFieldMap = accountSObjectType.getDescribe().fields.getMap();
    IConditionClause originalClause = new LikeConditionClause(
      accountSObjectType,
      accountFieldMap,
      'Name',
      'Test%'
    );

    // Act
    Schema.SObjectType oppSObjectType = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSObjectType.getDescribe().fields.getMap();
    IConditionClause newClause = originalClause.overrideMetaData(oppSObjectType, oppFieldMap);

    // Assert
    Assert.areNotEqual(originalClause, newClause, 'A new instance should be returned.');
    Assert.areEqual('Name LIKE \'Test%\'', originalClause.build(), 'Original instance should not be modified.');
  }

  @isTest
  static void testImmutability_WhenOverrideField_ThenReturnsNewInstanceWithNewField() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    IConditionClause originalClause = new LikeConditionClause(sObjectType, fieldMap, 'Name', 'Test%');

    // Act
    IConditionClause newClause = originalClause.overrideField('BillingStreet');

    // Assert
    Assert.areNotEqual(originalClause, newClause, 'A new instance should be returned.');
    Assert.areEqual('Name LIKE \'Test%\'', originalClause.build(), 'Original instance should not be modified.');
    Assert.areEqual(
      'BillingStreet LIKE \'Test%\'',
      newClause.build(),
      'New instance should reflect the overridden field name.'
    );
  }
}
