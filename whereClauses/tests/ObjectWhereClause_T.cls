@isTest
public with sharing class ObjectWhereClause_T {
  @isTest
  static void testBuild_WhenIdEqualsValue_ThenCorrectWhereClause() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSource.getDescribe().fields.getMap();
    WhereClauseInterface whereClause = new ObjectWhereClause(oppSource, null, 'Id', '=', '006000000000000');
    whereClause = whereClause.overrideMetaData(oppSource, oppFieldMap);

    // Act
    String build = whereClause.build();

    // Assert
    String expected = 'Id = \'006000000000000\'';
    Assert.areEqual(expected, build);
  }

  @isTest
  static void testBuild_WhenIdNotEqualsNull_ThenCorrectWhereClause() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSource.getDescribe().fields.getMap();
    WhereClauseInterface whereClause = new ObjectWhereClause(oppSource, oppFieldMap, 'Id', '!=', null);

    // Act
    String build = whereClause.build();

    // Assert
    String expected = 'Id != NULL';
    System.assertEquals(expected, build);
  }

  @isTest
  static void testBuild_WhenDateEqualsValue_ThenCorrectWhereClause() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSource.getDescribe().fields.getMap();
    WhereClauseInterface whereClause = new ObjectWhereClause(
      oppSource,
      oppFieldMap,
      'CloseDate',
      '=',
      Date.newinstance(2024, 12, 31)
    );

    // Act
    String build = whereClause.build();

    // Assert
    String expected = 'CloseDate = 2024-12-31';
    Assert.areEqual(expected, build);
  }

  @isTest
  static void testBuild_WhenDateTimeEqualsValue_ThenCorrectWhereClause() {
    // Arrange
    Schema.SObjectType contactSource = Contact.getSObjectType();
    Datetime dt = DateTime.newInstance(2024, 4, 1, 12, 34, 56);
    Map<String, Schema.SObjectField> contactFieldMap = contactSource.getDescribe().fields.getMap();
    WhereClauseInterface whereClause = new ObjectWhereClause(
      contactSource,
      contactFieldMap,
      'LastCURequestDate',
      '=',
      dt
    );

    // Act
    String build = whereClause.build();
    Integer offsetMillis = UserInfo.getTimeZone().getOffset(dt);
    Integer offsetHours = offsetMillis / (1000 * 60 * 60);
    Datetime adjustedDatetime = dt.addHours(-offsetHours);
    String expected =
      'LastCURequestDate = ' +
      adjustedDatetime.year() +
      '-' +
      String.valueOf(adjustedDatetime.month()).leftPad(2, '0') +
      '-' +
      String.valueOf(adjustedDatetime.day()).leftPad(2, '0') +
      'T' +
      String.valueOf(adjustedDatetime.hour()).leftPad(2, '0') +
      ':' +
      String.valueOf(adjustedDatetime.minute()).leftPad(2, '0') +
      ':' +
      String.valueOf(adjustedDatetime.second()).leftPad(2, '0') +
      'Z';

    // Assert
    Assert.areEqual(expected, build);
  }

  @isTest
  static void testBuild_WhenInjectionAttempt_ThenCorrectlySanitized() {
    // Arrange
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSource.getDescribe().fields.getMap();
    WhereClauseInterface whereClause = new ObjectWhereClause(
      oppSource,
      oppFieldMap,
      'CloseDate',
      '=',
      '2024-01-01 OR Name LIKE \'%\''
    );

    // Act
    String build = whereClause.build();

    // Assert
    String expected = 'CloseDate = 2024-01-01 OR Name LIKE \\\'%\\\'';
    Assert.areEqual(expected, build);
  }
}
