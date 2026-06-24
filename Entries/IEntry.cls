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
 * @description Defines the contract for a unified record wrapper, which represents a single result from an `ApexEloquent` query.
 *
 * This interface is the cornerstone of the framework's testability. It abstracts the
 * underlying data source, allowing developers to interact seamlessly with either a real `SObject`
 * record returned from the database (via the `Entry` class) or a mocked in-memory record
 * (via the `MockEntry` class).
 *
 * It provides methods to access field values and to navigate eager-loaded parent, child,
 * and many-to-many (`through`) relationships.
 */
public interface IEntry {
  /**
   * get SObject field value.
   *
   * @param fieldName field name
   * @return field value
   */
  Object get(String fieldName);

  /**
   * set SObject field value.
   *
   * @param fieldName field name
   * @param value field value
   */
  void put(String fieldName, Object value);

  /**
   * get parent SObject as Evaluator.
   *
   * @param parentFieldName parent relationId field name
   * @return parent SObject as Entry
   */
  IEntry getParent(String parentIdFieldName);

  /**
   * Returns the list of child IEntry records for the given name.
   *
   * Name resolution:
   *  1. First, treats `name` as a **child SObject name** (e.g., `Contact`, `Custom__c`).
   *  2. If that fails, falls back to treating `name` as a **child relationship name**
   *     (e.g., `Contacts`, `Custom__r`). This means callers can pass either form
   *     without choosing a different method.
   *  3. If neither resolves, `ApexEloquentException` is thrown.
   *
   * @param name Either a child SObject name or a child relationship name.
   * @return The list of child IEntry records. Empty list when no children exist.
   * @throws ApexEloquentException when `name` is null/blank, or when it matches
   *         neither a child SObject name nor a child relationship name on the
   *         parent. Also thrown for ambiguous SObject names (multiple
   *         relationships with the same SObject); in that case, pass the
   *         relationship name instead.
   */
  List<IEntry> getChildren(String name);

  /**
   * @deprecated
   * Use {@link #getChildren(String)} instead. `getChildren` now accepts both
   * child SObject names and child relationship names (with object-name
   * resolution attempted first, then falling back to relationship-name).
   * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * Get child SObject list by relationship name.
   *
   * @param childRelationName child relation name
   * @return child SObject list
   */
  List<IEntry> getChildrenByRelationName(String childRelationName);

  /**
   * Get related SObject list through a junction object.
   *
   * The junction is resolved by {@link #getChildren(String)}, so the first argument
   * accepts BOTH a junction SObject name AND a junction relationship name (object-name
   * resolution is attempted first, then falling back to relationship-name).
   *
   * @param junctionName junction SObject name or junction relationship name
   * @param relatedKey related SObject key field name in the junction object
   * @return related SObject list
   */
  List<IEntry> getThrough(String junctionName, String relatedKey);

  /**
   * @deprecated
   * Use {@link #getThrough(String, String)} instead. `getThrough` now accepts both
   * junction SObject names and junction relationship names, so a dedicated
   * relation-name-only entry point is no longer necessary.
   * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * Get related SObject list through a junction object relation name.
   *
   * @param junctionRelationName junction object relation Name
   * @param relatedKey related SObject key field name in the junction object
   * @return related SObject list
   */
  List<IEntry> getThroughByRelationName(String junctionRelationName, String relatedKey);

  /**
   * get Id
   *
   * @return Id
   */
  Id getId();

  /**
   * get Name
   *
   * @return Name
   */
  String getName();

  /**
   * get SObject
   *
   * @return SObject
   */
  SObject getRecord();

  /**
   * set Evaluatot SObject property
   *
   * @param record SObject
   * @return EvaluatorInterface
   */
  IEntry setRecord(SObject record);

  /**
   * set picked fields and relation fields.
   *
   * @param FieldStructure fieldStructure
   * @return EvaluatorInterface
   */
  IEntry setFieldStructure(FieldStructure fieldStructure);

  /**
   * set DescribeSObjectResult for relation query
   *
   * @param describeResult Schema.DescribeSObjectResult
   */
  void setDescribeResult(Schema.DescribeSObjectResult describeResult);
}
