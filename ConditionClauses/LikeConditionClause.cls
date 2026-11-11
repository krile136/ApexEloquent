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
 * SOQL `LIKE` condition for string pattern matching.
 *
 * This class formats the provided string value with the necessary single quotes.
 * It throws an `ApexEloquentException` if the provided value is null.
 * @see IConditionClause
 * @see AbstractConditionClause
 * @directory ApexEloquent/ConditionClauses
 */
public with sharing class LikeConditionClause extends AbstractConditionClause {
  private static final String CLASS_NAME = 'LikeConditionClause';

  private final Object value;

  /**
   * Set by whereContains / whereStartsWith / whereEndsWith (and their Not forms), whose
   * pattern carries deliberate `\%` `\_` `\\` escapes. Without it the pattern is taken as
   * v3 took it: `%` and `_` are wildcards and `\` is a plain character.
   */
  private Boolean escapesApply = false;

  /**
   * Constructor for LikeConditionClause.
   *
   * @param sObjectType The Schema.SObjectType of the object.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the LIKE condition on.
   * @param value The value to compare against.
   */
  public LikeConditionClause(
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
  private LikeConditionClause(String field, Object value) {
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
  private LikeConditionClause(System.Type recordType, String field, Object value) {
    this(toSObjectType(recordType), null, field, value);
  }

  /**
   * @inheritdoc
   */

  /**
   * @inheritDoc
   */
  public override String clauseKind() {
    // A pattern from whereContains & co. is its own kind: its text can equal a whereLike
    // pattern while it matches other rows (its escapes take effect, whereLike's do not), so
    // Scribe.assertCondition must not let one stand for the other (review r2 N7).
    return this.escapesApply ? 'likeLiteral' : 'like';
  }

  /**
   * The expected condition of a `whereContains(field, value)` call, for Scribe.assertCondition:
   * the field contains `value` taken literally. A whereLike condition with the same text does
   * not match it.
   *
   * @param field The field.
   * @param value The text, taken literally.
   * @return The expected condition.
   */
  @TestVisible
  private static LikeConditionClause contains(String field, String value) {
    return new LikeConditionClause(field, LikeConditionClause.literalPattern('%', value, '%')).withEscapesApplied();
  }

  /**
   * The expected condition of a `whereStartsWith(field, value)` call (see contains).
   *
   * @param field The field.
   * @param value The prefix, taken literally.
   * @return The expected condition.
   */
  @TestVisible
  private static LikeConditionClause startsWith(String field, String value) {
    return new LikeConditionClause(field, LikeConditionClause.literalPattern('', value, '%')).withEscapesApplied();
  }

  /**
   * The expected condition of a `whereEndsWith(field, value)` call (see contains).
   *
   * @param field The field.
   * @param value The suffix, taken literally.
   * @return The expected condition.
   */
  @TestVisible
  private static LikeConditionClause endsWith(String field, String value) {
    return new LikeConditionClause(field, LikeConditionClause.literalPattern('%', value, '')).withEscapesApplied();
  }

  public override String build() {
    return String.format('{0} LIKE {1}', new List<String>{ this.soqlField(), this.checkAndCast() });
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    LikeConditionClause copy = new LikeConditionClause(sObjectType, fieldMap, this.field, this.value);
    copy.escapesApply = this.escapesApply;
    return copy;
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideField(String field) {
    LikeConditionClause copy = new LikeConditionClause(this.sObjectType, this.fieldMap, field, this.value);
    copy.escapesApply = this.escapesApply;
    return copy;
  }

  /**
   * A copy whose pattern keeps its backslash escapes when bound. Internal: not part of the
   * supported API; Scribe's whereContains family is the caller.
   *
   * @return A new clause.
   */
  public LikeConditionClause withEscapesApplied() {
    LikeConditionClause copy = new LikeConditionClause(this.sObjectType, this.fieldMap, this.field, this.value);
    copy.escapesApply = true;
    return copy;
  }

  /**
   * A LIKE pattern that matches `value` literally between the given wildcards: `\`, `%` and
   * `_` in it are escaped, the backslash first so the escapes added for `%` and `_` are not
   * escaped again. Shared by Scribe's whereContains family and the expected conditions above,
   * so the two cannot drift. Internal: not part of the supported API.
   *
   * @param before The wildcard before the value ('' or '%').
   * @param value The text to match literally; null stays null.
   * @param after The wildcard after the value ('' or '%').
   * @return The pattern.
   */
  public static String literalPattern(String before, String value, String after) {
    if (value == null) {
      return null;
    }
    return before + value.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') + after;
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
