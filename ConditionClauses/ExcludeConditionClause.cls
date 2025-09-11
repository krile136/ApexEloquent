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
 * SOQL `EXCLUDES` condition.
 *
 * This clause is specifically designed for filtering on multi-select picklist fields.
 * It formats a list of string values into the required `('value1', 'value2')` syntax.
 * @see IConditionClause
 * @see AbstractConditionClause
 */
public with sharing class ExcludeConditionClause extends AbstractConditionClause {
  private final List<String> values;

  /**
   * Constructor for ExcludeConditionClause.
   *
   * @param sObjectType The SObject type for the condition.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the EXCLUDES condition on.
   * @param values A list of values to exclude.
   */
  public ExcludeConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    List<String> values
  ) {
    super(sObjectType, fieldMap, field);
    this.values = values;
  }

  /**
   * @inheritdoc
   */
  public override String build() {
    return String.format('{0} EXCLUDES ({1})', new List<String>{ this.field, this.checkAndCast() });
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new ExcludeConditionClause(sObjectType, fieldMap, this.field, this.values);
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideField(String field) {
    return new ExcludeConditionClause(this.sObjectType, this.fieldMap, field, this.values);
  }

  /**
   * check the value type and cast it to string for SOQL
   *
   * @return The value formatted as a SOQL-compatible string.
   */
  private String checkAndCast() {
    List<String> castedValues = new List<String>();
    for (Object value : this.values) {
      castedValues.add('\'' + value + '\'');
    }

    return String.join(castedValues, ', ');
  }
}
