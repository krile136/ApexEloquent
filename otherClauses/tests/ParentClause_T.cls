@isTest(seeAllData=false)
public with sharing class ParentClause_T {

  @isTest(seeAllData=false)
  public static void testBuild() {
    String testTitle = '正常系: 親のSELECT句が組み立てられる';
    ParentClause parentClause = new ParentClause('OwnerId', 'Name');
    Map<String, Schema.SObjectField> oppFieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();
    String actual;
    String expected;

    testTitle = '正常系: 親のSELECT句が組み立てられる';
    System.debug(testTitle);
    parentClause = new ParentClause('OwnerId', 'Name');
    actual = parentClause.build(oppFieldMap);
    expected = 'Owner.Name';
    Assert.areEqual(expected, actual, testTitle); 

    testTitle = '正常系: 親のSELECT句(複数)が組み立てられる';
    System.debug(testTitle);
    parentClause = new ParentClause('OwnerId', new List<String>{'Id', 'Name'});
    actual = parentClause.build(oppFieldMap);
    expected = 'Owner.Id, Owner.Name';
    Assert.areEqual(expected, actual, testTitle);

    testTitle = '異常系: 親のSELECT句が空';
    System.debug(testTitle);
    parentClause = new ParentClause('OwnerId', new List<String>());
    try {
      parentClause.build(oppFieldMap);
      Assert.fail(testTitle);
    } catch(QueryException e) {
      expected = 'The parent fields list is empty';
      Assert.areEqual(expected, e.getMessage(), testTitle);
    }

    testTitle = '異常系: 指定したリレーションIDフィールドが存在しない';
    System.debug(testTitle);
    parentClause = new ParentClause('noExistRelationId', 'Name');
    try {
      parentClause.build(oppFieldMap);
      Assert.fail(testTitle);
    } catch(QueryException e) {
      expected = 'The specified relation ID field does not exist in the object\'s fields';
      Assert.areEqual(expected, e.getMessage(), testTitle);
    }

    testTitle = '異常系: 指定したリレーションIDフィールドが参照型でない';
    System.debug(testTitle);
    parentClause = new ParentClause('Name', 'Id');
    try {
      parentClause.build(oppFieldMap);
      Assert.fail(testTitle);
    } catch(QueryException e) {
      expected = 'The specified relation ID field is not of reference type';
      Assert.areEqual(expected, e.getMessage(), testTitle);
    }

    testTitle = '異常系: 指定したリレーションIDフィールドにリレーション名が存在しない';
    System.debug(testTitle);
    parentClause = new ParentClause('ContactId', 'Id');
    try {
      parentClause.build(oppFieldMap);
      Assert.fail(testTitle);
    } catch(QueryException e) {
      expected = 'The specified relation ID field does not have a relationship name';
      Assert.areEqual(expected, e.getMessage(), testTitle);
    }

  }
}
