@isTest(seeAllData=false)
public with sharing class OppNameUpdatorUsingApexEloquent_T {

  @isTest(seeAllData=false)
  public static void testExecute() {
    // create test Data
    Opportunity mockOpp = new Opportunity();
    mockOpp.Id = '006000000000001';
    mockOpp.Name = 'Test Opportunity';

    // create MockRepository
    MockRepository mockRepository = new MockRepository(mockOpp);

    // create instance of the class
    OppNameUpdatorUsingApexEloquent updator = new OppNameUpdatorUsingApexEloquent(mockOpp.Id, mockRepository);

    // execute the method
    Opportunity updatedOpp = updator.execute();

    // verify the result
    String expectedName = 'Updated Opportunity Name';
  }
}
