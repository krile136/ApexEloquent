public with sharing class Entry extends AbstractEntry {
  /**
   * constructor
   *
   * @param record SObject
   */
  public Entry(SObject record) {
    super(record);
  }

  public override Object get(String fieldName) {
    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();

    // validate the fieldName
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
    if (!fieldMap.containsKey(fieldName)) {
      String error = String.format(
        'The specified field does not exist in the object\'s fields. object name: {0}, field name: {1}',
        new List<String>{ describeResult.getName(), fieldName }
      );
      throw new QueryException(error);
    }

    return this.record.get(fieldName);
  }

  public override IEntry getParent(String parentIdFieldName) {
    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

    Schema.SObjectField field = fieldMap.get(parentIdFieldName);
    if (field == null) {
      String error = String.format(
        'The specified parentIdFieldName does not exist in the object\'s fields. object name: {0}, parent Id field name: {1}',
        new List<String>{ describeResult.getName(), parentIdFieldName }
      );
      throw new QueryException(error);
    }

    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
    if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
      String error = String.format(
        'The specified parentIdFieldName is not a reference type. object name: {0}, parent Id field name: {1}',
        new List<String>{ describeResult.getName(), parentIdFieldName }
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

  public override List<IEntry> getChildren(String childObjectName) {

    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();


    List<Schema.ChildRelationship> childRelationShips = describeResult.getChildRelationships();


    for (Schema.ChildRelationship childRelationShip : childRelationShips) {
      if (childRelationShip.getChildSObject().getDescribe().getName() == childObjectName) {
        String childRelationName = childRelationShip.getRelationshipName();
        List<IEntry> childRecords = new List<IEntry>();
        for (SObject childSObject : this.record.getSObjects(childRelationName)) {
          childRecords.add(new Entry(ChildSObject));
        }

        return childRecords;
      }
    }


    String error = String.format(
      'The specified childObjectName does not exist in the parent object\'s children relationships. parent object name: {0}, child object name: {1}',
      new List<String>{ describeResult.getName(), childObjectName }
    );
    throw new QueryException(error);
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

  public override IEntry setRecord(SObject record) {
    return new Entry(record);
  }

  public override IEntry setFieldStructure(FieldStructure fieldStructure) {
    throw new QueryException(
      'Field structure is not supported in Entry class. Use MockEntry for testing purposes.'
    );
  }
}
