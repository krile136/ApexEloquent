public with sharing class Entry extends AbstractEntry {
  /**
   * constructor
   *
   * @param record SObject
   */
  public Entry(SObject record) {
    super(record);
  }

  /**
   * constructor for AggregateResult
   *
   * @param aggregateResult AggregateResult
   * @param fieldStructure FieldStructure
   */
  public Entry(AggregateResult aggregateResult, FieldStructure fieldStructure) {
    super(aggregateResult, fieldStructure);
  }

  /**
   * @inheritDoc
   */
  public override Object get(String fieldName) {
    if (this.hasAggregateResult) {
      if (!this.fieldStructure.hasField(fieldName.toLowerCase())) {
        String error = String.format(
          'The specified field or alias is not exist in Scribe. field or alias name: {0}',
          new List<String>{ fieldName }
        );
        throw new QueryException(error);
      }
      return this.aggregateResult.get(fieldName);
    }

    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }

    // validate the fieldName
    Map<String, Schema.SObjectField> fieldMap = this.describeResult.fields.getMap();
    if (!fieldMap.containsKey(fieldName)) {
      String error = String.format(
        'The specified field does not exist in the object\'s fields. object name: {0}, field name: {1}',
        new List<String>{ this.describeResult.getName(), fieldName }
      );
      throw new QueryException(error);
    }

    return this.record.get(fieldName);
  }

  /**
   * @inheritDoc
   */
  public override IEntry getParent(String parentIdFieldName) {
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }
    Map<String, Schema.SObjectField> fieldMap = this.describeResult.fields.getMap();

    Schema.SObjectField field = fieldMap.get(parentIdFieldName);
    if (field == null) {
      String error = String.format(
        'The specified parentIdFieldName does not exist in the object\'s fields. object name: {0}, parent Id field name: {1}',
        new List<String>{ this.describeResult.getName(), parentIdFieldName }
      );
      throw new QueryException(error);
    }

    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
    if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
      String error = String.format(
        'The specified parentIdFieldName is not a reference type. object name: {0}, parent Id field name: {1}',
        new List<String>{ this.describeResult.getName(), parentIdFieldName }
      );
      throw new QueryException(error);
    }

    String parentRelationName = fieldDescribe.getRelationshipName();
    SObject parentSObject = this.record.getSObject(parentRelationName);
    if (parentSObject == null) {
      return null;
    }

    return new Entry(parentSObject);
  }

  /**
   * @inheritDoc
   */
  public override List<IEntry> getChildren(String childObjectName) {
    System.debug('getChildren called. childObjectName: ' + childObjectName);
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }
    List<Schema.ChildRelationship> childRelationShips = this.describeResult.getChildRelationships();

    String childRelationName = this.getChildrenRelationNameFromChildObjectName(childObjectName);
    List<IEntry> childRecords = new List<IEntry>();
    for (SObject childSObject : this.record.getSObjects(childRelationName)) {
      childRecords.add(new Entry(ChildSObject));
    }

    return childRecords;
  }

  /**
   * @inheritDoc
   */
  public override List<IEntry> getChildrenByRelationName(String childRelationName) {
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }

    this.validateChildRelationName(childRelationName);

    List<IEntry> childRecords = new List<IEntry>();
    for (SObject childSObject : this.record.getSObjects(childRelationName)) {
      childRecords.add(new Entry(ChildSObject));
    }

    return childRecords;
  }

  /**
   * @inheritDoc
   */
  public override Id getId() {
    return (Id) this.record.get('Id');
  }

  /**
   * @inheritDoc
   */
  public override String getName() {
    return (String) this.record.get('Name');
  }

  /**
   * @inheritDoc
   */
  public override IEntry setRecord(SObject record) {
    return new Entry(record);
  }

  /**
   * @inheritDoc
   */
  public override IEntry setFieldStructure(FieldStructure fieldStructure) {
    throw new QueryException(
      'Field structure is not supported in Entry class. Use MockEntry for testing purposes.'
    );
  }
}
