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
 * It throws a `QueryException` if the provided value is null.
 * @see IConditionClause
 * @see AbstractConditionClause
 */
public with sharing class NotLikeConditionClause extends AbstractConditionClause {
  private final Object value;

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
   * @inheritDoc
   */
  public override String build() {
    return String.format('(NOT {0} LIKE {1})', new List<String>{ this.field, this.checkAndCast() });
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new NotLikeConditionClause(sObjectType, fieldMap, this.field, this.value);
  }

  /**
   * @inheritDoc
   */
  public override IConditionClause overrideField(String field) {
    return new NotLikeConditionClause(this.sObjectType, this.fieldMap, field, this.value);
  }

  /**
   * check the value type and cast it to string for SOQL
   *
   * @return The value formatted as a SOQL-compatible string.
   */
  private String checkAndCast() {
    if (value == null) {
      throw new QueryException('Value cannot be null for NOT LIKE condition. field: ' + field);
    }

    Schema.DisplayType fieldType = this.getFieldType(field);
    String valueString = this.formatAndCastToString(value);
    if (this.TYPES_REQUIRING_SINGLE_QUOTES.contains(fieldType)) {
      return '\'' + valueString + '\'';
    }

    return valueString;
  }
}
