@isTest(seeAllData=false)
public with sharing class ObjectWhereClause_T {
  public static testMethod void testBuild() {
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> oppFieldMap = oppSource.getDescribe().fields.getMap();
    Schema.SObjectType accountSource = Account.getSObjectType();
    Map<String, Schema.SObjectField> accountFieldMap = accountSource.getDescribe().fields.getMap();

    String testTitle = '正常系: Where句が組み立てられる';
    WhereClauseInterface whereClause = new ObjectWhereClause(oppSource, null, 'Id', '=', '006000000000000');
    whereClause = whereClause.overrideMetaData(accountSource, accountFieldMap);
    String build = whereClause.build();
    String expected = 'Id = \'006000000000000\'';
    System.assertEquals(expected, build, testTitle);

    testTitle = '正常系: Where句が組み立てられる(null)';
    whereClause = new ObjectWhereClause(oppSource, oppFieldMap, 'Id', '!=', null);
    build = whereClause.build();
    expected = 'Id != NULL';
    System.assertEquals(expected, build, testTitle);

    testTitle = '正常系: Where句が組み立てられる(Dateがキャストされる)';
    whereClause = new ObjectWhereClause(oppSource, oppFieldMap, 'CloseDate', '=', Date.newinstance(2024, 12, 31));
    build = whereClause.build();
    expected = 'CloseDate = 2024-12-31';
    System.assertEquals(expected, build, testTitle);

    testTitle = '正常系: Where句が組み立てられる(DateTimeがキャストされる)';
    Schema.SObjectType contactSource = Contact.getSObjectType();
    Map<String, Schema.SObjectField> contactFieldMap = contactSource.getDescribe().fields.getMap();
    whereClause = new ObjectWhereClause(contactSource, contactFieldMap, 'LastCURequestDate', '=', DateTime.newInstance(2024, 4, 1, 12, 34, 56));
    build = whereClause.build();
    expected = 'LastCURequestDate = 2024-04-01T12:34:56Z';
    System.assertEquals(expected, build, testTitle);

  }
}
