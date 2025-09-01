public abstract class AbstractEntry implements IEntry {
  protected final SObject record;
  protected final FieldStructure fieldStructure;
  protected Schema.DescribeSObjectResult describeResult;

  /**
   * constructor
   *
   * @param record SObject
   */
  protected AbstractEntry(SObject record) {
    this.record = record;
    this.fieldStructure = null;
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

  /**
   * @inheritDoc
   */
  public void setDescribeResult(Schema.DescribeSObjectResult describeResult) {
    this.describeResult = describeResult;
  }

  // abstract methods to be implemented by subclasses
  public abstract Object get(String fieldName);
  public abstract IEntry getParent(String parentFieldName);
  public abstract List<IEntry> getChildren(String childObjectName);
  public abstract IEntry setRecord(SObject record);
  public abstract Id getId();
  public abstract String getName();
  public abstract IEntry setFieldStructure(FieldStructure fieldStructure);
}
