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

    this.validateFieldName(fieldName);
    return this.record.get(fieldName);
  }

  /**
   * @inheritDoc
   */
  public override void put(String fieldName, Object value) {
    if (this.hasAggregateResult) {
      String error = 'Cannot call put() on an AggregateResult record.';
      throw new QueryException(error);
    }

    this.validateFieldName(fieldName);
    this.record.put(fieldName, value);
  }

  /**
   * @inheritDoc
   */
  public override IEntry getParent(String parentIdFieldName) {
    this.ensureDescribeResultIfNeeded();
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
    this.ensureDescribeResultIfNeeded();
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
    this.ensureDescribeResultIfNeeded();
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
  public override SObject getRecord() {
    return this.record;
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

  /**
  * validate field name
  *
  * @param fieldName field name to be validated
  * @throws QueryException if the field is not exist in the SObject
  */
  private void validateFieldName(String fieldName) {
    this.ensureDescribeResultIfNeeded();
    Map<String, Schema.SObjectField> fieldMap = this.describeResult.fields.getMap();
    if (!fieldMap.containsKey(fieldName)) {
      String error = String.format(
        'The specified field does not exist in the object\'s fields. object name: {0}, field name: {1}',
        new List<String>{ this.describeResult.getName(), fieldName }
      );
      throw new QueryException(error);
    }
  }
}
