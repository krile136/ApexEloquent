@isTest(seeAllData=false)
public with sharing class OrderByClause_T {
  public static testMethod void build() {
    OrderByClause clause;
    String result;
    String expected;

    String testTitle = '正常系: OrderBy句が組み立てられる';
    clause = new OrderByClause('Name');
    result = clause.build();
    expected = 'ORDER BY Name ASC';
    Assert.areEqual(expected, result, testTitle);

    testTitle = '正常系: OrderBy句が組み立てられる（降順）';
    clause = new OrderByClause('Name', 'DESC');
    result = clause.build();
    expected = 'ORDER BY Name DESC';
    Assert.areEqual(expected, result, testTitle);

    testTitle = '正常系: OrderBy句が組み立てられる（NULLS FIRST）';
    clause = new OrderByClause('Name', 'ASC', 'FIRST');
    result = clause.build();
    expected = 'ORDER BY Name ASC NULLS FIRST';
    Assert.areEqual(expected, result, testTitle);

    testTitle = '正常系: OrderBy句が組み立てられる（複数フィールド）';
    clause = new OrderByClause(new List<String>{ 'Name', 'Id' });
    result = clause.build();
    expected = 'ORDER BY Name, Id ASC';
    Assert.areEqual(expected, result, testTitle);

    testTitle = '正常系: OrderBy句が組み立てられる（複数フィールド、降順）';
    clause = new OrderByClause(new List<String>{ 'Name', 'Id' }, 'DESC');
    result = clause.build();
    expected = 'ORDER BY Name, Id DESC';
    Assert.areEqual(expected, result, testTitle);

    testTitle = '正常系: OrderBy句が組み立てられる（複数フィールド、NULLS LAST）';
    clause = new OrderByClause(new List<String>{ 'Name', 'Id' }, 'ASC', 'LAST');
    result = clause.build();
    expected = 'ORDER BY Name, Id ASC NULLS LAST';
    Assert.areEqual(expected, result, testTitle);
  }
}
