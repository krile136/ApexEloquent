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
 * @description An interface for classes that build a single condition part of a SOQL WHERE or HAVING clause.
 *
 * Implementations of this interface are responsible for generating a specific logical
 * condition string (e.g., "Name = 'Test Corp'" or "Amount > 1000"). This allows the
 * Scribe builder to handle various condition types in a polymorphic way.
 * @see AbstractConditionClause
 * @see Scribe
 */
 public interface IConditionClause {
  /**
   * Builds the condition clause string.
   *
   * @return The constructed condition clause part.
   */
  String build();

  /**
   * Overrides the internal metadata for the clause.
   *
   * @param sObjectType The SObjectType to use for context.
   * @param fieldMap The field map of the relevant SObject for schema validation.
   * @return A new IConditionClause instance with the updated metadata.
   */
  IConditionClause overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap);

  /**
   * Overrides the field name for this condition.
   *
   * @param field The new field name to use.
   * @return A new IConditionClause instance with the updated field name.
   */
  IConditionClause overrideField(String field);

  /**
   * Gets the field name or alias used in this condition.
   *
   * @return The field name or alias.
   */
  String getFieldName();
}
