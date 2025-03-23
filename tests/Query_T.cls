@isTest(seeAllData=false)
public with sharing class Query_T {
  public static testMethod void testQuery() {
    String testTitle;
    Query query;
    String queryString;
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Schema.SObjectType accountSource = Account.getSObjectType();

    testTitle = '正常系: fieldを一つ指定してレコードを取得するクエリを作成できる';
    System.debug(testTitle);
    query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', '006000000000000');
    queryString = 'SELECT Id FROM Opportunity WHERE (Id = \'006000000000000\')';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: fieldを複数指定してレコードを取得するクエリを作成できる';
    List<String> fields = new List<String>{ 'Id', 'Name' };
    System.debug(testTitle);
    query = (new Query()).source(oppSource).pick(fields).condition('Id', '=', '006000000000000');
    queryString = 'SELECT Id, Name FROM Opportunity WHERE (Id = \'006000000000000\')';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: 全フィールド取得を指定してレコードを取得するクエリを作成できる';
    query = (new Query()).source(oppSource).pickAll().condition('Id', '=', '006000000000000');
    queryString = 'SELECT FIELDS(ALL) FROM Opportunity WHERE (Id = \'006000000000000\')'; 
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: AND条件によるクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .condition('Name', '=', 'Test');
    queryString = 'SELECT Id FROM Opportunity WHERE (Id = \'006000000000000\' AND Name = \'Test\')';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: AND条件に配列を使用してクエリを作成できる';
    System.debug(testTitle);
    List<String> ids = new List<String>{ '006000000000000', '006000000000001' };
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Name', '=', 'Test')
      .condition('Id', 'IN', ids);
    queryString = 'SELECT Id FROM Opportunity WHERE (Name = \'Test\' AND Id IN (\'006000000000000\', \'006000000000001\'))';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: AND条件に配列を使用してクエリを作成できるが、配列が空の場合はヒットしない条件が追加される';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Name', '=', 'Test')
      .condition('Id', 'IN', new List<Id>());
    queryString = 'SELECT Id FROM Opportunity WHERE (Name = \'Test\' AND Id = NULL)';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: OR条件によるクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orCondition('Name', '=', 'Test');
    queryString = 'SELECT Id FROM Opportunity WHERE (Id = \'006000000000000\') OR (Name = \'Test\')';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: OR条件に配列を使用してクエリを作成できる';
    System.debug(testTitle);
    ids = new List<String>{ '006000000000000', '006000000000001' };
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Name', '=', 'Test')
      .orCondition('Id', 'IN', ids);
    queryString = 'SELECT Id FROM Opportunity WHERE (Name = \'Test\') OR (Id IN (\'006000000000000\', \'006000000000001\'))';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: OR条件に配列を使用してクエリを作成できるが、配列が空の場合はその条件はヒットしない条件が追加される';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Name', '=', 'Test')
      .orCondition('Id', 'IN', new List<Id>());
    queryString = 'SELECT Id FROM Opportunity WHERE (Name = \'Test\') OR (Id = NULL)';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: サブクエリを使い括弧で囲まれたAND条件を追加したクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .condition((new Query())
        .condition('Name', '=', 'Test')
        .condition('CloseDate', '<=', Date.newInstance(2024, 12, 31))
      );
    queryString = 'SELECT Id FROM Opportunity WHERE (Id = \'006000000000000\') AND ((Name = \'Test\' AND CloseDate <= 2024-12-31))';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: サブクエリを使い括弧で囲まれたAND条件を追加したクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Id', '=', '006000000000000')
      .orCondition((new Query())
        .condition('Name', '=', 'Test')
        .Condition('CloseDate', '<=', Date.newInstance(2024, 12, 31))
      );
    queryString = 'SELECT Id FROM Opportunity WHERE (Id = \'006000000000000\') OR ((Name = \'Test\' AND CloseDate <= 2024-12-31))';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: joinで別テーブルの条件を追加したクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Id','IN' , ids)
      .join('AccountId', 'IN', (new Query())
        .source(accountSource)
        .pick('Id')
        .condition('Name', '=', 'TestAccount')
      );
    queryString = 'SELECT Id FROM Opportunity WHERE (Id IN (\'006000000000000\', \'006000000000001\')) AND (AccountId IN (SELECT Id FROM Account WHERE (Name = \'TestAccount\')))';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: limitで取得件数を制限したクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .condition('Id','IN' , ids)
      .restrict(10);
    queryString = 'SELECT Id FROM Opportunity WHERE (Id IN (\'006000000000000\', \'006000000000001\')) LIMIT 10';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTItle = '正常系: 複雑な条件のクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick(fields)
      .condition('Id','IN' , ids)
      .condition((new Query())
        .condition('Name', '=', 'Test')
        .condition('CloseDate', '<=', Date.newInstance(2024, 12, 31))
      )
      .join('AccountId', 'IN', (new Query())
        .source(accountSource)
        .pick('Id')
        .condition('Name', '=', 'TestAccount')
      );
    queryString = 'SELECT Id, Name FROM Opportunity WHERE (Id IN (\'006000000000000\', \'006000000000001\')) AND ((Name = \'Test\' AND CloseDate <= 2024-12-31)) AND (AccountId IN (SELECT Id FROM Account WHERE (Name = \'TestAccount\')))';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: findメソッドでクエリを作成できる(IDを一つ指定するときは、salesforceの仕様でIDが18桁に自動変換される';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .find('006000000000000');
    queryString = 'SELECT Id FROM Opportunity WHERE (Id = \'006000000000000AAA\')';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: findManyメソッドでクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .findMany(ids);
    queryString = 'SELECT Id FROM Opportunity WHERE (Id IN (\'006000000000000\', \'006000000000001\'))';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: betweenInclusiveメソッドでクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .betweenInclusive('CloseDate', Date.newInstance(2024, 1, 1), Date.newInstance(2024, 12, 31));
    queryString = 'SELECT Id FROM Opportunity WHERE (CloseDate >= 2024-01-01 AND CloseDate <= 2024-12-31)';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: betweenExclusiveメソッドでクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .betweenExclusive('CloseDate', Date.newInstance(2024, 1, 1), Date.newInstance(2024, 12, 31));
    queryString = 'SELECT Id FROM Opportunity WHERE (CloseDate > 2024-01-01 AND CloseDate < 2024-12-31)';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: isNullメソッドでクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .isNull('CloseDate');
    queryString = 'SELECT Id FROM Opportunity WHERE (CloseDate = NULL)';
    Assert.areEqual(queryString, query.toSoql(), testTitle);

    testTitle = '正常系: isNotNullメソッドでクエリを作成できる';
    System.debug(testTitle);
    query = (new Query())
      .source(oppSource)
      .pick('Id')
      .isNotNull('CloseDate');
    queryString = 'SELECT Id FROM Opportunity WHERE (CloseDate != NULL)';
    Assert.areEqual(queryString, query.toSoql(), testTitle);


  }
}
