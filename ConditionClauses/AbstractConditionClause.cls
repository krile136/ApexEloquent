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
    DisplayType.COMBOBOX,
    DisplayType.ID,
    DisplayType.REFERENCE,
    DisplayType.URL,
    DisplayType.EMAIL,
    DisplayType.PHONE,
    DisplayType.ENCRYPTEDSTRING,
    DisplayType.ANYTYPE
  };

  /**
   * The largest whole number SOQL reads without a decimal point (the Integer maximum).
   * See toSoqlNumber.
   */
  private static final Long MAX_SOQL_INTEGER = 2147483647L;

  /**
   * The shape an unquoted value is allowed to take: a single token with no whitespace,
   * quotes, parentheses, commas or operators, and not starting with `:`. Numbers (`-1.5`),
   * booleans, `null`, dates, datetimes (`2026-01-01T00:00:00Z`), times and date literals
   * (`LAST_N_DAYS:30`) all fit.
   *
   * A leading `:` is refused because SOQL reads `:name` as a bind reference to a local
   * variable of the method that runs Database.query — measured on API v67.0, `:label`
   * resolved to a variable inside Eloquent. Date literals need a `:` in the middle; the
   * other mid-token forms measured (`0:n`, `n:n`, `LAST_N_DAYS::n`, `TODAY:n`) were all
   * parse errors, not binds.
   *
   * The token may also have the shape of a field name (`AnnualRevenue`). SOQL does not
   * compare a field with a field, and both forms measured were parse errors.
   */
  private static final Pattern UNQUOTED_LITERAL = Pattern.compile('[A-Za-z0-9_.+\\-][A-Za-z0-9_:.+\\-]*');

  /**
   * When set, getFieldType reports a number whatever the field type is. See
   * asNumericOperand.
   */
  private Boolean numericOperand = false;

  /**
   * How the field is written in the SOQL, when that differs from its name: `Account.Name`
   * for a parent condition, `MIN(Name)` for HAVING. Null means the name itself. See
   * renderFieldAs.
   */
  private String renderedField;

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

  /**
   * Returns a new clause for another field. Like overrideMetaData, it does not keep what
   * asNumericOperand and renderFieldAs set, so call it before them (see copyWithSettings).
   *
   * @param field The field the new clause filters.
   * @return A new clause.
   */
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
   * @return The field's display type, or DOUBLE for a copy made by asNumericOperand
   *         (a HAVING operand compared with COUNT / SUM / AVG of that field).
   */
  protected Schema.DisplayType getFieldType(String field) {
    if (this.numericOperand) {
      return Schema.DisplayType.DOUBLE;
    }
    if (this.sObjectType == null) {
      ApexEloquentException.invalidOperation(CLASS_NAME, null, 'source SObjectType is not set').fire();
    }
    if (!this.fieldMap.containsKey(field)) {
      // Unreachable from a query: Scribe.buildWhereClause refuses a field the object does
      // not have before any clause is rendered. Kept as a floor rather than an exception
      // because a clause can also be built by hand for Scribe's condition assertions, where
      // the caller is told about the unknown field by a message that names the object.
      //
      // 🚨 Do not treat this as support for dotted names. It once rendered
      // `Account.NumberOfEmployees > '100'` — a quoted literal against a numeric field,
      // which the platform rejects. Scribe has no dotted field syntax; parents are reached
      // with Scribe.asParent(...).
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
   * Refuses a value that cannot be written as one unquoted SOQL token.
   *
   * @param fieldType The type the value is rendered for.
   * @param value The value refused.
   * @throws ApexEloquentException always.
   */
  private void fireNotASingleLiteral(Schema.DisplayType fieldType, Object value) {
    String reason = this.numericOperand
      ? String.format(
          'The HAVING value compared with an aggregate of `{0}` is not a single SOQL literal and would be inserted into the query as syntax.',
          new List<String>{ this.field }
        )
      : String.format(
          'The value for `{0}` ({1}) is not a single SOQL literal and would be inserted into the query as syntax.',
          new List<String>{ this.field, String.valueOf(fieldType) }
        );
    String action = this.numericOperand
      ? 'Pass a number (Integer, Decimal) for an aggregate result'
      : 'Pass a value of the field\'s own type (Integer, Decimal, Boolean, Date, Datetime) instead of a String';
    ApexEloquentException.invalidArgument(CLASS_NAME, null, reason, action, 'value', value)
      .param('field', this.field)
      .fire();
  }

  /**
   * Writes a number the way SOQL reads it (issue #107). Two forms that String.valueOf
   * produces fail at run time (measured on API v64.0):
   *
   * - Exponent notation. Apex writes a Double of 1E7 or more, a Double below 1E-3 and a
   *   Decimal built from exponent notation that way (`1.2345678E7`, `1.5E-7`, `1E+10`).
   *   SOQL has no exponent literal.
   * - A whole number outside the Integer range without a decimal point
   *   (`AnnualRevenue > 10000000000`, also `-2147483648`) fails with `For input string`.
   *   The same number with `.0` runs. A Long has always rendered without the decimal
   *   point, so it failed the same way.
   *
   * Integer, Long and Double are all instances of Decimal in Apex, and the cast keeps the
   * value (measured). Between -2147483647 and 2147483647 nothing is added, because an
   * Integer field and COUNT() refuse a decimal point. Outside it they refuse the value
   * either way.
   *
   * A Double that is infinite or NaN cannot become a Decimal (`MathException`, measured
   * for Infinity). It is refused here with the same message as any other value that is not
   * a single SOQL literal; String.valueOf used to let `Infinity` into the query, which then
   * failed at run time.
   *
   * Quoted values do not come here: a number compared with a text field keeps
   * String.valueOf, which is what it has always matched.
   *
   * @param fieldType The type the value is rendered for (for the message when refused).
   * @param value The number to write (an Integer, Long, Double or Decimal).
   * @return A SOQL numeric literal.
   */
  private String toSoqlNumber(Schema.DisplayType fieldType, Object value) {
    Decimal numeric;
    try {
      numeric = (Decimal) value;
    } catch (MathException e) {
      this.fireNotASingleLiteral(fieldType, value);
    }
    String plain = numeric.toPlainString();
    if (!plain.contains('.') && numeric.abs() > MAX_SOQL_INTEGER) {
      plain += '.0';
    }
    return plain;
  }

  /**
   * Renders one non-null value as a SOQL literal for a field of the given type.
   *
   * A text-like field gets a quoted, escaped literal. Any other field gets the value
   * unquoted — and there `escapeSingleQuotes` protects nothing, because there is no
   * quote to break out of: a String such as `'0 OR Id != null'` handed to a numeric
   * field used to land in the WHERE clause as SOQL. The unquoted form is therefore
   * refused unless it is a single literal token (see UNQUOTED_LITERAL).
   *
   * The check stops a value from adding syntax; it does not stop a String from choosing
   * a different, valid operand. `'null'` or `'LAST_N_DAYS:99999'` still pass, so callers
   * comparing user input against a non-text field should convert it to the field's type.
   *
   * Converting every value to the field's type (Decimal, Boolean, Date) was rejected: it
   * would also reject date literals such as `LAST_N_DAYS:30`, which callers pass as
   * Strings today. Recognising date literals by pattern and converting everything else
   * was also considered; it would still break other Strings that SOQL accepts today,
   * because Datetime.valueOf takes only `yyyy-MM-dd HH:mm:ss`: ISO datetimes
   * (`2026-01-01T00:00:00Z`, with or without an offset), times and `'null'`.
   *
   * @param fieldType The display type of the field the value is compared against.
   * @param value The value to render. Callers handle null before calling this.
   * @return The SOQL literal.
   * @throws ApexEloquentException when the value would render as more than one token.
   */
  protected String toSoqlLiteral(Schema.DisplayType fieldType, Object value) {
    if (this.TYPES_REQUIRING_SINGLE_QUOTES.contains(fieldType)) {
      return '\'' + this.formatAndCastToString(value) + '\'';
    }
    String valueString = value instanceof Decimal ? this.toSoqlNumber(fieldType, value) : this.formatAndCastToString(value);
    if (valueString.length() > Scribe.MAX_TOKEN_LENGTH || !UNQUOTED_LITERAL.matcher(valueString).matches()) {
      this.fireNotASingleLiteral(fieldType, value);
    }
    return valueString;
  }

  /**
   * Returns a copy of this clause whose values are rendered as numbers, whatever the
   * field type is. Only values that go through getFieldType are affected: INCLUDES /
   * EXCLUDES stay quoted and escaped, and IS NULL / IS NOT NULL write `NULL` directly.
   *
   * For Scribe's HAVING clause: COUNT / COUNT_DISTINCT / SUM / AVG return a number, but
   * the clause is built against the aggregated field, so `COUNT(Id) > 5` would otherwise
   * render its operand as a quoted Id. Rendering it as a number here keeps the operand
   * under the same single-token check as any unquoted value. Scribe used to strip the
   * quotes from the built string instead, which undid the escaping.
   *
   * A clause that does not extend this class never gets the flag, so its rendering is its
   * own. Among the clauses Scribe creates, the only one that does not extend this class is
   * InvalidConditionClause, whose build() always throws. Internal: not part of the supported API.
   *
   * The copy keeps what renderFieldAs set, and renderFieldAs keeps this flag, so the two
   * can be applied in either order (copyWithSettings). overrideField and overrideMetaData
   * keep neither.
   *
   * @return A new clause; this one is left unchanged.
   */
  public IConditionClause asNumericOperand() {
    AbstractConditionClause copy = this.copyWithSettings();
    copy.numericOperand = true;
    return copy;
  }

  /**
   * Returns a copy of this clause that writes its field as `expression` in the SOQL. The
   * field name is still what the value's type is checked against and what getFieldName
   * returns, so assertions keep naming the field.
   *
   * For Scribe: a parent condition writes `Account.Name`, and HAVING writes `MIN(Name)`.
   * Scribe used to edit the built string instead — prefix the relationship path to it, or
   * replace its first word with the aggregate. Both assumed the string starts with the
   * field, but NOT LIKE renders `(NOT Name LIKE ...)`, so they produced
   * `Account.(NOT Name LIKE ...)` and `MIN(Name) Name LIKE ...)` (issues #115 / #109).
   * Writing the field in place does not depend on where a clause puts it.
   *
   * Internal: not part of the supported API.
   *
   * @param expression The field as it appears in the SOQL.
   * @return A new clause; this one is left unchanged.
   */
  public IConditionClause renderFieldAs(String expression) {
    AbstractConditionClause copy = this.copyWithSettings();
    copy.renderedField = expression;
    return copy;
  }

  /**
   * The field as the SOQL writes it: what renderFieldAs set, or the field name.
   *
   * @return The field for build() to write.
   */
  protected String soqlField() {
    return this.renderedField == null ? this.field : this.renderedField;
  }

  /**
   * A copy that keeps the rendering settings, so asNumericOperand and renderFieldAs can be
   * applied in either order without one dropping the other.
   *
   * @return A new clause with the same field, values and rendering settings.
   */
  private AbstractConditionClause copyWithSettings() {
    AbstractConditionClause copy = (AbstractConditionClause) this.overrideField(this.field);
    copy.numericOperand = this.numericOperand;
    copy.renderedField = this.renderedField;
    return copy;
  }

  /**
   * Renders one value as a quoted, escaped literal regardless of the field type, for
   * the multi-select operators (INCLUDES / EXCLUDES) whose operands are always strings.
   *
   * @param value The value to render.
   * @return The quoted SOQL literal.
   */
  protected String toQuotedSoqlLiteral(Object value) {
    return '\'' + this.formatAndCastToString(value) + '\'';
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
