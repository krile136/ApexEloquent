// execute SOQL using Apex Eloquent pattern
public with sharing class OppNameUpdatorUsingApexEloquent {
  private final Id oppId;
  private final RepositoryInterface repository;

  /**
  * constructor
  *
  * @param oppId the Id of the Opportunity to update
  */
  public OppNameUpdatorUsingApexEloquent(Id oppId) {
    this(oppId, null);
  }

  /**
  * private constructor for testing
  *
  * @param oppId the Id of the Opportunity to update
  * @param repository the repository to use for data access
  */
  @TestVisible
  private OppNameUpdatorUsingApexEloquent(Id oppId, RepositoryInterface repository) {
    this.oppId = oppId;
    this.repository = repository ?? new Repository();
  }

  /**
  * Updates the name of the Opportunity record with the given Id.
  */
  public Opportunity execute() {
    // Get the Opportunity record
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick(new List<String>{'Id', 'Name'})
      .condition('Id', '=', oppId);
    Opportunity opp = (Opportunity) this.repository.first(query);

    // Update the Opportunity name
    opp.Name = 'Updated Opportunity Name';

    // Update the record in the database
    Opportunity updatedOpp = (Opportunity) this.repository.doUpdate(opp);

    return updatedOpp;
  }
}



