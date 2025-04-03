@isTest(seeAllData=false)
public with sharing class OppNameUpdator_T {

  @isTest(seeAllData=false)
  public static void testExecute() {
      // create test Data
      Account acc = new Account(Name='Test Account');
      insert acc;
      Opportunity opp = new Opportunity();
      opp.Name = 'Test Opportunity';
      opp.StageName = 'Prospecting';
      opp.CloseDate = Date.today().addDays(30);
      opp.AccountId = acc.Id;
      insert opp;

      // create instance of the class
      OppNameUpdator updator = new OppNameUpdator(opp.Id);

      // execute the method
      Opportunity updatedOpp = updator.execute();

      // verify the result
      String exceptedName = 'Updated Opportunity Name';
      System.assertEquals(exceptedName, updatedOpp.Name);
  }
}


