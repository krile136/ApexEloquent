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
 * @description An abstract base class that implements the `IConditionClause` interface.
 *
 * It provides the common properties and shared functionality for all concrete condition
 * clause implementations. This includes helper methods for schema validation (e.g., `getFieldType`)
 * and for formatting various Apex data types into SOQL-compatible string literals
 * (e.g., `formatAndCastToString`).
 *
 * Subclasses are responsible for implementing the abstract methods to generate the
 * specific syntax for their respective conditions (e.g., `=`, `LIKE`, `IN`).
 * @see IConditionClause
 * @see Scribe
 * @directory ApexEloquent/ConditionClauses
 */
public with sharing abstract class AbstractConditionClause implements IConditionClause {
  private static final String CLASS_NAME = 'AbstractConditionClause';

  protected final Schema.SObjectType sObjectType;
  protected final Map<String, Schema.SObjectField> fieldMap;
  protected final String field;

  /**
   * A list of Schema.DisplayType values that require single quotes in a SOQL literal.
   */
  protected final List<Schema.DisplayType> TYPES_REQUIRING_SINGLE_QUOTES = new List<Schema.DisplayType>{
    DisplayType.STRING,
    DisplayType.TEXTAREA,
    DisplayType.PICKLIST,
    DisplayType.MULTIPICKLIST,
    DisplayType.ID,
    DisplayType.REFERENCE,
    DisplayType.URL,
    DisplayType.EMAIL,
    DisplayType.PHONE,
    DisplayType.ENCRYPTEDSTRING,
    DisplayType.ANYTYPE
  };

  /**
   * Constructor for the abstract clause.
   *
   * @param sObjectType The SObject type context.
   * @param fieldMap The field map for schema validation.
   * @param field The API name of the field for the condition.
   */
  public AbstractConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field
  ) {
    this.sObjectType = sObjectType;
    this.fieldMap = fieldMap;
    this.field = field;
  }

  // Abstract methods to be implemented by subclasses.
  public abstract IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  );
  public abstract IConditionClause overrideField(String field);
  private abstract String checkAndCast();
  public abstract String build();

  /**
   * @inheritDoc
   */
  public String getFieldName() {
    return this.field;
  }

  /**
   * A stable identity for the kind of condition this is ('equal', 'in', 'isNull', ...).
   *
   * Comparing conditions by their generated SOQL alone is not enough, because degenerate
   * inputs render indistinguishably: an empty `IN` builds `Id = null` and `IS NULL` builds
   * `Id = NULL`, which Apex's case-insensitive String equality treats as the same text,
   * while an empty `NOT IN` builds an empty string. Keying on the kind as well keeps
   * `Scribe.assertCondition` from matching one condition against a different one.
   *
   * @return The kind of this condition.
   */
  public virtual String clauseKind() {
    return 'unknown';
  }

  /**
   * Returns the SObject type this condition applies to, or null when the clause was
   * built without one. Scribe reads this when matching an expected condition against
   * a recorded query: a clause carrying a type is matched against nested scribes for
   * that object (a parent condition or a child subquery), and one carrying null is
   * matched against the queried object itself.
   *
   * @return the SObject type of this condition, or null when unspecified
   */
  public Schema.SObjectType getSObjectType() {
    return this.sObjectType;
  }

  /**
   * Gets the Schema.DisplayType of the specified field.
   *
   * @param field The API name of the field.
   * @return The field's display type.
   */
  protected Schema.DisplayType getFieldType(String field) {
    if (this.sObjectType == null) {
      ApexEloquentException.invalidOperation(CLASS_NAME, null, 'source SObjectType is not set').fire();
    }
    if (!this.fieldMap.containsKey(field)) {
      // If the field doesn't exist in the describe map, default to String.
      // This handles special polymorphic fields like 'Queue.Name',
      // which are valid in SOQL but may not appear in the initial describe result.
      return Schema.DisplayType.STRING;
    }
    Schema.DisplayType fieldType = this.fieldMap.get(field).getDescribe().getType();
    return fieldType;
  }

  /**
   * Formats a given value into a SOQL literal string based on its data type.
   * Handles special formatting for Date and Datetime values.
   *
   * @param value The value to format.
   * @return A string representation of the value suitable for a SOQL query.
   */
  protected String formatAndCastToString(Object value) {
    if (value instanceof Date) {
      Date dateValue = (Date) value;
      return dateValue.year() +
        '-' +
        String.valueOf(dateValue.month()).leftPad(2, '0') +
        '-' +
        String.valueOf(dateValue.day()).leftPad(2, '0');
    }
    if (value instanceof Datetime) {
      Datetime datetimeValue = (Datetime) value;
      return dateTimeValue.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }
    return String.escapeSingleQuotes(String.valueOf(value));
  }

  /**
   * Resolves an SObject class (e.g. `Account.class`) to its Schema.SObjectType, so the
   * test-only constructors can take the same `Account.class` form as `Scribe.of(...)`.
   *
   * @param recordType The SObject class.
   * @return The matching Schema.SObjectType.
   * @throws ApexEloquentException when recordType is null, or is a class that instantiates
   *         but is not an SObject.
   * @throws System.TypeException when recordType cannot be instantiated at all — an
   *         interface or an abstract class fails inside newInstance() before this method
   *         can judge it (measured on API v67.0).
   */
  public static Schema.SObjectType toSObjectType(System.Type recordType) {
    String method = 'toSObjectType(System.Type recordType)';
    if (recordType == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'recordType', recordType).fire();
    }
    Object instance = recordType.newInstance();
    if (!(instance instanceof SObject)) {
      String reason = '`recordType` is not an SObject type.';
      String action = 'Pass a valid SObject class (e.g., Account.class, MyObject__c.class)';
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'recordType', recordType).fire();
    }
    return ((SObject) instance).getSObjectType();
  }

  /**
   * Normalize a `List` or `Set` of primitive values into a `List<Object>`.
   *
   * Accepts:
   *   - `List<X>` for any X — returned as-is via Apex's primitive-list covariance
   *   - `Set<X>` where X is one of:
   *     Id, String, Integer, Long, Decimal, Double, Boolean, Date, Datetime, Time
   *
   * Used by `InConditionClause` / `NotInConditionClause` to accept both List- and Set-
   * shaped inputs without forcing the caller to cast to `Set<Id>` or pre-convert to a List.
   *
   * A Set has no order, so its values are sorted to give the generated IN clause a
   * canonical form: the same set of values always produces the same SOQL. Measured on
   * API v67.0, Apex Sets iterate in INSERTION order, so two sets holding the same
   * values built in different orders would otherwise produce different SOQL — which
   * also makes `Scribe.assertCondition` unable to match them. A List keeps its order:
   * the caller chose it.
   *
   * @param values A List or Set of primitive values.
   * @return The values as a `List<Object>`.
   * @throws ApexEloquentException when `values` is neither a List nor a supported Set type.
   */
  public static List<Object> toListObject(Object values) {
    if (values instanceof List<Object>) return (List<Object>) values;
    if (values instanceof Set<Id>) {
      List<Id> sorted = new List<Id>((Set<Id>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<String>) {
      List<String> sorted = new List<String>((Set<String>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<Integer>) {
      List<Integer> sorted = new List<Integer>((Set<Integer>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<Long>) {
      List<Long> sorted = new List<Long>((Set<Long>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<Decimal>) {
      List<Decimal> sorted = new List<Decimal>((Set<Decimal>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<Double>) {
      List<Double> sorted = new List<Double>((Set<Double>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<Boolean>) {
      List<Boolean> sorted = new List<Boolean>((Set<Boolean>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<Date>) {
      List<Date> sorted = new List<Date>((Set<Date>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<Datetime>) {
      List<Datetime> sorted = new List<Datetime>((Set<Datetime>) values);
      sorted.sort();
      return sorted;
    }
    if (values instanceof Set<Time>) {
      List<Time> sorted = new List<Time>((Set<Time>) values);
      sorted.sort();
      return sorted;
    }

    String reason = 'values must be a List or a Set of a primitive type (Id, String, Integer, Long, Decimal, Double, Boolean, Date, Datetime, Time)';
    String action = 'Pass a List<X> or Set<X> where X is one of the supported primitive types';
    ApexEloquentException.invalidArgument(CLASS_NAME, null, reason, action, 'values', values).fire();
    return null; // unreachable
  }
}
