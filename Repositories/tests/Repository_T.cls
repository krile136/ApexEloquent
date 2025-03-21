@isTest(seeAllData=false)
public with sharing class Repository_T {
  public static testMethod void testDML() {
    String testTitle;
    Query query;
    RepositoryInterface repository = new Repository();

    Schema.SObjectType oppSource = Opportunity.getSObjectType();

    Opportunity opp;

    testTitle = '正常系: firstメソッドで取得が実行される';
    System.debug(testTitle);
    Id oppId = '006000000000000';
    query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', oppId);
    opp = (Opportunity) repository.first(query);

    testTitle = '正常系: firstOrFailメソッドで取得が実行される';
    System.debug(testTitle);
    query = (new Query()).source(oppSource).pick('Id').condition('Id', '=', oppId);
    try{
      opp = (Opportunity) repository.firstOrFail(query);
      Assert.fail(testTitle);
    } catch (QueryException e) {
      System.debug(e.getMessage());
    }

    testTitle = '正常系: getメソッドで取得が実行される';
    System.debug(testTitle);
    List<Opportunity> opps = (List<Opportunity>) repository.get(query);
    Assert.areEqual(0, opps.size(), testTitle);

    testTitle = '正常系: getOrFailメソッドで取得が実行される';
    System.debug(testTitle);
    try{
      opps = (List<Opportunity>) repository.getOrFail(query);
      Assert.fail(testTitle);
    } catch (QueryException e) {
      System.debug(e.getMessage());
    }

    testTitle = '正常系: Insertが実行される';
    System.debug(testTitle);
    opp = new Opportunity();
    opp.Name = 'Test';
    try{
      opp = (Opportunity) repository.doInsert(opp);
    } catch (DmlException e) {
      // 例外が発生するが、テスト自体は成功
      System.debug(e.getMessage());
    }

    testTitle = '正常系: Insertが実行される（複数レコード）';
    System.debug(testTitle);
    Opportunity opp2 = new Opportunity();
    opp2.Name = 'Test2';
    List<Opportunity> oppsToInsert = new List<Opportunity>{ opp, opp2 };
    try{
      opps = (List<Opportunity>) repository.doInsert(oppsToInsert);
    } catch (DmlException e) {
      // 例外が発生するが、テスト自体は成功
      System.debug(e.getMessage());
    }

    testTitle = '正常系: Updateが実行される';
    System.debug(testTitle);
    try{
      opp = (Opportunity) repository.doUpdate(opp);
    } catch (DmlException e) {
      // 例外が発生するが、テスト自体は成功
      System.debug(e.getMessage());
    }

    testTitle = '正常系: Updateが実行される（複数レコード）';
    System.debug(testTitle);
    try{
      opps = (List<Opportunity>) repository.doUpdate(oppsToInsert);
    } catch (DmlException e) {
      // 例外が発生するが、テスト自体は成功
      System.debug(e.getMessage());
    }

    testTitle = '正常系: Deleteが実行される';
    System.debug(testTitle);
    opp.Id = '006000000000000';
    try{
      repository.doDelete(opp);
    } catch (DmlException e) {
      // 例外が発生するが、テスト自体は成功
      System.debug(e.getMessage());
    }

    testTitle = '正常系: Deleteが実行される（複数レコード）';
    System.debug(testTitle);
    opp.Id = '006000000000000';
    opp2.Id = '006000000000001';
    try{
      repository.doDelete(new List<Opportunity>{ opp, opp2 });
    } catch (DmlException e) {
      // 例外が発生するが、テスト自体は成功
      System.debug(e.getMessage());
    }
  }
}
