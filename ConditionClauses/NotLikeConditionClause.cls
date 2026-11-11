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
 * SOQL `NOT LIKE` condition for string pattern matching.
 *
 * This class formats the provided string value with the necessary single quotes and
 * wraps the entire expression in parentheses (e.g., `(NOT Name LIKE '%Test%')`).
 * It throws an `ApexEloquentException` if the provided value is null.
 * @see IConditionClause
 * @see AbstractConditionClause
 * @directory ApexEloquent/ConditionClauses
 */
public with sharing class NotLikeConditionClause extends AbstractConditionClause {
  private static final String CLASS_NAME = 'NotLikeConditionClause';

  private final Object value;

  /**
   * Set by whereContains / whereStartsWith / whereEndsWith (and their Not forms), whose
   * pattern carries deliberate `\%` `\_` `\\` escapes. Without it the pattern is taken as
   * v3 took it: `%` and `_` are wildcards and `\` is a plain character.
   */
  private Boolean escapesApply = false;

  /**
   * Constructor for NotLikeConditionClause.
   *
   * @param sObjectType The Schema.SObjectType of the object.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the NotLIKE condition on.
   * @param value The value to compare against.
   */
  public NotLikeConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    Object value
  ) {
    super(sObjectType, fieldMap, field);
    this.value = value;
  }

  /**
   * Test-only constructor for building an expected condition on the object being
   * queried. Pair it with `Scribe.assertCondition` / `assertNoCondition`.
   *
   * @param field The field name the condition applies to.
   * @param value The expected value.
   */
  @TestVisible
  private NotLikeConditionClause(String field, Object value) {
    this(null, null, field, value);
  }

  /**
   * Test-only constructor for building an expected condition on a specific object.
   * Use this to name a condition that lives on a parent (`parentCondition`) or on a
   * child subquery (`withChildren`); the two-argument form targets the queried object.
   *
   * @param recordType The SObject class the condition applies to (e.g. Account.class).
   * @param field The field name the condition applies to.
   * @param value The expected value.
   */
  @TestVisible
  private NotLikeConditionClause(System.Type recordType, String field, Object value) {
    this(toSObjectType(recordType), null, field, value);
  }

  /**
   * @inheritDoc
   */

  /**
   * @inheritDoc
   */
  public override String clauseKind() {
    return 'notLike';
  }

  public override String build() {
    return String.format('(NOT {0} LIKE {1})', new List<String>{ this.soqlField(), this.checkAndCast() });
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    NotLikeConditionClause copy = new NotLikeConditionClause(sObjectType, fieldMap, this.field, this.value);
    copy.escapesApply = this.escapesApply;
    return copy;
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideField(String field) {
    NotLikeConditionClause copy = new NotLikeConditionClause(this.sObjectType, this.fieldMap, field, this.value);
    copy.escapesApply = this.escapesApply;
    return copy;
  }

  /**
   * A copy whose pattern keeps its backslash escapes when bound. Internal: not part of the
   * supported API; Scribe's whereContains family is the caller.
   *
   * @return A new clause.
   */
  public NotLikeConditionClause withEscapesApplied() {
    NotLikeConditionClause copy = new NotLikeConditionClause(this.sObjectType, this.fieldMap, this.field, this.value);
    copy.escapesApply = true;
    return copy;
  }

  /**
   * Doubles the backslashes of a bound pattern unless the escapes are deliberate, so a
   * whereLike value means what it meant in v3 (measured: bound `%abc\%` matches nothing
   * where the v3 literal matched `abc\x`; doubled, the bind matches `abc\x` again).
   *
   * @param text The pattern.
   * @return The value to bind.
   */
  protected override String textBindValue(String text) {
    return this.escapesApply ? text : text.replace('\\', '\\\\');
  }

  /**
   * check the value type and cast it to string for SOQL
   *
   * @return The value formatted as a SOQL-compatible string.
   */
  private String checkAndCast() {
    if (value == null) {
      ApexEloquentException.required(CLASS_NAME, null, 'value', this.value)
        .param('field', this.field)
        .fire();
    }

    Schema.DisplayType fieldType = this.getFieldType(field);
    return this.toSoqlLiteral(fieldType, value);
  }
}
