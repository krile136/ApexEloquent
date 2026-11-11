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
 * @description A concrete implementation of `AbstractConditionClause` that builds a
 * SOQL `NOT IN` condition.
 *
 * This class handles both `List<X>` and `Set<X>` collections where X is any Apex
 * primitive type (Id, String, Integer, Long, Decimal, Double, Boolean, Date, Datetime,
 * Time), formatting each value into a comma-separated list suitable for the `NOT IN`
 * clause. It correctly handles null values within the collection by converting them to
 * the `NULL` literal.
 *
 * An empty list is always true (no value is "in" it), so instead of causing a SOQL error
 * it renders the always-true `Id != null`, mirroring the always-false `Id = null` of an
 * empty `IN` — the same choice as Laravel (`1 = 1` / `0 = 1`). Before v4 it rendered
 * nothing and dropped out, which was harmless under AND but turned `A OR true` (every
 * row) into `A` under OR, narrowing the result without any sign (issue #117).
 * @see IConditionClause
 * @see AbstractConditionClause
 * @directory ApexEloquent/ConditionClauses
 */
public with sharing class NotInConditionClause extends AbstractConditionClause {
  private final List<Object> values;

  /**
   * Constructor for NotInConditionClause.
   *
   * @param sObjectType The SObject type for the condition.
   * @param fieldMap A map of field names to SObjectField tokens.
   * @param field The field name to apply the NotIN condition on.
   * @param values A list or set of values for the NotIN condition.
   */
  public NotInConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Object values
  ) {
    super(sObjectType, fieldMap, field);
    this.values = toListObject(values);
  }

  /**
   * Test-only constructor for building an expected condition on the object being
   * queried. Pair it with `Scribe.assertCondition` / `assertNoCondition`.
   *
   * @param field The field name the condition applies to.
   * @param values The expected values.
   */
  @TestVisible
  private NotInConditionClause(String field, Object values) {
    this(null, null, field, values);
  }

  /**
   * Test-only constructor for building an expected condition on a specific object.
   * Use this to name a condition that lives on a parent (`parentCondition`) or on a
   * child subquery (`withChildren`); the two-argument form targets the queried object.
   *
   * @param recordType The SObject class the condition applies to (e.g. Account.class).
   * @param field The field name the condition applies to.
   * @param values The expected values.
   */
  @TestVisible
  private NotInConditionClause(System.Type recordType, String field, Object values) {
    this(toSObjectType(recordType), null, field, values);
  }

  /**
   * @inheritdoc
   */

  /**
   * @inheritDoc
   */
  public override String clauseKind() {
    return 'notIn';
  }

  /**
   * Whether the list is empty, so the clause matches every row. For Scribe's HAVING clause,
   * which cannot use the `Id != null` that build() writes for this case. Internal: not part
   * of the supported API.
   *
   * @return true when no value was given.
   */
  public Boolean hasNoValues() {
    return this.values.isEmpty();
  }

  public override String build() {
    if (this.values.isEmpty()) {
      // Matches every row. Like the empty IN, it names the queried object's own Id, never
      // the rendered field: under a parent condition `Account.Id != null` would drop the
      // children that have no parent. Measured: `... OR Id != null` returns every row at
      // the root, in a child subquery and inside a semi-join.
      return 'Id != null';
    }
    return String.format('{0} NOT IN ({1})', new List<String>{ this.soqlField(), this.checkAndCast() });
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new NotInConditionClause(sObjectType, fieldMap, this.field, this.values);
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideField(String field) {
    return new NotInConditionClause(this.sObjectType, this.fieldMap, field, this.values);
  }

  /**
   * check the value type and cast it to string for SOQL
   *
   * @return The value formatted as a SOQL-compatible string.
   */
  private String checkAndCast() {
    Schema.DisplayType fieldType = this.getFieldType(field);
    List<String> castedValues = new List<String>();
    for (Object value : this.values) {
      if (value == null) {
        castedValues.add('NULL');
        continue;
      }
      castedValues.add(this.toSoqlLiteral(fieldType, value));
    }

    return String.join(castedValues, ', ');
  }
}
