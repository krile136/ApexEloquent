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
 * @description An abstract base class that implements the `IEntry` interface.
 * It provides a common foundation and shared logic for concrete implementations
 * like `Entry` (for real SObjects) and `MockEntry` (for test data).
 * This class handles the dual nature of query results, capable of representing both
 * standard `SObject` records and `AggregateResult` records.
 */
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
    this.fieldStructure = new FieldStructure();
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
   * Ensure that describeResult is set.
   */
  protected void ensureDescribeResultIfNeeded() {
    if (this.describeResult == null) {
      Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
      this.setDescribeResult(describeResult);
    }
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
   * @throws ApexEloquentException if the child object name is not exist in the parent object's children relationships
   *                               or if there are multiple relationships with the same child object name
   */
  protected String getChildrenRelationNameFromChildObjectName(String childObjectName) {
    List<Schema.ChildRelationship> childRelationships = this.describeResult.getChildRelationships();
    Integer size = childRelationships.size();

    Integer low = 0;
    Integer high = size - 1;
    Integer foundIndex = -1;

    // 1. 二分探索で一つ目を見つける
    while (low <= high) {
      Integer mid = (low + high) / 2;
      String midName = childRelationships[mid].getChildSObject().getDescribe().getName();
      Integer res = childObjectName.compareTo(midName);

      if (res == 0) {
        foundIndex = mid;
        break;
      } else if (res > 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (foundIndex == -1) {
      throw new ApexEloquentException(
        String.format(
          'The specified child object name `{0}` does not exist on Parent: {1}',
          new List<String>{ childObjectName, this.describeResult.getName() }
        )
      );
    }

    // 2. 曖昧性（Ambiguous）のチェック：見つかった場所の前後だけを確認
    // Salesforceのリストはソート済みなので、同じ名前は必ず隣接している
    Schema.ChildRelationship targetRelation = childRelationships[foundIndex];

    Boolean isAmbiguous = false;
    // 前を確認
    if (
      foundIndex > 0 &&
      childRelationships[foundIndex - 1].getChildSObject().getDescribe().getName() == childObjectName
    ) {
      isAmbiguous = true;
    }
    // 後を確認
    if (
      !isAmbiguous &&
      foundIndex < size - 1 &&
      childRelationships[foundIndex + 1].getChildSObject().getDescribe().getName() == childObjectName
    ) {
      isAmbiguous = true;
    }

    if (isAmbiguous) {
      throw new ApexEloquentException(
        String.format(
          'The specified child object name `{0}` is ambiguous because multiple relationships exist on Parent: {1}',
          new List<String>{ childObjectName, this.describeResult.getName() }
        )
      );
    }

    return targetRelation.getRelationshipName();
  }

  /**
   * validate the child relation name.
   *
   * @param childRelationName child relation name to be validated
   * @throws ApexEloquentException if the child relation name is not exist in the parent object's children relationships
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
        'The specified childRelationName does not exist in the parent object\'s children relationships. parent object name: {0}',
        new List<String>{ this.describeResult.getName() }
      );
      throw new ApexEloquentException(error);
    }
  }

  // abstract methods to be implemented by subclasses
  public abstract Object get(String fieldName);
  public abstract void put(String fieldName, Object value);
  public abstract IEntry getParent(String parentFieldName);
  public abstract List<IEntry> getChildren(String childObjectName);
  public abstract List<IEntry> getChildrenByRelationName(String childRelationName);
  public abstract SObject getRecord();
  public abstract IEntry setRecord(SObject record);
  public abstract Id getId();
  public abstract String getName();
  public abstract IEntry withoutFieldValidation();
  public abstract IEntry setFieldStructure(FieldStructure fieldStructure);
}
