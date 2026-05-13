/**
 * Copyright 2025 Hiroyuki Matsuoka
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @description The concrete implementation of the `IEntry` interface for wrapping real records
 * returned from a Salesforce database query.
 *
 * An `Entry` instance can represent either a standard `SObject` record (from a `Scribe` query)
 * or an `AggregateResult` record (from an aggregate `Scribe` query). It provides access
 * to field values and relationships by delegating calls to the underlying `SObject` or
 * `AggregateResult`'s standard methods (e.g., `.get()`, `.getSObject()`, `.getSObjects()`).
 *
 * This class is the production counterpart to `MockEntry`.
 * @see IEntry
 * @see AbstractEntry
 * @see MockEntry
 */
public with sharing class Entry extends AbstractEntry {
  private static final String CLASS_NAME = 'Entry';

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
    String method = 'get(String fieldName)';
    if (fieldName == null || String.isBlank(fieldName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'fieldName', fieldName).fire();
    }

    if (this.hasAggregateResult) {
      if (!this.fieldStructure.hasField(fieldName.toLowerCase())) {
        String reason = 'The specified field or alias is not exist in Scribe.';
        String action = 'Add the field or alias to the Scribe definition for this AggregateResult';
        ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'fieldName', fieldName).fire();
      }
      return this.aggregateResult.get(fieldName);
    }

    try {
      this.validateFieldName(fieldName);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action = 'Ensure that the field name is correct and exists in the object\'s fields.';
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'fieldName', fieldName, e).fire();
    }
    return this.record.get(fieldName);
  }

  /**
   * @inheritDoc
   */
  public override void put(String fieldName, Object value) {
    String method = 'put(String fieldName, Object value)';
    if (this.hasAggregateResult) {
      String reason = 'The put() operation is incompatible with AggregateResult-based Entry instances';
      ApexEloquentException.invalidOperation(CLASS_NAME, method, reason).fire();
    }

    try {
      this.validateFieldName(fieldName);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action = 'Ensure that the field name is correct and exists in the object\'s fields.';
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'fieldName', fieldName, e).fire();
    }
    this.record.put(fieldName, value);
  }

  /**
   * @inheritDoc
   */
  public override IEntry getParent(String parentIdFieldName) {
    String method = 'getParent(String parentIdFieldName)';
    if (parentIdFieldName == null || String.isBlank(parentIdFieldName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'parentIdFieldName', parentIdFieldName).fire();
    }

    this.ensureDescribeResultIfNeeded();
    Map<String, Schema.SObjectField> fieldMap = this.describeResult.fields.getMap();

    Schema.SObjectField field = fieldMap.get(parentIdFieldName);
    if (field == null) {
      String reason =
        'The specified parentIdFieldName does not exist in the object\'s fields. Object name:' +
        this.describeResult.getName();
      String action = 'Ensure that the parentIdFieldName is correct and exists in the object\'s fields.';
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'parentIdFieldName',
          parentIdFieldName
        )
        .fire();
    }

    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
    if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
      String reason =
        'The specified parentIdFieldName is not a reference type. Object name:' + this.describeResult.getName();
      String action = 'Ensure that the parentIdFieldName is a reference type field.';
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'parentIdFieldName',
          parentIdFieldName
        )
        .fire();
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
    String method = 'getChildren(String childObjectName)';
    if (childObjectName == null || String.isBlank(childObjectName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'childObjectName', childObjectName).fire();
    }

    this.ensureDescribeResultIfNeeded();
    List<Schema.ChildRelationship> childRelationShips = this.describeResult.getChildRelationships();

    String childRelationName = null;
    try {
      childRelationName = this.getChildrenRelationNameFromChildObjectName(childObjectName);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action = 'Ensure that the child object name is correct and exists in the parent object\'s child relationships.';
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'childObjectName',
          childObjectName,
          e
        )
        .fire();
    }
    List<IEntry> childRecords = new List<IEntry>();
    for (SObject childSObject : this.record.getSObjects(childRelationName)) {
      childRecords.add(new Entry(childSObject));
    }

    return childRecords;
  }

  /**
   * @inheritDoc
   */
  public override List<IEntry> getChildrenByRelationName(String childRelationName) {
    String method = 'getChildrenByRelationName(String childRelationName)';
    if (childRelationName == null || String.isBlank(childRelationName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'childRelationName', childRelationName).fire();
    }

    this.ensureDescribeResultIfNeeded();
    try {
      this.validateChildRelationName(childRelationName);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action = 'Ensure that the child relation name is correct and exists in the parent object\'s child relationships.';
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'childRelationName',
          childRelationName,
          e
        )
        .fire();
    }

    List<IEntry> childRecords = new List<IEntry>();
    for (SObject childSObject : this.record.getSObjects(childRelationName)) {
      childRecords.add(new Entry(childSObject));
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
  public override SObject getRecord() {
    if (this.hasAggregateResult) {
      ApexEloquentException.invalidOperation(
          CLASS_NAME,
          'getRecord()',
          'getRecord() is not supported on an Entry that represents an AggregateResult'
        )
        .fire();
    }
    // Return a defensive deep clone so callers cannot mutate the cached internal state.
    return this.record.clone(true, true, true, true);
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
    String method = 'setFieldStructure(FieldStructure fieldStructure)';
    String reason = 'The setFieldStructure() method is not supported in Entry class because this class represents actual database records. If you need to validate field access in a test context, please ensure you are using a MockEntry instance instead.';
    ApexEloquentException.invalidOperation(CLASS_NAME, method, reason).fire();

    // This line will never be reached because the above method call will always throw an exception, but it is required to satisfy the method's return type.
    return null;
  }

  /**
   * validate field name
   *
   * @param fieldName field name to be validated
   * @throws ApexEloquentException if the field is not exist in the SObject
   */
  private void validateFieldName(String fieldName) {
    this.ensureDescribeResultIfNeeded();
    Map<String, Schema.SObjectField> fieldMap = this.describeResult.fields.getMap();
    if (!fieldMap.containsKey(fieldName)) {
      String reason = 'The specified field does not exist in the object\'s fields';
      String action = 'Ensure the field name is correct and exists on the SObject';
      ApexEloquentException.invalidArgument(CLASS_NAME, null, reason, action, 'fieldName', fieldName)
        .param('objectName', this.describeResult.getName())
        .fire();
    }
  }
}
