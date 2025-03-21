@isTest(seeAllData=false)
public with sharing class MockRepository_T {
  public static testMethod void testMockDML() {
    String testTitle;
    Query query;
    RepositoryInterface repository;

    Opportunity mockOpp;
    Opportunity opp;

    testTitle = '正常系: firstメソッドの取得結果がMockで指定したものに変わる';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    mockOpp.Id = '006000000000009';
    repository = new MockRepository(mockOpp);
    query = (new Query()).source(Opportunity.getSObjectType()).pick('Id').condition('Id', '=', '006000000000000');
    opp = (Opportunity) repository.first(query);
    Assert.areEqual(mockOpp.Id, opp.Id, testTitle);

    testTitle = '正常系: firstOrFailメソッドの取得結果がMockで指定したものに変わる';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    mockOpp.Id = '006000000000009';
    repository = new MockRepository(mockOpp);
    query = (new Query()).source(Opportunity.getSObjectType()).pick('Id').condition('Id', '=', '006000000000000');
    opp = (Opportunity) repository.firstOrFail(query);
    Assert.areEqual(mockOpp.Id, opp.Id, testTitle);

    testTitle = '正常系: getメソッドの取得結果がMockで指定したものに変わる';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    mockOpp.Id = '006000000000009';
    repository = new MockRepository(new List<SObject>{ mockOpp });
    query = (new Query()).source(Opportunity.getSObjectType()).pick('Id').condition('Id', '=', '006000000000000');
    List<Opportunity> opps = (List<Opportunity>) repository.get(query);
    Assert.areEqual(1, opps.size(), testTitle);
    Assert.areEqual(mockOpp.Id, opps[0].Id, testTitle);

    testTitle = '正常系: getメソッドの取得結果がMockで指定したものに変わる';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    mockOpp.Id = '006000000000009';
    repository = new MockRepository(new List<SObject>{ mockOpp });
    query = (new Query()).source(Opportunity.getSObjectType()).pick('Id').condition('Id', '=', '006000000000000');
    opps = (List<Opportunity>) repository.getOrFail(query);
    Assert.areEqual(1, opps.size(), testTitle);
    Assert.areEqual(mockOpp.Id, opps[0].Id, testTitle);

    testTitle = '正常系: MockでもInsertすることができ、架空のIDがセットされる（レコードを一つ挿入）';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    repository = new MockRepository();
    Opportunity insertedOpp = (Opportunity) repository.doInsert(mockOpp);
    Assert.areEqual('006000000000000', insertedOpp.Id, testTitle);

    testTitle = '正常系: MockでもInsertすることができ、架空のIDがセットされる（レコードを複数挿入）';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    Opportunity mockOpp2 = new Opportunity();
    List<Opportunity> mockOpps = new List<Opportunity>{ mockOpp, mockOpp2 };
    repository = new MockRepository();
    List<Opportunity> insertedOpps = (List<Opportunity>) repository.doInsert(mockOpps);
    Assert.areEqual('006000000000000', insertedOpps[0].Id, testTitle);
    Assert.areEqual('006000000000001', insertedOpps[1].Id, testTitle);

    testTitle = '正常系: MockでもUpdateすることができ、引数のレコードがそのまま返る(レコードを一つ更新)';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    mockOpp.Id = '006000000000009';
    repository = new MockRepository();
    Opportunity updatedOpp = (Opportunity) repository.doUpdate(mockOpp);
    Assert.areEqual(mockOpp.Id, updatedOpp.Id, testTitle);

    testTitle = '正常系: MockでもUpdateすることができ、引数のレコードがそのまま返る(レコードを複数更新)';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    mockOpp.Id = '006000000000009';
    mockOpp2 = new Opportunity();
    mockOpp2.Id = '006000000000010';
    mockOpps = new List<Opportunity>{ mockOpp, mockOpp2 };
    repository = new MockRepository();
    List<Opportunity> updatedOpps = (List<Opportunity>) repository.doUpdate(mockOpps);
    Assert.areEqual(mockOpp.Id, updatedOpps[0].Id, testTitle);
    Assert.areEqual(mockOpp2.Id, updatedOpps[1].Id, testTitle);

    testTitle = '正常系: MockでもDeleteすることができる。(レコードを一つ削除)';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    mockOpp.Id = '006000000000009';
    repository = new MockRepository();
    repository.doDelete(mockOpp);

    testTitle = '正常系: MockでもDeleteすることができる。(レコードを複数削除)';
    System.debug(testTitle);
    mockOpp = new Opportunity();
    mockOpp.Id = '006000000000009';
    mockOpp2 = new Opportunity();
    mockOpp2.Id = '006000000000010';
    mockOpps = new List<Opportunity>{ mockOpp, mockOpp2 };
    repository = new MockRepository();
    repository.doDelete(mockOpps);

  }
}
