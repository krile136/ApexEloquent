public abstract class AbstractEntry implements IEntry {
  protected final SObject record;
  protected final AggregateResult aggregateResult;
  protected final FieldStructure fieldStructure;
  protected Schema.DescribeSObjectResult describeResult;
  @TestVisible
  protected Boolean hasAggregateResult = false;

  /**
   * constructor
   *
   * @param record SObject
   */
  protected AbstractEntry(SObject record) {
    this.record = record;
    this.aggregateResult = null;
    this.fieldStructure = null;
    this.hasAggregateResult = this.record == null;
  }

  /**
   * constructor for AggregateResult
   *
   * @param aggregateResult AggregateResult
   */
  protected AbstractEntry(AggregateResult aggregateResult, FieldStructure fieldStructure) {
    this.record = null;
    this.aggregateResult = aggregateResult;
    this.fieldStructure = fieldStructure;
    this.hasAggregateResult = this.record == null;
  }

  /**
   * constructor with selected fields and relation fields
   *
   * @param record SObject
   * @param fieldStructure FieldStructure containing picked fields and relations
   */
  protected AbstractEntry(SObject record, FieldStructure fieldStructure) {
    this.record = record;
    this.fieldStructure = fieldStructure;
    this.hasAggregateResult = this.record == null;
  }

  /**
   * validate the relation name.
   *
   * @param relationName relation name to be validated
   * @throws QueryException if the relation is not exist in Scribe
   */
  protected void validateRelationName(String relationName) {
    if (this.fieldStructure == null) {
      return;
    }

    if (fieldStructure.hasRelation(relationName)) {
      return;
    }

    String error = String.format(
      'The specified relation is not exist in Scribe. object name: {0}, relation name: {1}',
      new List<String>{ this.record.getSObjectType().getDescribe().getName(), relationName }
    );

    throw new QueryException(error);
  }

  /**
   * @inheritDoc
   */
  public SObject getRecord() {
    return this.record;
  }

  /**
   * @inheritDoc
   */
  public List<IEntry> getThrough(String junctionObjectName, String relatedKey) {
    List<IEntry> junctionEntries = this.getChildren(junctionObjectName);
    if (junctionEntries.isEmpty()) {
      return new List<IEntry>();
    }

    List<IEntry> relatedEntries = new List<IEntry>();
    Schema.DescribeSObjectResult junctionDescribeResult = junctionEntries[0]
      .getRecord()
      .getSObjectType()
      .getDescribe();
    for (IEntry junctionEntry : junctionEntries) {
      junctionEntry.setDescribeResult(junctionDescribeResult);
      relatedEntries.add(junctionEntry.getParent(relatedKey)); 
    }
    return relatedEntries;
  }

  public List<IEntry> getThroughByRelationName(String junctionRelationName, String relatedKey) {
    List<IEntry> junctionEntries = this.getChildrenByRelationName(junctionRelationName);
    if (junctionEntries.isEmpty()) {
      return new List<IEntry>();
    }

    List<IEntry> relatedEntries = new List<IEntry>();
    Schema.DescribeSObjectResult junctionDescribeResult = junctionEntries[0]
      .getRecord()
      .getSObjectType()
      .getDescribe();
    for (IEntry junctionEntry : junctionEntries) {
      junctionEntry.setDescribeResult(junctionDescribeResult);
      relatedEntries.add(junctionEntry.getParent(relatedKey)); 
    }
    return relatedEntries;
  }

  /**
   * @inheritDoc
   */
  public void setDescribeResult(Schema.DescribeSObjectResult describeResult) {
    this.describeResult = describeResult;
  }

  /**
    * get child relation name from child object name.
    * If there are multiple relationships with the same child object name, an exception is thrown.
    *
    * @param childObjectName child object name
    * @return child relation name
    * @throws QueryException if the child object name is not exist in the parent object's children relationships
    *                        or if there are multiple relationships with the same child object name
    */
  protected String getChildrenRelationNameFromChildObjectName(String childObjectName) {
    List<Schema.ChildRelationship> childRelationShips = this.describeResult.getChildRelationships();

    Schema.ChildRelationship targetChildRelationShip;
    for (Schema.ChildRelationship childRelationShip : childRelationShips) {
      if (childRelationShip.getChildSObject().getDescribe().getName() == childObjectName) {
        if (targetChildRelationShip != null) {
          String error = String.format(
            'The specified childObjectName has multiple relationships in the parent object\'s children relationships. Please specify the relationship name instead of the object name. parent object name: {0}, child object name: {1}',
            new List<String>{ this.describeResult.getName(), childObjectName }
          );
          throw new QueryException(error);
        }
        targetChildRelationShip = childRelationShip;
      }
    }
    if (targetChildRelationShip == null) {
      String error = String.format(
        'The specified childObjectName does not exist in the parent object\'s children relationships. parent object name: {0}, child object name: {1}',
        new List<String>{ this.describeResult.getName(), childObjectName }
      );
      throw new QueryException(error);
    }

    String childRelationName = targetChildRelationShip.getRelationshipName();

    return childRelationName;
  }

  /**
   * validate the child relation name.
   *
   * @param childRelationName child relation name to be validated
   * @throws QueryException if the child relation name is not exist in the parent object's children relationships
   */
  protected void validateChildRelationName(String childRelationName) {
    List<Schema.ChildRelationship> childRelationShips = this.describeResult.getChildRelationships();

    Boolean found = false;
    for (Schema.ChildRelationship childRelationShip : childRelationShips) {
      if (childRelationShip.getRelationshipName() == childRelationName) {
        found = true;
        break;
      }
    }
    if (!found) {
      String error = String.format(
        'The specified childRelationName does not exist in the parent object\'s children relationships. parent object name: {0}, child relation name: {1}',
        new List<String>{ this.describeResult.getName(), childRelationName }
      );
      throw new QueryException(error);
    }
  }

  // abstract methods to be implemented by subclasses
  public abstract Object get(String fieldName);
  public abstract IEntry getParent(String parentFieldName);
  public abstract List<IEntry> getChildren(String childObjectName);
  public abstract List<IEntry> getChildrenByRelationName(String childRelationName);
  public abstract IEntry setRecord(SObject record);
  public abstract Id getId();
  public abstract String getName();
  public abstract IEntry setFieldStructure(FieldStructure fieldStructure);
}
