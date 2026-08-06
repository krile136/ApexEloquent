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
 * @description A placeholder condition recorded when a where...() method received a
 * null value at chain time (issue #71).
 *
 * Throwing immediately in the where...() call would make the condition impossible
 * to retract: `whereIn(f, ids).ignoreWhen(ids == null)` never reaches ignoreWhen().
 * Instead the invalid condition is recorded like any other ConditionPart — if
 * ignoreWhen() retracts it, nothing happens; if it survives to SOQL build time,
 * build() fires the original required-argument error, carrying the originating
 * method and field name so the offending where...() call is identifiable.
 * @see Scribe
 * @see IConditionClause
 */
public with sharing class InvalidConditionClause implements IConditionClause {
  private static final String CLASS_NAME = 'Scribe';

  private final String method;
  private final String field;

  /**
   * @param method the Scribe method that received the null value (for the deferred error)
   * @param field the field name the condition was for
   */
  public InvalidConditionClause(String method, String field) {
    this.method = method;
    this.field = field;
  }

  /**
   * Fires the deferred required-argument error: the null-valued condition survived
   * to SOQL build time without being retracted by ignoreWhen().
   */
  public String build() {
    ApexEloquentException.required(CLASS_NAME, this.method, 'value', null)
      .param('fieldName', this.field)
      .action(
        'Pass a non-null value, or drop the condition by chaining .ignoreWhen(...) directly after the where...() call.'
      )
      .fire();
    return null; // unreachable — fire() always throws
  }

  /**
   * @inheritDoc
   */
  public IConditionClause overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap) {
    return this;
  }

  /**
   * @inheritDoc
   */
  public IConditionClause overrideField(String field) {
    return new InvalidConditionClause(this.method, field);
  }

  /**
   * @inheritDoc
   */
  public String getFieldName() {
    return this.field;
  }
}
