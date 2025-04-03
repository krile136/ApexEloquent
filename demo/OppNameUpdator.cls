// execute SOQL directly pattern
public with sharing class OppNameUpdator {
  private final Id oppId;

  /**
  * constructor
  *
  * @param oppId the Id of the Opportunity to update
  */
  public OppNameUpdator(Id oppId) {
    this.oppId = oppId;
  }

  /**
  * Updates the name of the Opportunity record with the given Id.
  */
  public Opportunity execute() {
    // Get the Opportunity record
    Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :oppId LIMIT 1];

    // Update the Opportunity name
    opp.Name = 'Updated Opportunity Name';

    // Update the record in the database
    update opp;

    return opp;
  }
}





