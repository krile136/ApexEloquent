public with sharing class MockEntry extends AbstractEntry {
  private final Map<String, Object> fieldToValue;

  public MockEntry(SObject record) {
    super(record);
    this.fieldToValue = new Map<String, Object>();
  }

  public MockEntry(SObject record, Map<String, Object> fieldToValue) {
    super(record);
    this.fieldToValue = fieldToValue;
  }

  public MockEntry(SObject record, FieldStructure fieldStructure) {
    super(record, fieldStructure);
    this.fieldToValue = new Map<String, Object>();
  }

  @TestVisible
  private MockEntry(SObject record, FieldStructure fieldStructure, Map<String, Object> fieldToValue) {
    super(record, fieldStructure);
    this.fieldToValue = fieldToValue;
  }

  public override Object get(String fieldName) {
    this.validateFieldName(fieldName);

    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }

    for (String key : this.fieldToValue.keySet()) {
      if (key.equalsIgnoreCase(fieldName)) {
        return this.fieldToValue.get(key);
      }
    }

    Entry entry = new Entry(this.record);
    return entry.get(fieldName);
  }

  public override IEntry getParent(String parentIdFieldName) {
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }

    String lowerCaseFieldName = parentIdFieldName.toLowerCase();

    if (!this.fieldStructure.hasRelation(lowerCaseFieldName)) {
      String error = String.format(
        'The specified parentIdFieldName is not set in Scribe. object name: {0}, parent Id field name: {1}',
        new List<String>{ this.describeResult.getName(), parentIdFieldName }
      );
      throw new QueryException(error);
    }

    if (this.fieldToValue.containsKey(parentIdFieldName)) {
      IEntry resultEntry = (IEntry) this.fieldToValue.get(parentIdFieldName);
      FieldStructure parentFieldStructure = this.fieldStructure == null
        ? new FieldStructure(new List<String>())
        : this.fieldStructure.getRelationFieldStructure(lowerCaseFieldName);
      return resultEntry.setFieldStructure(parentFieldStructure);
    }

    Entry entry = new Entry(this.record);
    return entry.getParent(parentIdFieldName);
  }

  public override List<IEntry> getChildren(String childObjectName) {
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }
    // for validate the childObjectName
    String childRelationName = this.getChildrenRelationNameFromChildObjectName(childObjectName);

    String lowerCastChildObjectName = childObjectName.toLowerCase();

    if (!this.fieldStructure.hasRelation(lowerCastChildObjectName)) {
      String error = String.format(
        'The specified childObjectName is not set in Scribe. object name: {0}, child object name: {1}',
        new List<String>{ this.describeResult.getName(), childObjectName }
      );
      throw new QueryException(error);
    }

    if (this.fieldToValue.containsKey(childObjectName)) {
      List<IEntry> entries;
      Object childObject = this.fieldToValue.get(childObjectName);
      if (childObject instanceof List<IEntry>) {
        entries = (List<IEntry>) childObject;
      } else if (childObject instanceof IEntry) {
        entries = new List<IEntry>{ (IEntry) childObject };
      } else {
        String error = String.format(
          'The child object needs to be a List<IEntry> or IEntry. object name: {0}, child object name: {1}',
          new List<String>{ this.describeResult.getName(), childObjectName }
        );
        throw new QueryException(error);
      }

      List<IEntry> resultEntries = new List<IEntry>();
      FieldStructure childFieldStructure = this.fieldStructure == null
        ? null
        : this.fieldStructure.getRelationFieldStructure(lowerCastChildObjectName);
      for (IEntry entry : entries) {
        resultEntries.add(entry.setFieldStructure(childFieldStructure));
      }

      return resultEntries;
    }

    Entry entry = new Entry(this.record);
    return entry.getChildren(childObjectName);
  }

  public override List<IEntry> getChildrenByRelationName(String childRelationName) {
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }

    String lowerCaseRelationName = childRelationName.toLowerCase();

    if (!this.fieldStructure.hasRelation(lowerCaseRelationName)) {
      String error = String.format(
        'The specified childRelationName is not set in Scribe. object name: {0}, child relation name: {1}',
        new List<String>{ this.describeResult.getName(), childRelationName }
      );
      throw new QueryException(error);
    }

    this.validateChildRelationName(childRelationName);

    if (this.fieldToValue.containsKey(childRelationName)) {
      List<IEntry> entries;
      Object childObject = this.fieldToValue.get(childRelationName);
      if (childObject instanceof List<IEntry>) {
        entries = (List<IEntry>) childObject;
      } else if (childObject instanceof IEntry) {
        entries = new List<IEntry>{ (IEntry) childObject };
      } else {
        String error = String.format(
          'The child object needs to be a List<IEntry> or IEntry. object name: {0}, child object relation name: {1}',
          new List<String>{ this.describeResult.getName(), childRelationName }
        );
        throw new QueryException(error);
      }

      List<IEntry> resultEntries = new List<IEntry>();
      FieldStructure childFieldStructure = this.fieldStructure == null
        ? null
        : this.fieldStructure.getRelationFieldStructure(lowerCaseRelationName);
      for (IEntry entry : entries) {
        resultEntries.add(entry.setFieldStructure(childFieldStructure));
      }

      return resultEntries;
    }

    Entry entry = new Entry(this.record);
    return entry.getChildrenByRelationName(childRelationName);
  }

  /**
   * @inheritDoc
   */
  public override Id getId() {
    this.validateFieldName('Id');

    if (this.fieldToValue.containsKey('Id')) {
      return (Id) this.fieldToValue.get('Id');
    }

    return (Id) this.record.get('Id');
  }

  /**
   * @inheritDoc
   */
  public override String getName() {
    this.validateFieldName('Name');

    if (this.fieldToValue.containsKey('Name')) {
      return (String) this.fieldToValue.get('Name');
    }

    return (String) this.record.get('Name');
  }

  public override IEntry setRecord(SObject record) {
    return new MockEntry(record, this.fieldStructure, this.fieldToValue);
  }

  public override IEntry setFieldStructure(FieldStructure fieldStructure) {
    return new MockEntry(this.record, fieldStructure, this.fieldToValue);
  }

  /**
   * validate the field name.
   *
   * @param fieldName field name to be validated
   * @throws QueryException if the field is not picked in Scribe
   */
  private void validateFieldName(String fieldName) {
    String lowerCaseFieldName = fieldName.toLowerCase();
    if (this.fieldStructure.hasField(lowerCaseFieldName)) {
      return;
    }

    String error = String.format(
      'The specified field is not selected in Scribe. object name: {0}, field name: {1}',
      new List<String>{ this.record.getSObjectType().getDescribe().getName(), fieldName }
    );
    throw new QueryException(error);
  }
}
