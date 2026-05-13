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
 * @description The mock implementation of the `IEntry` interface, designed to facilitate
 * fast, reliable, and database-independent unit tests.
 *
 * A `MockEntry` wraps a base `SObject` instance but allows any field or relationship value
 * to be overridden via a `Map<String, Object>`. This enables the simulation of complex
 * data scenarios, including non-writable fields and relationships, without DML.
 *
 * It can also represent a virtual `AggregateResult` by being instantiated directly
 * with a map of values.
 *
 * Crucially, `MockEntry` is a high-fidelity mock. When provided with a `FieldStructure`,
 * it simulates the framework's "select-forgotten" validation, throwing an exception
 * if a test attempts to access data that was not part of the original query definition.
 * @see IEntry
 * @see AbstractEntry
 * @see Entry
 */
public with sharing class MockEntry extends AbstractEntry {
  private final Map<String, Object> fieldToValue;
  private Boolean skipFieldValidation = false;
  private String alias;

  private static final String CLASS_NAME = 'MockEntry';

  /**
   * @deprecated
   * This method is deprecated in favor of {@link #of(System.Type)} to align with
   * the declaration patterns of `ApexBlueprint` (my other OSS) and provide
   * a more intuitive developer experience (DX).
   * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * @param sObjectType The SObject type of the record to create.
   * @return A new MockEntry instance.
   */
  public static MockEntry of(Schema.SObjectType sObjectType) {
    SObject record = sObjectType.newSObject();
    return new MockEntry(record);
  }

  /**
   * Creates a new instance of MockEntry for a given SObject Type.
   *
   * @param recordType The Class type of the SObject (e.g., Account.class).
   * @return A new MockEntry instance.
   * @throws ApexEloquentException if recordType is null or not an SObject type.
   */
  public static MockEntry of(System.Type recordType) {
    String method = 'of(System.Type recordType)';
    if (recordType == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'recordType', recordType).fire();
    }

    Object instance = recordType.newInstance();
    if (!(instance instanceof SObject)) {
      String reason = '`recordType` is not an SObject type. ';
      String action = 'Ensure you are passing a valid SObject class (e.g., Opportunity.class, MyCustomObject__c.class)';
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'recordType', recordType).fire();
    }

    return new MockEntry((SObject) instance);
  }

  /**
   * Creates a new MockEntry that represents an `AggregateResult` row.
   *
   * This is the discoverable counterpart to {@link #of(System.Type)} for non-SObject
   * results from aggregate SOQL queries (e.g., `SELECT COUNT(Id) total ...`).
   * The returned MockEntry has no underlying SObject; values are supplied via
   * `.set(fieldNameOrAlias, value)` and read via `.get(fieldNameOrAlias)`.
   *
   * @return A new empty MockEntry in AggregateResult mode.
   */
  public static MockEntry asAggregateResult() {
    return new MockEntry(new Map<String, Object>());
  }

  /**
   * Creates a new MockEntry that represents an `AggregateResult` row, pre-populated
   * with the given field/alias values.
   *
   * Convenience overload for the common case of declaring an aggregate mock inline
   * with multiple field values at once:
   *
   * <pre>
   * MockEntry.asAggregateResult(new Map<String, Object>{
   *   'StageName' => 'Closed Won',
   *   'totalAmount' => 15000
   * });
   * </pre>
   *
   * @param fieldToValue A map of field names or aliases to their mock values.
   * @return A new MockEntry in AggregateResult mode with the supplied values.
   * @throws ApexEloquentException when {@code fieldToValue} is null.
   */
  public static MockEntry asAggregateResult(Map<String, Object> fieldToValue) {
    String method = 'asAggregateResult(Map<String, Object> fieldToValue)';
    if (fieldToValue == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'fieldToValue', fieldToValue).fire();
    }
    return new MockEntry(fieldToValue);
  }

  /**
   * Creates a new MockEntry instance with the specified alias.
   * The alias is used for retrieving the entry via `getByAlias` method.
   *
   * @param alias The alias to assign to this MockEntry.
   * @return A new MockEntry instance with the specified alias.
   */
  public MockEntry alias(String alias) {
    String method = 'alias(String alias)';
    if (alias == null || String.isBlank(alias)) {
      ApexEloquentException.required(CLASS_NAME, method, 'alias', alias).fire();
    }

    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, this.fieldToValue);
    newEntry.inheritParameters(newEntry);
    newEntry.alias = alias;
    return newEntry;
  }

  /**
   * Retrieves a MockEntry by its alias. The search is performed recursively through the current entry and all related entries.
   *
   * @param alias The alias of the MockEntry to retrieve.
   * @return The MockEntry with the specified alias.
   * @throws ApexEloquentException if no MockEntry with the specified alias is found.
   */
  public MockEntry getByAlias(String alias) {
    String method = 'getByAlias(String alias)';
    if (alias == null || String.isBlank(alias)) {
      ApexEloquentException.required(CLASS_NAME, method, 'alias', alias).fire();
    }

    if (this.alias == alias) {
      MockEntry returnEntry = new MockEntry(this.record, this.fieldStructure, this.fieldToValue);
      returnEntry = returnEntry.withoutFieldValidation();
      return returnEntry;
    }
    List<MockEntry> relations = new List<MockEntry>();
    for (Object value : this.fieldToValue.values()) {
      if (value instanceof MockEntry) {
        relations.add((MockEntry) value);
      } else if (value instanceof List<MockEntry>) {
        relations.addAll((List<MockEntry>) value);
      }
    }
    for (MockEntry relation : relations) {
      MockEntry returnEntry = relation.getByAliasFromRelation(alias);
      if (returnEntry != null) {
        returnEntry = returnEntry.withoutFieldValidation();
        return returnEntry;
      }
    }

    String reason = 'No MockEntry found by the specified alias';
    String action =
      'Ensure that a MockEntry with the alias \'' +
      alias +
      '\' exists in the current entry or its relations.';
    ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'alias', alias).fire();

    // This line will never be reached because the above line will always throw an exception, but it's required to satisfy the method's return type.
    return null;
  }

  /**
   * Helper method to recursively search for a MockEntry with the specified alias in related entries.
   *
   * @param alias The alias of the MockEntry to retrieve.
   * @return The MockEntry with the specified alias, or null if not found.
   */
  private MockEntry getByAliasFromRelation(String alias) {
    if (this.alias == alias) {
      return this;
    }

    List<MockEntry> relations = new List<MockEntry>();
    for (Object value : this.fieldToValue.values()) {
      if (value instanceof MockEntry) {
        relations.add((MockEntry) value);
      } else if (value instanceof List<MockEntry>) {
        relations.addAll((List<MockEntry>) value);
      }
    }
    for (MockEntry relation : relations) {
      MockEntry returnEntry = relation.getByAliasFromRelation(alias);
      if (returnEntry != null) {
        return returnEntry;
      }
    }
    return null;
  }

  /**
   * Retrieves the Id of a MockEntry by its alias.
   *
   * @param alias The alias of the MockEntry whose Id to retrieve.
   * @return The Id of the MockEntry with the specified alias.
   * @throws ApexEloquentException if no MockEntry with the specified alias is found.
   */
  public Id getAliasId(String alias) {
    String method = 'getAliasId(String alias)';
    if (alias == null || String.isBlank(alias)) {
      ApexEloquentException.required(CLASS_NAME, method, 'alias', alias).fire();
    }

    MockEntry entry;
    try {
      entry = this.getByAlias(alias);
    } catch (ApexEloquentException e) {
      String reason = 'The specified alias does not exist in the current entry or its relations.';
      String action = 'Ensure that a MockEntry with the alias \'' + alias + '\' exists and is correctly set.';
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'alias', alias).fire();
    }
    return entry.getId();
  }

  /**
   * @deprecated
   * This method is deprecated in favor set {@link #set(String fieldName, Object value)} to align with
   * the declaration patterns of `ApexBlueprint` (my other OSS) and provide
   * a more intuitive developer experience (DX).
   * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * Sets a value for a specified field.
   * This method is immutable and returns a new MockEntry instance.
   *
   * @param fieldName The API name of the field to set.
   * @param value The value to set for the field.
   * @return A new MockEntry instance with the updated field value.
   */
  public MockEntry add(String fieldName, Object value) {
    Map<String, Object> newFieldToValue = new Map<String, Object>(this.fieldToValue);
    newFieldToValue.put(fieldName, value);
    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, newFieldToValue);
    this.inheritParameters(newEntry);
    return newEntry;
  }

  /**
   * Sets a value for a specified field.
   * This method is immutable and returns a new MockEntry instance.
   *
   * @param fieldName The API name of the field to set.
   * @param value The value to set for the field.
   * @return A new MockEntry instance with the updated field value.
   */
  public MockEntry set(String fieldName, Object value) {
    String method = 'set(String fieldName, Object value)';
    if (fieldName == null || String.isBlank(fieldName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'fieldName', fieldName).fire();
    }
    Map<String, Object> newFieldToValue = new Map<String, Object>(this.fieldToValue);
    newFieldToValue.put(fieldName, value);
    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, newFieldToValue);
    this.inheritParameters(newEntry);
    return newEntry;
  }

  /**
   * Sets multiple field values at once using a map of field names to values.
   * This method is immutable and returns a new MockEntry instance.
   *
   * @param fieldToValue A map where the key is the API name of the field and the value is the value to set.
   * @return A new MockEntry instance with the updated field values.
   */
  public MockEntry template(Map<String, Object> fieldToValue) {
    String method = 'template(Map<String, Object> fieldToValue)';
    if (fieldToValue == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'fieldToValue', fieldToValue).fire();
    }

    Map<String, Object> newFieldToValue = new Map<String, Object>(this.fieldToValue);
    for (String fieldName : fieldToValue.keySet()) {
      newFieldToValue.put(fieldName, fieldToValue.get(fieldName));
    }
    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, newFieldToValue);
    this.inheritParameters(newEntry);
    return newEntry;
  }

  /**
   * @deprecated
   * This method is deprecated in favor setChildren {@link #addChildren(String childObjectNameOrRelationName, List<MockEntry> children)} to align with
   * the declaration patterns of `ApexBlueprint` (my other OSS) and provide
   * a more intuitive developer experience (DX).
   * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * Sets a list of child relationship records.
   *
   * @param childObjectNameOrRelationName The child object name or the relationship name (e.g., 'Contacts').
   * @param children A list of MockEntry instances for the child records.
   * @return A new MockEntry instance with the child records added.
   */
  public MockEntry addChildren(String childObjectNameOrRelationName, List<MockEntry> children) {
    Map<String, Object> newFieldToValue = new Map<String, Object>(this.fieldToValue);
    newFieldToValue.put(childObjectNameOrRelationName, children);
    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, newFieldToValue);
    this.inheritParameters(newEntry);
    return newEntry;
  }

  /**
   * Sets a list of child relationship records.
   *
   * @param childObjectNameOrRelationName The child object name or the relationship name (e.g., 'Contacts').
   * @param children A list of MockEntry instances for the child records.
   * @return A new MockEntry instance with the child records added.
   */
  public MockEntry setChildren(String childObjectNameOrRelationName, List<MockEntry> children) {
    String method = 'setChildren(String childObjectNameOrRelationName, List<MockEntry> children)';
    if (childObjectNameOrRelationName == null || String.isBlank(childObjectNameOrRelationName)) {
      ApexEloquentException.required(
          CLASS_NAME,
          method,
          'childObjectNameOrRelationName',
          childObjectNameOrRelationName
        )
        .fire();
    }
    if (children == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'children', children).fire();
    }
    Map<String, Object> newFieldToValue = new Map<String, Object>(this.fieldToValue);
    newFieldToValue.put(childObjectNameOrRelationName, children);
    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, newFieldToValue);
    this.inheritParameters(newEntry);
    return newEntry;
  }

  /**
   * @deprecated
   * This method is deprecated in favor setParent {@link #addParent(String parentIdFieldName, MockEntry parent)} to align with
   * the declaration patterns of `ApexBlueprint` (my other OSS) and provide
   * a more intuitive developer experience (DX).
   * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * Sets a parent relationship record.
   *
   * @param parentIdFieldName The name of the parent ID field (e.g., 'AccountId').
   * @param parent The MockEntry for the parent record.
   * @return A new MockEntry instance with the parent record added.
   */
  public MockEntry addParent(String parentIdFieldName, MockEntry parent) {
    Map<String, Object> newFieldToValue = new Map<String, Object>(this.fieldToValue);
    newFieldToValue.put(parentIdFieldName, parent);
    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, newFieldToValue);
    this.inheritParameters(newEntry);
    return newEntry;
  }

  /**
   * Sets a parent relationship record.
   *
   * @param parentIdFieldName The name of the parent ID field (e.g., 'AccountId').
   * @param parent The MockEntry for the parent record.
   * @return A new MockEntry instance with the parent record added.
   */
  public MockEntry setParent(String parentIdFieldName, MockEntry parent) {
    String method = 'setParent(String parentIdFieldName, MockEntry parent)';
    if (parentIdFieldName == null || String.isBlank(parentIdFieldName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'parentIdFieldName', parentIdFieldName).fire();
    }
    Map<String, Object> newFieldToValue = new Map<String, Object>(this.fieldToValue);
    newFieldToValue.put(parentIdFieldName, parent);
    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, newFieldToValue);
    this.inheritParameters(newEntry);
    return newEntry;
  }

  /**
   * Automatically generates an 18-character ID from the SObject's prefix and a specified suffix,
   * and sets it on the Id field.
   *
   * @param suffix The string to be used at the end of the ID.
   * @return A new MockEntry instance with the Id field set.
   */
  public MockEntry autoId(String suffix) {
    String method = 'autoId(String suffix)';
    if (String.isBlank(suffix)) {
      ApexEloquentException.required(CLASS_NAME, method, 'suffix', suffix).fire();
    }
    if (suffix == '{#}' || suffix == '{A}' || suffix == '{a}') {
      return this.add('Id', suffix);
    }
    String id = this.generate18CharId(suffix);
    FieldStructure clonedfieldStructure = this.fieldStructure.clone();
    clonedfieldStructure.addField('id');
    MockEntry newEntry = new MockEntry(this.record, clonedfieldStructure, this.fieldToValue);
    newEntry = newEntry.add('Id', id);
    this.inheritParameters(newEntry);
    return newEntry;
  }

  /**
   * Automatically generates an 18-character ID from the SObject's prefix and a specified suffix,
   * and sets it on the Id field.
   *
   * @param suffix The number (non-negative) to be used at the end of the ID.
   * @return A new MockEntry instance with the Id field set.
   * @throws ApexEloquentException if the suffix is a negative number.
   */
  public MockEntry autoId(Integer suffix) {
    String method = 'autoId(Integer suffix)';
    if (suffix == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'suffix', suffix).fire();
    }
    if (suffix < 0) {
      String reason = 'Negative values are not allowed for ID generation suffixes.';
      String action = 'Change the `suffix` argument to a non-negative integer (0 or greater).';
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'suffix', suffix).fire();
    }
    return this.autoId(String.valueOf(suffix));
  }

  /**
   * Generates a list of records using the current MockEntry as a template.
   * The sequence starts at 1 and increments by 1.
   *
   * @param count The number of records to generate.
   * @return A list of generated MockEntry instances.
   */
  public List<MockEntry> times(Integer count) {
    String method = 'times(Integer count)';
    ApexEloquentException validationException = this.validateTimesParams(count, 1, 1);
    if (validationException != null) {
      validationException.method(method).fire();
    }
    return this.times(count, 1, 1);
  }

  /**
   * Generates a list of records using the current MockEntry as a template.
   * The sequence starts at the specified number and increments by 1.
   *
   * @param count The number of records to generate.
   * @param startAt The starting number for the sequence.
   * @return A list of generated MockEntry instances.
   */
  public List<MockEntry> times(Integer count, Integer startAt) {
    String method = 'times(Integer count, Integer startAt)';
    ApexEloquentException validationException = this.validateTimesParams(count, startAt, 1);
    if (validationException != null) {
      validationException.method(method).fire();
    }
    return this.times(count, startAt, 1);
  }

  /**
   * Generates a list of records using the current MockEntry as a template.
   * Field values can contain '{#}', '{A}', and '{a}' placeholders to embed sequential values.
   *
   * @param count The number of records to generate.
   * @param startAt The starting number for the sequence.
   * @param interval The step or interval between each number in the sequence.
   * @return A list of generated MockEntry instances.
   * @throws IllegalArgumentException if count is 0 or less, or if an alphabetic sequence is used and startAt is less than 1.
   * @example
   * // Generates 3 records with Names 'Test Account 10', 'Test Account 20', 'Test Account 30'
   * .add('Name', 'Test Account {#}').times(3, 10, 10);
   */
  public List<MockEntry> times(Integer count, Integer startAt, Integer interval) {
    String method = 'times(Integer count, Integer startAt, Integer interval)';
    ApexEloquentException validationException = this.validateTimesParams(count, startAt, interval);
    if (validationException != null) {
      validationException.method(method).fire();
    }

    List<MockEntry> entries = new List<MockEntry>();
    for (Integer i = 0; i < count; i++) {
      Integer currentSequence = startAt + (i * interval);
      Map<String, Object> newFieldToValue = new Map<String, Object>();

      for (String key : this.fieldToValue.keySet()) {
        Object templateValue = this.fieldToValue.get(key);
        Object resolvedValue = this.resolveValue(templateValue, currentSequence);

        if (key.startsWith('id') || key.startsWith('Id') || key.endsWith('Id')) {
          newFieldToValue.put(key, this.generate18CharId(String.valueOf(resolvedValue)));
        } else {
          newFieldToValue.put(key, resolvedValue);
        }
      }
      MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, newFieldToValue);
      this.inheritParameters(newEntry);
      if (this.alias != null) {
        newEntry = newEntry.alias((String) this.resolveValue(this.alias, currentSequence));
      }
      entries.add(newEntry);
    }

    return entries;
  }

  private ApexEloquentException validateTimesParams(Integer count, Integer startAt, Integer interval) {
    if (count == null) {
      return ApexEloquentException.required(CLASS_NAME, '', 'count', count);
    }
    if (count <= 0) {
      String reason = 'The `count` argument must be greater than 0';
      String action = 'Ensure that the `count` argument is a positive integer (1 or greater)';
      return ApexEloquentException.invalidArgument(CLASS_NAME, '', reason, action, 'count', count);
    }

    if (startAt == null) {
      return ApexEloquentException.required(CLASS_NAME, '', 'startAt', startAt);
    }

    if(interval == null) {
      return ApexEloquentException.required(CLASS_NAME, '', 'interval', interval);
    }
    if(interval == 0) {
      String reason = 'The `interval` argument must be a non-zero integer for creating a sequence with a step';
      String action = 'Ensure that the `interval` argument is a non-zero integer';
      return ApexEloquentException.invalidArgument(CLASS_NAME, '', reason, action, 'interval', interval);
    }

    Boolean hasAlphabeticPlaceholder = false;
    for (Object value : this.fieldToValue.values()) {
      if (value instanceof String) {
        String strValue = (String) value;
        if (strValue.contains('{A}') || strValue.contains('{a}')) {
          hasAlphabeticPlaceholder = true;
          break;
        }
      }
    }

    if (hasAlphabeticPlaceholder && startAt < 1) {
      // throw new IllegalArgumentException(
        // 'Alphabetic sequences {A} or {a} require \'startAt\' to be 1 or greater.'
      //);
      String reason = 'Alphabetic sequences {A} or {a} require `startAt` to be 1 or greater';
      String action = 'Ensure that the `startAt` argument is set to 1 or greater when using alphabetic placeholders';
      return ApexEloquentException.invalidArgument(CLASS_NAME, '', reason, action, 'startAt', startAt);
    }

    return null;
  }

  /**
   * Resolves a template value by replacing placeholders with the current sequence number.
   * Supported placeholders:
   * - '{#}': Replaced with the current sequence number.
   * - '{A}': Replaced with the current sequence number converted to an uppercase alphabetic representation.
   * - '{a}': Replaced with the current sequence number converted to a lowercase alphabetic representation.
   * If the template value is not a string, it is returned as-is.
   *
   * @param templateValue The template value containing placeholders.
   * @param sequence The current sequence number to replace placeholders.
   * @return The resolved value with placeholders replaced.
   */
  private Object resolveValue(Object templateValue, Integer sequence) {
    if (!(templateValue instanceof String)) {
      return templateValue;
    }

    String value = (String) templateValue;

    if (value == '{#}') {
      return sequence;
    }

    String resolvedString = value.replace('{#}', String.valueOf(sequence))
      .replace('{A}', this.convertNumberToAlphabet(sequence, true))
      .replace('{a}', this.convertNumberToAlphabet(sequence, false));

    return resolvedString;
  }

  /**
   * Generates an 18-character Salesforce ID using the SObject's key prefix and a specified suffix.
   * The suffix is left-padded with zeros to ensure the total length is 18 characters.
   *
   * @param suffix The string to be used at the end of the ID.
   * @return An 18-character Salesforce ID.
   */
  private String generate18CharId(String suffix) {
    String prefix = this.record.getSObjectType().getDescribe().getKeyPrefix();
    return this.convert15To18(prefix + String.valueOf(suffix).leftPad(15 - prefix.length(), '0'));
  }

  /**
   * Converts a 15-character Salesforce ID to its 18-character equivalent by calculating the checksum.
   *
   * @param id15 The 15-character Salesforce ID.
   * @return The corresponding 18-character Salesforce ID, or null if the input is invalid.
   */
  private String convert15To18(String id15) {
    if (id15 == null || id15.length() != 15) {
      return null;
    }

    final String CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345';
    String checksum = '';

    for (Integer i = 0; i < 3; i++) {
      Integer flags = 0;
      for (Integer j = 0; j < 5; j++) {
        String c = id15.substring(i * 5 + j, i * 5 + j + 1);

        Integer charCode = c.charAt(0);
        if (charCode >= 65 && charCode <= 90) {
          flags += 1 << j;
        }
      }
      checksum += CHARS.substring(flags, flags + 1);
    }
    return id15 + checksum;
  }

  /**
   * Converts a positive integer to its corresponding alphabetic representation.
   * For example, 1 -> 'A', 26 -> 'Z', 27 -> 'AA', 52 -> 'AZ', 53 -> 'BA', etc.
   *
   * @param num The positive integer to convert.
   * @param isUpperCase If true, returns uppercase letters; if false, returns lowercase letters.
   * @return The alphabetic representation of the number.
   */
  private String convertNumberToAlphabet(Integer num, Boolean isUpperCase) {
    if (num == null || num <= 0) {
      return '';
    }

    final Integer BASE_CHAR_CODE = isUpperCase ? 65 : 97;
    final Integer BASE = 26;
    String result = '';

    Integer current = num;
    while (current > 0) {
      Integer remainder = Math.mod(current - 1, BASE);

      Integer charCode = BASE_CHAR_CODE + remainder;
      result = String.fromCharArray(new List<Integer>{ charCode }) + result;

      current = (current - remainder) / BASE;
    }
    return result;
  }

  /**
   * constructor
   *
   * @param record SObject
   */
  public MockEntry(SObject record) {
    super(record);
    this.fieldToValue = new Map<String, Object>();
  }

  /**
   * constructor
   *
   * @param record SObject
   * @param fieldToValue field to value map
   */
  public MockEntry(SObject record, Map<String, Object> fieldToValue) {
    super(record);
    this.fieldToValue = fieldToValue;
  }

  /**
   * constructor
   *
   * @param record SObject
   * @param fieldStructure FieldStructure
   */
  public MockEntry(SObject record, FieldStructure fieldStructure) {
    super(record, fieldStructure);
    this.fieldToValue = new Map<String, Object>();
  }

  /**
   * @deprecated
   * Use {@link #asAggregateResult()} or {@link #asAggregateResult(Map)} instead.
   * The static factories make the intent ("AggregateResult mode") obvious at the
   * call site, aligning with the `MockEntry.of(...)` / `Scribe.asParent / asChild / asHaving`
   * patterns elsewhere in ApexEloquent.
   *
   * This constructor is retained for backward compatibility but may be removed
   * in a future major version.
   *
   * @param fieldToValue field to value map
   */
  public MockEntry(Map<String, Object> fieldToValue) {
    super(null);
    this.fieldToValue = fieldToValue;
    this.hasAggregateResult = true;
  }

  /**
   * constructor for testing
   *
   * @param record SObject
   * @param fieldStructure FieldStructure
   * @param fieldToValue field to value map
   */
  @TestVisible
  private MockEntry(SObject record, FieldStructure fieldStructure, Map<String, Object> fieldToValue) {
    super(record, fieldStructure);
    this.fieldToValue = fieldToValue;
  }

  /**
   * @inheritDoc
   */
  public override Object get(String fieldName) {
    String method = 'get(String fieldName)';
    if (fieldName == null || String.isBlank(fieldName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'fieldName', fieldName).fire();
    }

    if (this.hasAggregateResult) {
      if (!this.skipFieldValidation && !this.fieldStructure.hasField(fieldName.toLowerCase())) {
        String reason = 'The specified field or alias is not exist in Scribe.';
        String action = 'Add the field or alias to the Scribe definition for this AggregateResult';
        ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'fieldName', fieldName).fire();
      }

      for (String key : this.fieldToValue.keySet()) {
        if (key.equalsIgnoreCase(fieldName)) {
          Object value = this.fieldToValue.get(key);
          if (value instanceof IEntry) {
            IEntry entry = (IEntry) value;
            if (this.skipFieldValidation && entry instanceof MockEntry) {
              entry = ((MockEntry) entry).withoutFieldValidation();
            }
            FieldStructure relationFieldStructure = this.fieldStructure == null
              ? new FieldStructure(new List<String>())
              : this.fieldStructure.getRelationFieldStructure(fieldname.toLowerCase());
            return entry.setFieldStructure(relationFieldStructure).getId();
          }
          return this.fieldToValue.get(key);
        }
      }

      // Since an AggregateResult cannot be instantiated like an SObject, we must throw an error if the requested field/alias is not found in the fieldToValue map.
      String reason = 'The requested field or alias is not defined in the mock data provided for this AggregateResult.';
      String action =
        'Ensure that the field or alias \'' +
        fieldName +
        '\' is included in the mock data map when creating this MockEntry instance.';
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'fieldName', fieldName).fire();
    }

    try {
      this.validateFieldName(fieldName);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action =
        'Ensure that the field \'' +
        fieldName +
        '\' is included in the Scribe definition for this object.';
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'fieldName', fieldName, e).fire();
    }
    this.ensureDescribeResultIfNeeded();

    for (String key : this.fieldToValue.keySet()) {
      if (key.equalsIgnoreCase(fieldName)) {
        Object value = this.fieldToValue.get(key);
        if (value instanceof IEntry) {
          IEntry entry = (IEntry) value;
          if (this.skipFieldValidation && entry instanceof MockEntry) {
            entry = ((MockEntry) entry).withoutFieldValidation();
          }
          FieldStructure relationFieldStructure = this.fieldStructure == null
            ? new FieldStructure(new List<String>())
            : this.fieldStructure.getRelationFieldStructure(fieldname.toLowerCase());
          return entry.setFieldStructure(relationFieldStructure).getId();
        }
        return this.fieldToValue.get(key);
      }
    }

    Entry entry = new Entry(this.record);
    return entry.get(fieldName);
  }

  /**
   * @inheritDoc
   */
  public override void put(String fieldName, Object value) {
    String method = 'put(String fieldName, Object value)';
    if (this.hasAggregateResult) {
      String reason = 'The put() operation is incompatible with AggregateResult-based MockEntry instances';
      ApexEloquentException.invalidOperation(CLASS_NAME, method, reason).fire();
    }

    try {
      this.record.put(fieldName, value);
      this.fieldToValue.put(fieldName, value);
      this.fieldStructure.addField(fieldName.toLowerCase());
    } catch (Exception e) {
      String reason = 'SObject.put() failed: ' + e.getMessage();
      String action = 'Check the field API name and ensure the value type matches the field definition.';
      Map<String, Object> paramToValue = new Map<String, Object>{ 'fieldName' => fieldName, 'value' => value };
      ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, paramToValue, e).fire();
    }
  }

  /**
   * @inheritDoc
   */
  public override IEntry getParent(String parentIdFieldName) {
    String method = 'getParent(String parentIdFieldName)';
    if (parentIdFieldName == null || String.isBlank(parentIdFieldName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'parentIdFieldName', parentIdFieldName).fire();
    }

    this.ensureDescribeResultIfNeeded();
    String lowerCaseFieldName = parentIdFieldName.toLowerCase();

    if (!this.skipFieldValidation && !this.fieldStructure.hasRelation(lowerCaseFieldName)) {
      String reason =
        'The specified parentIdFieldName is not defined as a relationship in Scribe. SObject: ' +
        this.describeResult.getName();
      String action =
        'Ensure that the parentIdFieldName \'' +
        parentIdFieldName +
        '\' is included as a relationship in the Scribe definition for this object.';
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'parentIdFieldName',
          parentIdFieldName
        )
        .fire();
    }

    if (this.fieldToValue.containsKey(parentIdFieldName)) {
      IEntry resultEntry = (IEntry) this.fieldToValue.get(parentIdFieldName);
      if (this.skipFieldValidation && resultEntry instanceof MockEntry) {
        resultEntry = ((MockEntry) resultEntry).withoutFieldValidation();
      }
      FieldStructure parentFieldStructure = this.fieldStructure == null
        ? new FieldStructure(new List<String>())
        : this.fieldStructure.getRelationFieldStructure(lowerCaseFieldName);
      System.debug('skipFieldValidation: ' + this.skipFieldValidation);
      return resultEntry.setFieldStructure(parentFieldStructure);
    }

    Entry entry = new Entry(this.record);
    return entry.getParent(parentIdFieldName);
  }

  /**
   * @inheritDoc
   */
  public override List<IEntry> getChildren(String childObjectName) {
    String method = 'getChildren(String childObjectName)';
    if (childObjectName == null || String.isBlank(childObjectName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'childObjectName', childObjectName).fire();
    }

    this.ensureDescribeResultIfNeeded();
    // for validate the childObjectName
    try {
      String childRelationName = this.getChildrenRelationNameFromChildObjectName(childObjectName);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action = 'Use getChildrenByRelationName() to specify the relationship name instead of the object name';
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'childObjectName',
          childObjectName,
          e
        )
        .fire();
    }

    String errorTemplate = 'The specified child Object Name `{0}` is not set in Scribe. parent object name: {1}';
    try {
      this.validateChildRelationInFieldStructure(childObjectname, errorTemplate);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action =
        'Ensure that the childObjectName \'' +
        childObjectName +
        '\' or its corresponding child relation name is included in the Scribe definition for this object.';
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'childObjectName',
          childObjectName,
          e
        )
        .fire();
    }

    for (String key : this.fieldToValue.keySet()) {
      if (key.equalsIgnoreCase(childObjectName)) {
        errorTemplate = 'The child object needs to be a List<IEntry> or IEntry. parent object name: {0}';
        try {
          return this.getchildEntriesFromFieldToValue(key, errorTemplate);
        } catch (ApexEloquentException e) {
          String reason = e.getMessage();
          String action =
            'Ensure that the value associated with \'' +
            childObjectName +
            '\' is a List<IEntry> or IEntry in the mock data for this object.';
          ApexEloquentException.invalidArgument(
              CLASS_NAME,
              method,
              reason,
              action,
              'childObjectName',
              childObjectName,
              e
            )
            .fire();
        }
      }
    }

    Entry entry = new Entry(this.record);
    return entry.getChildren(childObjectName);
  }

  /**
   * @inheritDoc
   */
  public override List<IEntry> getChildrenByRelationName(String childRelationName) {
    String method = 'getChildrenByRelationName(String childRelationName)';
    if(childRelationName == null || String.isBlank(childRelationName)) {
      ApexEloquentException.required(CLASS_NAME, method, 'childRelationName', childRelationName).fire();
    }

    this.ensureDescribeResultIfNeeded();
    String errorTemplate = 'The specified child relation name `{0}` is not set in Scribe. parent object name: {0}';
    try {
      this.validateChildRelationInFieldStructure(childRelationname, errorTemplate);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action =
        'Ensure that the child relation name \'' +
        childRelationName +
        '\' is included in the Scribe definition for this object.';
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'childRelationName',
          childRelationName,
          e
        )
        .fire();
    }

    try {
      this.validateChildRelationName(childRelationName);
    } catch (ApexEloquentException e) {
      String reason = e.getMessage();
      String action =
        'Ensure that the child relation name \'' +
        childRelationName +
        '\' is a valid child relationship for this object.';
      System.debug('fireするよ');
      ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'childRelationName',
          childRelationName,
          e
        )
        .fire();
    }

    for (String key : this.fieldToValue.keySet()) {
      if (key.equalsIgnoreCase(childRelationName)) {
        errorTemplate = 'The child object needs to be a List<IEntry> or IEntry. parent object name: {0}';
        try {
          return this.getchildEntriesFromFieldToValue(key, errorTemplate);
        } catch (ApexEloquentException e) {
          String reason = e.getMessage();
          String action =
            'Ensure that the value associated with \'' +
            childRelationName +
            '\' is a List<IEntry> or IEntry in the mock data for this object.';
          ApexEloquentException.invalidArgument(
              CLASS_NAME,
              method,
              reason,
              action,
              'childRelationName',
              childRelationName,
              e
            )
            .fire();
        }
      }
    }

    Entry entry = new Entry(this.record);
    return entry.getChildrenByRelationName(childRelationName);
  }

  /**
   * @inheritDoc
   */
  public override Id getId() {
    string method = 'getId()';
    try {
      this.validateFieldName('Id');
    } catch (ApexEloquentException e) {
      String reason = e.getMessage() + ', field: Id';
      String action = 'Add the Id field to the Scribe definition for this object';
      ApexEloquentException.message(CLASS_NAME, 'getId()', reason, action, e).fire();
    }

    if (this.fieldToValue.containsKey('Id')) {
      return (Id) this.fieldToValue.get('Id');
    }

    return (Id) this.record.get('Id');
  }

  /**
   * @inheritDoc
   */
  public override String getName() {
    String method = 'getName()';
    try {
      this.validateFieldName('Name');
    } catch (ApexEloquentException e) {
      String reason = e.getMessage() + ', field: Name';
      String action = 'Add the Name field to the Scribe definition for this object';
      ApexEloquentException.message(CLASS_NAME, method, reason, action, e).fire();
    }

    if (this.fieldToValue.containsKey('Name')) {
      return (String) this.fieldToValue.get('Name');
    }

    return (String) this.record.get('Name');
  }

  /**
   * @inheritDoc
   */
  /**
   * Disable the "unselected field detection" feature for this MockEntry.
   *
   * NOTE: This is a MockEntry-only API. It is intentionally NOT exposed on IEntry
   * because Entry (production) has no concept of skip-validation — defining it on
   * the interface would force a LSP-violating throw on the Entry side.
   *
   * Use this when constructing mock data that intentionally omits some fields:
   *   mockEntry.withoutFieldValidation()
   *
   * @return a new MockEntry instance with skipFieldValidation = true
   */
  public MockEntry withoutFieldValidation() {
    MockEntry newEntry = new MockEntry(this.record, this.fieldStructure, this.fieldToValue);
    newEntry.inheritParameters(newEntry);
    newEntry.skipFieldValidation = true;
    return newEntry;
  }

  /**
   * Returns the underlying SObject with all scalar field overrides applied.
   *
   * Implementation notes:
   *  - Uses JSON round-trip so formula / audit / rollup / other read-only fields
   *    can also be populated for testing (SObject.put() rejects these).
   *  - Relation overrides (set via setParent / setChildren) are NOT embedded in
   *    the returned SObject. The returned SObject only contains scalar field values.
   *
   * Usage notes for callers:
   *  - When you need related data, navigate via the IEntry API first
   *    (getParent / getChildren / getChildrenByRelationName / getThrough / getThroughByRelationName)
   *    and then call getRecord() on the resulting IEntry.
   *  - Calling getRecord() on a MockEntry that represents an AggregateResult
   *    throws ApexEloquentException — AggregateResult cannot be returned as a regular SObject.
   *
   * @return The SObject with scalar overrides applied (defensive clone, not aliasing internal state).
   * @throws ApexEloquentException when called on an AggregateResult-mode MockEntry, or when the
   *         JSON round-trip fails (e.g. value type does not match the target field type).
   */
  public override SObject getRecord() {
    String method = 'getRecord()';

    if (this.hasAggregateResult) {
      ApexEloquentException.invalidOperation(
          CLASS_NAME,
          method,
          'getRecord() is not supported on a MockEntry that represents an AggregateResult; AggregateResult cannot be returned as a regular SObject'
        )
        .fire();
    }

    // 1. Defensive clone so the caller cannot mutate the cached internal state.
    SObject baseRecord = this.record.clone(true, true, true, true);

    // 2. Extract scalar overrides only. IEntry / List<IEntry> values stored via
    //    setParent / setChildren are relationship data, not flat SObject fields.
    Map<String, Object> scalarOverrides = new Map<String, Object>();
    for (String fieldName : this.fieldToValue.keySet()) {
      Object value = this.fieldToValue.get(fieldName);
      if (value instanceof IEntry) {
        continue;
      }
      if (value instanceof List<IEntry>) {
        continue;
      }
      scalarOverrides.put(fieldName, value);
    }

    if (scalarOverrides.isEmpty()) {
      return baseRecord;
    }

    // 3. JSON round-trip applies the overrides even on read-only fields
    //    (formula / audit / rollup) which SObject.put() would reject.
    try {
      Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(baseRecord));
      jsonMap.putAll(scalarOverrides);
      Type apexType = Type.forName(this.record.getSObjectType().getDescribe().getName());
      return (SObject) JSON.deserialize(JSON.serialize(jsonMap), apexType);
    } catch (Exception e) {
      String reason = 'Failed to apply scalar overrides to the SObject via JSON round-trip';
      String action = 'Verify each scalar override value matches the target field type (Date/Datetime/Decimal/Boolean/etc.)';
      ApexEloquentException.invalidOperation(CLASS_NAME, method, reason)
        .param('scalarOverrides', scalarOverrides)
        .action(action)
        .causedBy(e)
        .fire();
      return null; // unreachable
    }
  }

  /**
   * @inheritDoc
   */
  public override IEntry setRecord(SObject record) {
    MockEntry newMockEntry = new MockEntry(record, this.fieldStructure, this.fieldToValue);
    this.inheritParameters(newMockEntry);
    return newMockEntry;
  }

  /**
   * @inheritDoc
   */
  public override IEntry setFieldStructure(FieldStructure fieldStructure) {
    MockEntry newMockEntry = new MockEntry(this.record, fieldStructure, this.fieldToValue);
    this.inheritParameters(newMockEntry);
    return newMockEntry;
  }

  /**
   * validate the field name.
   *
   * @param fieldName field name to be validated
   * @throws ApexEloquentException if the field is not picked in Scribe
   */
  private void validateFieldName(String fieldName) {
    String lowerCaseFieldName = fieldName.toLowerCase();
    if (this.skipFieldValidation || this.fieldStructure.hasField(lowerCaseFieldName)) {
      return;
    }

    String reason = 'The specified field is not selected in Scribe';
    String action = 'Add the field to the Scribe definition (e.g. `.field(\'' + fieldName + '\')`) or call .withoutFieldValidation() when intentional';
    ApexEloquentException.invalidArgument(CLASS_NAME, null, reason, action, 'fieldName', fieldName)
      .param('objectName', this.record.getSObjectType().getDescribe().getName())
      .fire();
  }

  /**
   * validate the child relation name.
   *
   * @param childRelationName child relation name to be validated
   * @throws ApexEloquentException if the child relation name is not valid
   */
  private void validateChildRelationInFieldStructure(String relation, String errorTemplate) {
    if (!this.skipFieldValidation && !this.fieldStructure.hasRelation(relation.toLowerCase())) {
      this.ensureDescribeResultIfNeeded();
      String reason = String.format(errorTemplate, new List<String>{ relation, this.describeResult.getName() });
      String action = 'Add the relation to the Scribe definition (.withChildren(...)) or call .withoutFieldValidation() when intentional';
      ApexEloquentException.invalidArgument(CLASS_NAME, null, reason, action, 'relation', relation)
        .param('parentObjectName', this.describeResult.getName())
        .fire();
    }
  }

  /**
   * validate the child relation name.
   *
   * @param childRelationName child relation name to be validated
   * @throws ApexEloquentException if the child relation name is not valid
   */
  private List<IEntry> getChildEntriesFromFieldToValue(String key, String errorTemplate) {
    List<IEntry> entries = new List<IEntry>();
    Object childObjects = this.fieldToValue.get(key);
    if (childObjects instanceof List<IEntry>) {
      entries = (List<IEntry>) childObjects;
    } else if (childObjects instanceof IEntry) {
      entries = new List<IEntry>{ (IEntry) childObjects };
    } else {
      this.ensureDescribeResultIfNeeded();
      String reason = String.format(errorTemplate, new List<String>{ this.describeResult.getName() });
      ApexEloquentException.invalidOperation(CLASS_NAME, null, reason).fire();
    }

    List<IEntry> resultEntries = new List<IEntry>();
    FieldStructure childFieldStructure = this.fieldStructure == null
      ? new FieldStructure()
      : this.fieldStructure.getRelationFieldStructure(key.toLowerCase());
    for (IEntry entry : entries) {
      if (this.skipFieldValidation && entry instanceof MockEntry) {
        entry = ((MockEntry) entry).withoutFieldValidation();
      }
      resultEntries.add(entry.setFieldStructure(childFieldStructure));
    }
    return resultEntries;
  }

  private void inheritParameters(MockEntry entry) {
    entry.skipFieldValidation = this.skipFieldValidation;
    entry.alias = this.alias;
  }
}
