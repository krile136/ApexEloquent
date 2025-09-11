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
 * SOQL "IS NULL" condition (represented as `= NULL`).
 *
 * This class does not require a value and simply generates the condition based on the
 * provided field name.
 * @see IConditionClause
 * @see AbstractConditionClause
 */
public with sharing class IsNullConditionClause extends AbstractConditionClause {
  /**
   * Constructor for IsNullConditionClause.
   *
   * @param sObjectType The SObject type for the condition.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the equality to null condition on.
   */
  public IsNullConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field
  ) {
    super(sObjectType, fieldMap, field);
  }

  /**
   * @inheritdoc
   */
  public override String build() {
    return String.format('{0} = {1}', new List<String>{ this.field, 'NULL' });
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new IsNullConditionClause(sObjectType, fieldMap, this.field);
  }

  /**
   * @inheritdoc
   */

  public override IConditionClause overrideField(String field) {
    return new IsNullConditionClause(this.sObjectType, this.fieldMap, field);
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
