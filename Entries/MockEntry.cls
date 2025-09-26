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
 * @description The mock implementation of the `IEntry` interface, designed to facilitate
 * fast, reliable, and database-independent unit tests.
 *
 * A `MockEntry` wraps a base `SObject` instance but allows any field or relationship value
 * to be overridden via a `Map<String, Object>`. This enables the simulation of complex
 * data scenarios, including non-writable fields and relationships, without DML.
 *
 * It can also represent a virtual `AggregateResult` by being instantiated directly
 * with a map of values.
 *
 * Crucially, `MockEntry` is a high-fidelity mock. When provided with a `FieldStructure`,
 * it simulates the framework's "select-forgotten" validation, throwing an exception
 * if a test attempts to access data that was not part of the original query definition.
 * @see IEntry
 * @see AbstractEntry
 * @see Entry
 */
public with sharing class MockEntry extends AbstractEntry {
  private final Map<String, Object> fieldToValue;

  /**
   * constructor
   *
   * @param record SObject
   */
  public MockEntry(SObject record) {
    super(record);
    this.fieldToValue = new Map<String, Object>();
  }

  /**
   * constructor
   *
   * @param record SObject
   * @param fieldToValue field to value map
   */
  public MockEntry(SObject record, Map<String, Object> fieldToValue) {
    super(record);
    this.fieldToValue = fieldToValue;
  }

  /**
   * constructor
   *
   * @param record SObject
   * @param fieldStructure FieldStructure
   */
  public MockEntry(SObject record, FieldStructure fieldStructure) {
    super(record, fieldStructure);
    this.fieldToValue = new Map<String, Object>();
  }

  /**
   * constructor for AggregateResult
   *
   * @param fieldToValue field to value map
   */
  public MockEntry(Map<String, Object> fieldToValue) {
    super(null);
    this.fieldToValue = fieldToValue;
    this.hasAggregateResult = true;
  }

  /**
   * constructor for testing
   *
   * @param record SObject
   * @param fieldStructure FieldStructure
   * @param fieldToValue field to value map
   */
  @TestVisible
  private MockEntry(SObject record, FieldStructure fieldStructure, Map<String, Object> fieldToValue) {
    super(record, fieldStructure);
    this.fieldToValue = fieldToValue;
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

      for (String key : this.fieldToValue.keySet()) {
        if (key.equalsIgnoreCase(fieldName)) {
          Object value = this.fieldToValue.get(key);
          if (value instanceof IEntry) {
            IEntry entry = (IEntry) value;
            FieldStructure relationFieldStructure = this.fieldStructure == null
              ? new FieldStructure(new List<String>())
              : this.fieldStructure.getRelationFieldStructure(fieldname.toLowerCase());
            return entry.setFieldStructure(relationFieldStructure).getId();
          }
          return this.fieldToValue.get(key);
        }
      }

      // Since an AggregateResult cannot be instantiated like an SObject, we must throw an error if the requested field/alias is not found in the fieldToValue map.
      String error = String.format(
        'The specified field or alias is not found in the mock data. field or alias name: {0}',
        new List<String>{ fieldName }
      );
      throw new QueryException(error);
    }

    this.validateFieldName(fieldName);

    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }

    for (String key : this.fieldToValue.keySet()) {
      if (key.equalsIgnoreCase(fieldName)) {
        Object value = this.fieldToValue.get(key);
        if (value instanceof IEntry) {
          IEntry entry = (IEntry) value;
          FieldStructure relationFieldStructure = this.fieldStructure == null
            ? new FieldStructure(new List<String>())
            : this.fieldStructure.getRelationFieldStructure(fieldname.toLowerCase());
          return entry.setFieldStructure(relationFieldStructure).getId();
        }
        return this.fieldToValue.get(key);
      }
    }

    Entry entry = new Entry(this.record);
    return entry.get(fieldName);
  }

  /**
   * @inheritDoc
   */
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

  /**
   * @inheritDoc
   */
  public override List<IEntry> getChildren(String childObjectName) {
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }
    // for validate the childObjectName
    String childRelationName = this.getChildrenRelationNameFromChildObjectName(childObjectName);

    String errorTemplate = 'The specified childObjectName is not set in Scribe. object name: {0}, child object name: {1}';
    this.validateChildRelationInFieldStructure(childObjectname, errorTemplate);

    for (String key : this.fieldToValue.keySet()) {
      if (key.equalsIgnoreCase(childObjectName)) {
        errorTemplate = 'The child object needs to be a List<IEntry> or IEntry. object name: {0}, child object name: {1}';
        return this.getchildEntriesFromFieldToValue(key, errorTemplate);
      }
    }

    Entry entry = new Entry(this.record);
    return entry.getChildren(childObjectName);
  }

  /**
   * @inheritDoc
   */
  public override List<IEntry> getChildrenByRelationName(String childRelationName) {
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }

    String errorTemplate = 'The specified childRelationName is not set in Scribe. object name: {0}, child relation name: {1}';
    this.validateChildRelationInFieldStructure(childRelationname, errorTemplate);

    this.validateChildRelationName(childRelationName);

    for (String key : this.fieldToValue.keySet()) {
      if (key.equalsIgnoreCase(childRelationName)) {
        errorTemplate = 'The child object needs to be a List<IEntry> or IEntry. object name: {0}, child object relation name: {1}';
        return this.getchildEntriesFromFieldToValue(key, errorTemplate);
      }
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

  /**
   * @inheritDoc
   */
  public override IEntry setRecord(SObject record) {
    return new MockEntry(record, this.fieldStructure, this.fieldToValue);
  }

  /**
   * @inheritDoc
   */
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

  /**
   * validate the child relation name.
   *
   * @param childRelationName child relation name to be validated
   * @throws QueryException if the child relation name is not valid
   */
  private void validateChildRelationInFieldStructure(String relation, String errorTemplate) {
    if (!this.fieldStructure.hasRelation(relation.toLowerCase())) {
      String error = String.format(errorTemplate, new List<String>{ this.describeResult.getName(), relation });
      throw new QueryException(error);
    }
  }

  /**
   * validate the child relation name.
   *
   * @param childRelationName child relation name to be validated
   * @throws QueryException if the child relation name is not valid
   */
  private List<IEntry> getChildEntriesFromFieldToValue(String key, String errorTemplate) {
    List<IEntry> entries = new List<IEntry>();
    Object childObjects = this.fieldToValue.get(key);
    if (childObjects instanceof List<IEntry>) {
      entries = (List<IEntry>) childObjects;
    } else if (childObjects instanceof IEntry) {
      entries = new List<IEntry>{ (IEntry) childObjects };
    } else {
      String error = String.format(errorTemplate, new List<String>{ this.describeResult.getName(), key });
      throw new QueryException(error);
    }

    List<IEntry> resultEntries = new List<IEntry>();
    FieldStructure childFieldStructure = this.fieldStructure == null
      ? new FieldStructure()
      : this.fieldStructure.getRelationFieldStructure(key.toLowerCase());
    for (IEntry entry : entries) {
      resultEntries.add(entry.setFieldStructure(childFieldStructure));
    }
    return resultEntries;
  }
}
