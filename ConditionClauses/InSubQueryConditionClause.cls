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
 * SOQL `IN` condition with a subquery.
 *
 * This class demonstrates the composability of the framework, as it takes another
 * `Scribe` instance as its "value". The `build()` method recursively calls `toSoql()`
 * on the provided subquery Scribe to generate the final clause.
 * @see IConditionClause
 * @see AbstractConditionClause
 * @see Scribe
 */
public with sharing class InSubQueryConditionClause extends AbstractConditionClause {
  private final Scribe subQueryScribe;

  /**
   * Constructor for InSubQueryConditionClause.
   *
   * @param sObjectType The SObject type for the main query.
   * @param fieldMap A map of field names to Schema.SObjectField for the main query.
   * @param field The field name in the main query to apply the in subQuery condition on.
   * @param subQueryScribe The Scribe instance representing the subquery.
   */
  public InSubQueryConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Scribe subQueryScribe
  ) {
    super(sObjectType, fieldMap, field);
    this.subQueryScribe = subQueryScribe;
  }

  /**
   * Test-only constructor for building an expected condition on the object being
   * queried. Pair it with `Scribe.assertCondition` / `assertNoCondition`.
   *
   * @param field The field name the condition applies to.
   * @param subQueryScribe The expected subQueryScribe.
   */
  @TestVisible
  private InSubQueryConditionClause(String field, Scribe subQueryScribe) {
    this(null, null, field, subQueryScribe);
  }

  /**
   * Test-only constructor for building an expected condition on a specific object.
   * Use this to name a condition that lives on a parent (`parentCondition`) or on a
   * child subquery (`withChildren`); the two-argument form targets the queried object.
   *
   * @param recordType The SObject class the condition applies to (e.g. Account.class).
   * @param field The field name the condition applies to.
   * @param subQueryScribe The expected subQueryScribe.
   */
  @TestVisible
  private InSubQueryConditionClause(System.Type recordType, String field, Scribe subQueryScribe) {
    this(toSObjectType(recordType), null, field, subQueryScribe);
  }

  /**
   * @inheritDoc
   */


  /**
   * Returns the subquery this condition wraps, so `Scribe.assertCondition` can search the
   * conditions inside a semi-join. Without it the subquery is a leaf and its conditions are
   * invisible to the assertion, which would let `assertNoCondition` pass on a filter that is
   * in fact present.
   *
   * @return The subquery Scribe.
   */
  public Scribe getSubQueryScribe() {
    return this.subQueryScribe;
  }

  /**
   * @inheritDoc
   */
  public override String clauseKind() {
    return 'inSubQuery';
  }

  public override String build() {
    return String.format('{0} IN ({1})', new List<String>{ this.field, this.subQueryScribe.toSoql() });
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new InSubQueryConditionClause(sObjectType, fieldMap, this.field, this.subQueryScribe);
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideField(String field) {
    return new InSubQueryConditionClause(this.sObjectType, this.fieldMap, field, this.subQueryScribe);
  }

  /**
   * check the value type and cast it to string for SOQL
   *
   * @return The value formatted as a SOQL-compatible string.
   */
  private String checkAndCast() {
    return '';
  }
}
