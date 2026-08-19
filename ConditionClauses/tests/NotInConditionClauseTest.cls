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
 * @directory ApexEloquent/ConditionClauses/tests
 */
@isTest
public class NotInConditionClauseTest {
  @isTest
  static void testBuild_WhenValueIsStringList_ThenReturnsNotInClauseWithQuotes() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> names = new List<String>{ 'Corp A', 'Corp B' };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'Name', names);

    // Act
    String result = clause.build();

    // Assert
    String expected = 'Name NOT IN (\'Corp A\', \'Corp B\')';
    Assert.areEqual(expected, result, 'String values should be quoted and comma-separated.');
  }

  @isTest
  static void testBuild_WhenValueIsIdSet_ThenReturnsNotInClauseWithQuotes() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Id> accountIds = new Set<Id>{ '001xx0000000001AAA', '001xx0000000002AAA' };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'Id', accountIds);

    // Act
    String result = clause.build();

    // Assert
    // The order might vary with a Set, so we check for presence instead of exact match.
    Assert.isTrue(result.startsWith('Id NOT IN ('), 'Clause should start with NOT IN operator.');
    Assert.isTrue(result.contains('\'001xx0000000001AAA\''), 'Clause should contain the first Id.');
    Assert.isTrue(result.contains('\'001xx0000000002AAA\''), 'Clause should contain the second Id.');
  }

  @isTest
  static void testBuild_WhenValueIsIntegerList_ThenReturnsNotInClauseWithoutQuotes() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<Integer> employees = new List<Integer>{ 100, 200 };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'NumberOfEmployees', employees);

    // Act
    String result = clause.build();

    // Assert
    String expected = 'NumberOfEmployees NOT IN (100, 200)';
    Assert.areEqual(expected, result, 'Integer values should not be quoted.');
  }

  @isTest
  static void testBuild_WhenListContainsNull_ThenReturnsNotInClauseWithNullLiteral() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> names = new List<String>{ 'Corp A', null };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'Name', names);

    // Act
    String result = clause.build();

    // Assert
    String expected = 'Name NOT IN (\'Corp A\', NULL)';
    Assert.areEqual(expected, result, 'Null values in the list should be converted to NULL literals.');
  }

  @isTest
  static void testBuild_WhenListIsEmpty_ThenReturnsEmptyString() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> names = new List<String>();
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'Name', names);

    // Act
    String result = clause.build();

    // Assert
    Assert.areEqual(
      '',
      result,
      'An empty NOT IN list should result in an empty string to be ignored by the builder.'
    );
  }

  // ====== Set<X> for each Apex primitive type ======

  @isTest
  static void testBuild_WhenValueIsSetOfString_ThenAccepted() {
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<String> names = new Set<String>{ 'Corp A', 'Corp B' };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'Name', names);

    String result = clause.build();

    Assert.isTrue(result.startsWith('Name NOT IN ('), 'should start with Name NOT IN (');
    Assert.isTrue(result.contains('\'Corp A\''), 'should contain first value');
    Assert.isTrue(result.contains('\'Corp B\''), 'should contain second value');
  }

  @isTest
  static void testBuild_WhenValueIsSetOfInteger_ThenAccepted() {
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Integer> employees = new Set<Integer>{ 100, 200 };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'NumberOfEmployees', employees);

    String result = clause.build();

    Assert.isTrue(result.startsWith('NumberOfEmployees NOT IN ('), 'should start with NumberOfEmployees NOT IN (');
    Assert.isTrue(result.contains('100'), 'should contain first value');
    Assert.isTrue(result.contains('200'), 'should contain second value');
  }

  @isTest
  static void testBuild_WhenValueIsSetOfLong_ThenAccepted() {
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Long> employees = new Set<Long>{ 100L, 200L };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'NumberOfEmployees', employees);

    String result = clause.build();

    Assert.isTrue(result.startsWith('NumberOfEmployees NOT IN ('), 'should start with NumberOfEmployees NOT IN (');
    Assert.isTrue(result.contains('100'), 'should contain first value');
    Assert.isTrue(result.contains('200'), 'should contain second value');
  }

  @isTest
  static void testBuild_WhenValueIsSetOfDecimal_ThenAccepted() {
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Decimal> revenues = new Set<Decimal>{ 1500.50, 3000.75 };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'AnnualRevenue', revenues);

    String result = clause.build();

    Assert.isTrue(result.startsWith('AnnualRevenue NOT IN ('), 'should start with AnnualRevenue NOT IN (');
    Assert.isTrue(result.contains('1500.5'), 'should contain first value');
    Assert.isTrue(result.contains('3000.75'), 'should contain second value');
  }

  @isTest
  static void testBuild_WhenValueIsSetOfDouble_ThenAccepted() {
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Double> revenues = new Set<Double>{ 1500.5, 3000.75 };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'AnnualRevenue', revenues);

    String result = clause.build();

    Assert.isTrue(result.startsWith('AnnualRevenue NOT IN ('), 'should start with AnnualRevenue NOT IN (');
    Assert.isTrue(result.contains('1500.5'), 'should contain first value');
    Assert.isTrue(result.contains('3000.75'), 'should contain second value');
  }

  @isTest
  static void testBuild_WhenValueIsSetOfBoolean_ThenAccepted() {
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Boolean> flags = new Set<Boolean>{ true, false };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'IsDeleted', flags);

    String result = clause.build();

    Assert.isTrue(result.startsWith('IsDeleted NOT IN ('), 'should start with IsDeleted NOT IN (');
    Assert.isTrue(result.contains('true'), 'should contain true');
    Assert.isTrue(result.contains('false'), 'should contain false');
  }

  @isTest
  static void testBuild_WhenValueIsSetOfDate_ThenAccepted() {
    Schema.SObjectType sObjectType = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Date> dates = new Set<Date>{ Date.newInstance(2026, 1, 1), Date.newInstance(2026, 6, 30) };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'CloseDate', dates);

    String result = clause.build();

    Assert.isTrue(result.startsWith('CloseDate NOT IN ('), 'should start with CloseDate NOT IN (');
    Assert.isTrue(result.contains('2026-01-01'), 'should contain first date');
    Assert.isTrue(result.contains('2026-06-30'), 'should contain second date');
  }

  @isTest
  static void testBuild_WhenValueIsSetOfDatetime_ThenAccepted() {
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Datetime> dts = new Set<Datetime>{
      Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0),
      Datetime.newInstanceGmt(2026, 6, 30, 12, 30, 45)
    };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'CreatedDate', dts);

    String result = clause.build();

    Assert.isTrue(result.startsWith('CreatedDate NOT IN ('), 'should start with CreatedDate NOT IN (');
    Assert.isTrue(result.contains('2026-01-01T00:00:00Z'), 'should contain first datetime');
    Assert.isTrue(result.contains('2026-06-30T12:30:45Z'), 'should contain second datetime');
  }

  @isTest
  static void testBuild_WhenValueIsSetOfTime_ThenAccepted() {
    // Time has no obvious standard-object field with DisplayType.TIME,
    // so we use Account.Name (STRING) which forces single-quoted formatting.
    // The point is to verify Set<Time> is accepted without ClassCastException.
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Set<Time> times = new Set<Time>{ Time.newInstance(9, 0, 0, 0), Time.newInstance(17, 30, 0, 0) };
    IConditionClause clause = new NotInConditionClause(sObjectType, fieldMap, 'Name', times);

    String result = clause.build();

    Assert.isTrue(result.startsWith('Name NOT IN ('), 'Set<Time> should be accepted (no ClassCastException)');
  }

  @isTest
  static void testConstructor_WhenValueIsUnsupportedType_ThenThrowApexEloquentException() {
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    Integer notACollection = 42;

    try {
      new NotInConditionClause(sObjectType, fieldMap, 'Name', notACollection);
      Assert.fail('Expected ApexEloquentException for unsupported values type');
    } catch (ApexEloquentException e) {
      String msg = e.getMessage();
      Assert.isTrue(msg.contains('AbstractConditionClause'), 'should locate at AbstractConditionClause');
      Assert.isTrue(msg.contains('values'), 'should mention values parameter');
    }
  }

  @isTest
  static void testImmutability_WhenOverrideMetaData_ThenReturnsNewInstance() {
    // Arrange
    Schema.SObjectType accountSObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> accountFieldMap = accountSObjectType.getDescribe().fields.getMap();
    List<String> values = new List<String>{ 'Value1' };
    IConditionClause originalClause = new NotInConditionClause(
      accountSObjectType,
      accountFieldMap,
      'Name',
      values
    );

    // Act
    Schema.SObjectType oppSObjectType = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSObjectType.getDescribe().fields.getMap();
    IConditionClause newClause = originalClause.overrideMetaData(oppSObjectType, oppFieldMap);

    // Assert
    Assert.areNotEqual(originalClause, newClause, 'A new instance should be returned.');
    Assert.areEqual(
      'Name NOT IN (\'Value1\')',
      originalClause.build(),
      'Original instance should not be modified.'
    );
  }

  @isTest
  static void testImmutability_WhenOverrideField_ThenReturnsNewInstanceWithNewField() {
    // Arrange
    Schema.SObjectType sObjectType = Account.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
    List<String> values = new List<String>{ 'Tech', 'Finance' };
    IConditionClause originalClause = new NotInConditionClause(sObjectType, fieldMap, 'Type', values);

    // Act
    IConditionClause newClause = originalClause.overrideField('Industry');

    // Assert
    Assert.areNotEqual(originalClause, newClause, 'A new instance should be returned.');
    Assert.areEqual(
      'Type NOT IN (\'Tech\', \'Finance\')',
      originalClause.build(),
      'Original instance should not be modified.'
    );
    Assert.areEqual(
      'Industry NOT IN (\'Tech\', \'Finance\')',
      newClause.build(),
      'New instance should reflect the overridden field name.'
    );
  }
}
