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
 * @description A fluent, immutable, and type-safe query builder for SOQL, inspired by Laravel Eloquent.
 * Scribe allows developers to construct complex SOQL queries programmatically
 * without string concatenation, reducing errors and improving readability.
 * It is the core of the ApexEloquent ORM's query building capabilities.
 */
public with sharing class Scribe {
  private static final String CLASS_NAME = 'Scribe';

  // =================================================================================================================
  // Properties
  // =================================================================================================================

  @TestVisible
  private Schema.SObjectType sObjectType;
  private Schema.DescribeSObjectResult describe;

  // SELECT clause properties
  @TestVisible
  private Set<String> selectFields = new Set<String>();
  private List<IAggregateClause> aggregateClauses = new List<IAggregateClause>();
  private Boolean isSelectAll = false;

  // WHERE clause properties
  private List<ConditionPart> conditionParts = new List<ConditionPart>();
  private Boolean isNextConditionOr = false;
  private Boolean canOnlyAddOrCondition = false;
  // True only immediately after a where...() condition. Intentionally NOT copied in deepClone(),
  // so it resets on every builder step — ignoreWhen() is therefore valid ONLY directly after a where...().
  private Boolean isAfterWhereClause = false;

  // Relationship properties
  private List<ParentScribe> parents = new List<ParentScribe>();
  private List<Scribe> children = new List<Scribe>();
  private List<Scribe> throughScribes = new List<Scribe>();
  private Schema.SObjectType junctionSObjectType;
  private String parentRelationIdFieldName;
  private String relationName = '';

  // Aggregate clause properties
  private List<GroupByClause> groupByClauses = new List<GroupByClause>();
  private Map<String, AliasStructure> aggregateAliasMap = new Map<String, AliasStructure>();
  private Scribe havingScribe;

  // ORDER BY clause properties
  private List<Scribe.OrderByClause> orderByClauses = new List<Scribe.OrderByClause>();

  // LIMIT clause properties
  private Integer limitNumber = 0;

  // OFFSET clause properties
  private Integer offsetNumber = 0;

  // Other properties
  private Boolean isParent = false;
  private Boolean isChild = false;
  private Boolean isGroup = false;
  private Boolean isThrough = false;
  private Boolean isHaving = false;
  private Boolean isForUpdate = false;

  // Constants
  private final Integer MAX_UPPER_NESTING_DEPTH = 5;
  private final Integer MAX_LOWER_NESTING_DEPTH = 4;

  // =================================================================================================================
  // Constructor
  // =================================================================================================================

  /**
   * Constructor to initialize a Scribe instance.
   * Use the static `source()` method to start building a query.
   * @param sObjectType The SObject type for the query.
   */
  public Scribe(Schema.SObjectType sObjectType) {
    this.sObjectType = sObjectType;
    this.describe = sObjectType != null ? sObjectType.getDescribe() : null;
  }

  // =================================================================================================================
  // Static Factory Methods
  // =================================================================================================================

  /**
   * @deprecated
   * This method is deprecated in favor of {@link #of(System.Type)} to align with
   * the declaration patterns of `ApexBlueprint` (my other OSS) and provide
   * a more intuitive developer experience (DX).
   * * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * Creates a new Scribe instance, setting the source SObject (the FROM clause).
   * This is the entry point for building a new query.
   * Example: `Scribe.source(Account.getSObjectType())`
   *
   * @param sObjectType The SObject type to query from.
   * @return A new Scribe instance.
   */
  public static Scribe source(Schema.SObjectType sObjectType) {
    Scribe newScribe = new Scribe(sObjectType);
    return newScribe;
  }

  /**
   * Creates a new Scribe instance, setting the source SObject (the FROM clause).
   * This is the entry point for building a new query.
   * Example: `Scribe.source(Account.getSObjectType())`
   *
   * @param recordType The Class type of the SObject (e.g., Account.class).
   * @return A new Scribe instance.
   */
  public static Scribe of(System.Type recordType) {
    String method = 'of(System.Type recordType)';
    if (recordType == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'recordType', null).build();
    }

    Object instance = recordType.newInstance();
    if (!(instance instanceof SObject)) {
      String reason = recordType.getName() + ' is not an SObject type.';
      String action = 'Ensure you are passing a valid SObject class (e.g., Opportunity.class, MyCustomObject__c.class).';
      throw ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'recordType',
          recordType.getName()
        )
        .build();
    }

    Schema.SObjectType sObjectType = ((SObject) instance).getSObjectType();
    Scribe newScribe = new Scribe(sObjectType);
    return newScribe;
  }

  /**
   * Creates a Scribe instance for grouping WHERE conditions with parentheses.
   * Example: `.whereGroup(Scribe.asGroup().whereEqual(...).whereIn())`
   *
   * @return A new Scribe instance configured for grouping.
   */
  public static Scribe asGroup() {
    Scribe newScribe = new Scribe(null);
    newScribe.isGroup = true;
    return newScribe;
  }
  /**
   * Creates a Scribe instance representing a parent relationship for field selection or conditions.
   * Example: `.parentField(Scribe.asParent('AccountId').fields(...).whereEqual(...))`
   *
   * @param parentRelationIdFieldName The API name of the lookup or master-detail field (e.g., 'AccountId').
   * @return A new Scribe instance configured for a parent relationship.
   * @throws ApexEloquentException if the field name is blank.
   */
  public static Scribe asParent(String parentRelationIdFieldName) {
    String method = 'asParent(String parentRelationIdFieldName)';
    if (String.isBlank(parentRelationIdFieldName)) {
      throw ApexEloquentException.required(
          CLASS_NAME,
          method,
          'parentRelationIdFieldName',
          parentRelationIdFieldName
        )
        .build();
    }
    Scribe newScribe = new Scribe(null);
    newScribe.isParent = true;
    newScribe.parentRelationIdFieldName = parentRelationIdFieldName;
    return newScribe;
  }

  /**
   * @deprecated
   * This method is deprecated in favor asChild {@link #asChild(System.Type)} to align with
   * the declaration patterns of `ApexBlueprint` (my other OSS) and provide
   * a more intuitive developer experience (DX).
   * * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * Creates a Scribe instance representing a child subquery.
   * Example: `.withChildren(Scribe.asChild(Contact.getSObjectType()).fields(...).whereEqual(...))`
   *
   * @param childSObjectType The SObjectType of the child records.
   * @return A new Scribe instance configured for a child relationship.
   * @throws ApexEloquentException if the SObjectType is null.
   */
  public static Scribe asChild(Schema.SObjectType childSObjectType) {
    String method = 'asChild(Schema.SObjectType childSObjectType)';
    if (childSObjectType == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'childRecordType', null).build();
    }
    Scribe newScribe = new Scribe(childSObjectType);
    newScribe.isChild = true;

    return newScribe;
  }

  /**
   * Creates a Scribe instance representing a child subquery.
   * Example: `.withChildren(Scribe.asChild(Contact.getSObjectType()).fields(...).whereEqual(...))`
   *
   * @param childRecordType The Class type of the child SObject (e.g., Contact.class).
   * @return A new Scribe instance configured for a child relationship.
   * @throws ApexEloquentException if the SObjectType is null.
   */
  public static Scribe asChild(System.Type childRecordType) {
    String method = 'asChild(System.Type childRecordType)';
    if (childRecordType == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'childRecordType', null).build();
    }

    Object instance = childRecordType.newInstance();
    if (!(instance instanceof SObject)) {
      String reason = childRecordType.getName() + ' is not an SObject type.';
      String action = 'Ensure you are passing a valid SObject class (e.g., Contact.class, MyCustomObject__c.class).';
      throw ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'childRecordType',
          childRecordType.getName()
        )
        .build();
    }

    Schema.SObjectType childSObjectType = ((SObject) instance).getSObjectType();
    return Scribe.asChild(childSObjectType);
  }

  /**
   * Creates a Scribe instance for a HAVING clause.
   * Example: `.havingCondition(Scribe.asHaving().whereGreaterThan(...))`
   *
   * @return A new Scribe instance configured for a HAVING clause.
   */
  public static Scribe asHaving() {
    Scribe newScribe = new Scribe(null);
    newScribe.isHaving = true;
    return newScribe;
  }

  /**
   * @deprecated
   * This method is deprecated in favor asThrough {@link #asThrough(System.Type)} to align with
   * the declaration patterns of `ApexBlueprint` (my other OSS) and provide
   * a more intuitive developer experience (DX).
   * * * This method is maintained for backward compatibility but may be removed
   * in a future version.
   *
   * Creates a Scribe instance for a many-to-many relationship traversal.
   * Example: `.through(Scribe.asThrough(JunctionObject.getSObjectType(), 'TargetObject__c'))`
   *
   * @param junctionSObjectType The SObjectType of the junction object.
   * @param relatedKey The API name of the lookup/master-detail field on the junction object that points to the final target object.
   * @return A new Scribe instance configured for a many-to-many relationship.
   */
  public static Scribe asThrough(Schema.SObjectType junctionSObjectType, String relatedKey) {
    Scribe newScribe = new Scribe(null);
    newScribe.isThrough = true;
    newScribe.junctionSObjectType = junctionSObjectType;
    newScribe.parentRelationIdFieldName = relatedKey;

    return newScribe;
  }

  /**
   * Creates a Scribe instance configured for a many-to-many relationship traversal.
   * This method defines how to bridge to a target object through a junction object.
   *
   * Example:
   * .through(Scribe.asThrough(OrderItem.class, 'Product2Id'))
   *
   * @param junctionType The Class type of the junction SObject (e.g., OrderItem.class).
   * @param targetLookupField The API name of the field on the junction object that points to the final related object (e.g., 'Product2Id').
   * @return A new Scribe instance tailored for junction object traversal.
   */
  public static Scribe asThrough(System.Type junctionType, String targetLookupField) {
    String method = 'asThrough(System.Type junctionType, String targetLookupField)';
    if (junctionType == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'junctionType', null).build();
    }

    if (String.isBlank(targetLookupField)) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'targetLookupField', targetLookupField).build();
    }

    Object instance = junctionType.newInstance();
    if (!(instance instanceof SObject)) {
      String reason = junctionType.getName() + ' is not an SObject type.';
      String action = 'Ensure you are passing a valid SObject class (e.g., JunctionObject__c.class).';
      throw ApexEloquentException.invalidArgument(
          CLASS_NAME,
          method,
          reason,
          action,
          'junctionType',
          junctionType.getName()
        )
        .build();
    }

    Schema.SObjectType junctionSObjectType = ((SObject) instance).getSObjectType();
    Scribe newScribe = new Scribe(null);
    newScribe.isThrough = true;
    newScribe.junctionSObjectType = junctionSObjectType;
    newScribe.parentRelationIdFieldName = targetLookupField;
    return newScribe;
  }

  // =================================================================================================================
  // Public Helper Methods
  // =================================================================================================================

  /**
   * Checks if the current Scribe instance is configured for an aggregate query.
   *
   * @return True if aggregate or group-by clauses have been added, false otherwise.
   */
  public Boolean isAggregate() {
    return !this.aggregateClauses.isEmpty() || !this.groupByClauses.isEmpty();
  }

  /**
   * Builds a FieldStructure object representing the fields and aliases of an aggregate query result.
   *
   * This is used by MockEntry to validate mocked aggregate data.
   * @return A FieldStructure instance for the aggregate query.
   */
  public FieldStructure buildAggregateFieldStructure() {
    List<String> flattenedFieldStructure = this.buildFieldStructure().getAllFieldsAsFlatten();
    for (String alias : this.aggregateAliasMap.keySet()) {
      flattenedFieldStructure.add(alias.toLowerCase());
    }
    return new FieldStructure(flattenedFieldStructure);
  }

  // =================================================================================================================
  // SELECT Clause Methods
  // =================================================================================================================

  /**
   * Adds a single field to the SELECT clause.
   *
   * @param fieldName The API name of the field to select.
   * @return A new, immutable Scribe instance with the added field.
   */
  public Scribe field(String fieldName) {
    String method = 'field(String fieldName)';
    ApexEloquentException validationError = this.validateAddFieldClause();
    if (validationError != null) {
      validationError.method(method).fire();
    }

    if (fieldName == null || String.isBlank(fieldName)) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'fieldName', null).build();
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.selectFields.add(fieldName);

    return clonedScribe;
  }

  /**
   * Adds multiple fields to the SELECT clause from a list.
   *
   * @param fieldNames A list of field API names to select.
   * @return A new, immutable Scribe instance with the added fields.
   */
  public Scribe fields(List<String> fieldNames) {
    String method = 'fields(List<String> fieldNames)';
    ApexEloquentException validationError = this.validateAddFieldClause();
    if (validationError != null) {
      validationError.method(method).fire();
    }

    if (fieldNames == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'fieldNames', null).build();
    }

    Scribe clonedScribe = this.deepClone();
    if (fieldNames.isEmpty()) {
      return clonedScribe;
    }

    clonedScribe.selectFields.addAll(new Set<String>(fieldNames));
    return clonedScribe;
  }

  /**
   * Selects all fields of the source SObject.
   * Note: This is generally discouraged as a best practice, but provided for convenience.
   *
   * @return A new, immutable Scribe instance configured to select all fields.
   */
  public Scribe allFields() {
    String method = 'allFields()';
    ApexEloquentException validationError = this.validateAddFieldClause();
    if (validationError != null) {
      validationError.method(method).fire();
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.isSelectAll = true;

    return clonedScribe;
  }

  // =================================================================================================================
  // Aggregate Methods
  // =================================================================================================================

  /**
   * Adds an AVG() aggregate function to the query.
   *
   * @param fieldName The numeric field to average.
   * @param alias The alias for the result.
   * @return A new, immutable Scribe instance with the aggregate function.
   */
  public Scribe average(String fieldName, String alias) {
    String method = 'average(String fieldName, String alias)';
    this.validateAggregateClauseParams(method, fieldName, alias);
    this.validateAddAggregateClause(method);

    IAggregateClause averageClause = new AverageClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(averageClause);

    return clonedScribe;
  }

  /**
   * Adds a COUNT() aggregate function to the query.
   *
   * @param fieldName The field to count.
   * @param alias The alias for the result.
   * @return A new, immutable Scribe instance with the aggregate function.
   */
  public Scribe count(String fieldName, String alias) {
    String method = 'count(String fieldName, String alias)';
    this.validateAggregateClauseParams(method, fieldName, alias);
    this.validateAddAggregateClause(method);

    IAggregateClause countClause = new CountClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(countClause);

    return clonedScribe;
  }

  /**
   * Adds a COUNT_DISTINCT() aggregate function to the query.
   *
   * @param fieldName The field to count distinct values of.
   * @param alias The alias for the result.
   * @return A new, immutable Scribe instance with the aggregate function.
   */
  public Scribe countDistinct(String fieldName, String alias) {
    String method = 'countDistinct(String fieldName, String alias)';
    this.validateAggregateClauseParams(method, fieldName, alias);
    this.validateAddAggregateClause(method);

    IAggregateClause countDistinctClause = new CountDistinctClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(countDistinctClause);

    return clonedScribe;
  }

  /**
   * Adds a MIN() aggregate function to the query.
   *
   * @param fieldName The field to find the minimum value of.
   * @param alias The alias for the result.
   * @return A new, immutable Scribe instance with the aggregate function.
   */
  public Scribe min(String fieldName, String alias) {
    String method = 'min(String fieldName, String alias)';
    this.validateAggregateClauseParams(method, fieldName, alias);
    this.validateAddAggregateClause(method);

    IAggregateClause minClause = new MinClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(minClause);

    return clonedScribe;
  }

  /**
   * Adds a MAX() aggregate function to the query.
   *
   * @param fieldName The field to find the maximum value of.
   * @param alias The alias for the result.
   * @return A new, immutable Scribe instance with the aggregate function.
   */
  public Scribe max(String fieldName, String alias) {
    String method = 'max(String fieldName, String alias)';
    this.validateAggregateClauseParams(method, fieldName, alias);
    this.validateAddAggregateClause(method);

    IAggregateClause maxClause = new MaxClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(maxClause);

    return clonedScribe;
  }

  /**
   * Adds a SUM() aggregate function to the query.
   *
   * @param fieldName The numeric field to sum.
   * @param alias The alias for the result.
   * @return A new, immutable Scribe instance with the aggregate function.
   */
  public Scribe sum(String fieldName, String alias) {
    String method = 'sum(String fieldName, String alias)';
    this.validateAggregateClauseParams(method, fieldName, alias);
    this.validateAddAggregateClause(method);

    IAggregateClause sumClause = new SumClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(sumClause);

    return clonedScribe;
  }

  /**
   * Adds a single field to the GROUP BY clause.
   *
   * @param fieldName The API name of the field to group by.
   * @return A new, immutable Scribe instance with the GROUP BY field.
   */
  public Scribe groupByField(String fieldName) {
    String method = 'groupByField(String fieldName)';
    this.validateAddAggregateClause(method);
    if (fieldName == null || String.isBlank(fieldName)) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'fieldName', fieldName).build();
    }

    if (!this.children.isEmpty()) {
      String error = 'SOQL Aggregate Restriction';
      String reason = 'Aggregate functions and child relationship queries (withChildren) are incompatible in a single SOQL statement.';
      String action = 'Remove the withChildren() calls, or separate the aggregate and child queries.';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    Scribe clonedScribe = this.deepClone();
    GroupByClause groupByClause = new GroupByClause(fieldName);
    clonedScribe.groupByClauses.add(groupByClause);

    return clonedScribe;
  }

  /**
   * Adds multiple fields to the GROUP BY clause from a list.
   *
   * @param fieldNames A list of field API names to group by.
   * @return A new, immutable Scribe instance with the GROUP BY fields.
   */
  public Scribe groupByFields(List<String> fieldNames) {
    String method = 'groupByFields(List<String> fieldNames)';
    this.validateAddAggregateClause(method);
    if (fieldNames == null || fieldNames.isEmpty()) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'fieldNames', fieldNames).build();
    }

    Scribe clonedScribe = this.deepClone();
    for (String fieldName : fieldNames) {
      if (fieldName == null || String.isBlank(fieldName)) {
        String reason = 'string value in fieldnames argument must not be null or blank.';
        String action = 'Ensure all field names in the list are not null or blank.';
        throw ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'fieldNames', fieldNames)
          .build();
      }
      GroupByClause groupByClause = new GroupByClause(fieldName);
      clonedScribe.groupByClauses.add(groupByClause);
    }

    return clonedScribe;
  }

  /**
   * Adds a parent relationship field to the GROUP BY clause.
   * Example: `.groupByParent(Scribe.asParent('parentIdField').groupByField('Id'));`
   *
   * @param parentScribe A Scribe instance created with `Scribe.asParent()` and configured with `groupByField()`.
   * @return A new, immutable Scribe instance with the parent GROUP BY field.
   */
  public Scribe groupByParent(Scribe parentScribe) {
    String method = 'groupByParent(Scribe parentScribe)';

    this.validateAddAggregateClause(method);
    if (parentScribe == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'parentScribe', null).build();
    }
    if (!parentScribe.isParent) {
      String error = 'Contextual Violation: groupByParent() Forbidden';
      String reason = 'Currently not within a parent context. The groupByParent() method is only permitted in parent context.';
      String action = 'Ensure you are passing a Scribe instance created with Scribe.asParent()';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    Scribe clonedScribe = this.deepClone();
    GroupByClause groupByClause = new GroupByClause(
      new ParentScribe(parentScribe.parentRelationIdFieldName, parentScribe)
    );
    clonedScribe.groupByClauses.add(groupByClause);

    return clonedScribe;
  }

  /**
   * Adds a HAVING clause to the aggregate query. Must be used with a GROUP BY clause.
   *
   * @param havingScribe A Scribe instance created with `Scribe.asHaving()` and configured with WHERE conditions on aggregate aliases.
   * @return A new, immutable Scribe instance with the HAVING clause.
   */
  public Scribe havingCondition(Scribe havingScribe) {
    String method = 'havingCondition(Scribe havingScribe)';
    if (havingScribe == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'havingScribe', null).build();
    }
    if (this.groupByClauses.isEmpty()) {
      String error = 'Missing Required Clause: GROUP BY';
      String reason = 'The HAVING clause requires a GROUP BY clause. The current query does not have any GROUP BY fields defined.';
      String action = 'Please add a .groupBy() or .groupByParent() method call before invoking .havingCondition().';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }
    if (!havingScribe.isHaving) {
      String reason = 'The provided Scribe instance was not initialized asHaving()';
      String action = 'Please create the input Scribe instance using asHaving()';
      throw ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'havingScribe', havingScribe)
        .build();
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.havingScribe = havingScribe;

    return clonedScribe;
  }

  // =================================================================================================================
  // OR Condition Methods
  // =================================================================================================================

  /**
   * Specifies that the next WHERE condition should be joined with an OR operator.
   *
   * Subsequent conditions must also be OR unless grouped.
   *
   * When no condition exists yet, this is a no-op: with ignoreWhen() dynamically
   * retracting conditions, "A OR B where A may vanish" is a legitimate chain, and
   * the surviving condition simply becomes the first (plain) condition:
   *   scribe.whereIn('X', a).ignoreWhen(a.isEmpty())
   *         .orCondition()
   *         .whereIn('Y', b).ignoreWhen(b.isEmpty())
   *
   * @return A new, immutable Scribe instance configured for an OR condition.
   */
  public Scribe orCondition() {
    String method = 'orCondition()';
    this.validateOrConditionNotAllowed(method);

    Scribe clonedScribe = this.deepClone();

    // No condition to attach to (either never added, or retracted by ignoreWhen):
    // do not raise the OR marker — the next condition starts the WHERE clause.
    if (clonedScribe.conditionParts.isEmpty() && !clonedScribe.isParent) {
      return clonedScribe;
    }
    clonedScribe.isNextConditionOr = true;
    clonedScribe.canOnlyAddOrCondition = true;

    return clonedScribe;
  }

  /**
   * Drops the immediately-preceding WHERE condition when `shouldIgnore` is true.
   *
   * Must be chained DIRECTLY onto a where...() call. Handy for building dynamic queries
   * from optional inputs (e.g. search filters from an LWC):
   *   scribe.whereIn('Id', ids).ignoreWhen(ids.isEmpty())
   *   scribe.whereLike('Name', keyword).ignoreWhen(String.isBlank(keyword))
   *
   * When `shouldIgnore` is false, the condition is kept (query unchanged). When true, the
   * preceding condition is removed — this also avoids the empty `IN ()` pitfall, which would
   * otherwise match zero rows.
   *
   * If it is NOT chained immediately after a where...() (e.g. called first, after orderBy(),
   * or twice in a row), an ApexEloquentException is thrown so the relationship between
   * ignoreWhen() and its target condition stays unambiguous.
   *
   * @param shouldIgnore when true, the immediately-preceding WHERE condition is removed.
   * @return A new, immutable Scribe instance.
   */
  public Scribe ignoreWhen(Boolean shouldIgnore) {
    String method = 'ignoreWhen(Boolean shouldIgnore)';
    if (this.isAfterWhereClause != true) {
      String error = 'Invalid ignoreWhen() placement';
      String reason = 'ignoreWhen() can only be chained immediately after a where...() condition.';
      String action = 'Chain it directly onto a where...() call, e.g. whereIn(\'Id\', ids).ignoreWhen(ids.isEmpty()).';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    // deepClone() does not copy isAfterWhereClause, so the result resets to false
    // (a second ignoreWhen() in a row will therefore throw).
    Scribe clonedScribe = this.deepClone();
    if (shouldIgnore == true) {
      clonedScribe.conditionParts.remove(clonedScribe.conditionParts.size() - 1);
      // Recompute the OR-only mode from the remaining parts: when the retracted
      // condition was the only OR, the chain must accept plain (AND) conditions
      // again — otherwise the OR marker would outlive its retracted target.
      Boolean hasOrPart = false;
      for (ConditionPart part : clonedScribe.conditionParts) {
        if (part.isOr == true) {
          hasOrPart = true;
          break;
        }
      }
      clonedScribe.canOnlyAddOrCondition = hasOrPart;
    }

    return clonedScribe;
  }

  // =================================================================================================================
  // WHERE Clause Methods
  // =================================================================================================================

  /**
   * Adds an equality (=) or IS NULL condition to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param value The value to compare against. If null, becomes an IS NULL clause.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereEqual(String fieldName, Object value) {
    String method = 'whereEqual(String fieldName, Object value)';
    this.validateConditionClause(method, fieldName, value);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (value == null) {
      conditionClause = new IsNullConditionClause(clonedScribe.sObjectType, null, fieldName);
    } else {
      conditionClause = new EqualConditionClause(clonedScribe.sObjectType, null, fieldName, value);
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds an inequality (!=) or IS NOT NULL condition to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param value The value to compare against. If null, becomes an IS NOT NULL clause.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereNotEqual(String fieldName, Object value) {
    String method = 'whereNotEqual(String fieldName, Object value)';
    this.validateConditionClause(method, fieldName, value);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (value == null) {
      conditionClause = new IsNotNullConditionClause(clonedScribe.sObjectType, null, fieldName);
    } else {
      conditionClause = new NotEqualConditionClause(clonedScribe.sObjectType, null, fieldName, value);
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds a greater than (>) condition to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param value The value to compare against.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereGreaterThan(String fieldName, Object value) {
    String method = 'whereGreaterThan(String fieldName, Object value)';
    this.validateConditionClause(method, fieldName, value);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (value == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new GreaterThanConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        value
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds a greater than or equal (>=) condition to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param value The value to compare against.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereGreaterThanOrEqual(String fieldName, Object value) {
    String method = 'whereGreaterThanOrEqual(String fieldName, Object value)';
    this.validateConditionClause(method, fieldName, value);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (value == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new GreaterThanOrEqualConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        value
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds a less than (<) condition to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param value The value to compare against.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereLessThan(String fieldName, Object value) {
    String method = 'whereLessThan(String fieldName, Object value)';
    this.validateConditionClause(method, fieldName, value);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (value == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new LessThanConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        value
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds a less than or equal (<=) condition to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param value The value to compare against.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereLessThanOrEqual(String fieldName, Object value) {
    String method = 'whereLessThanOrEqual(String fieldName, Object value)';
    this.validateConditionClause(method, fieldName, value);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (value == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new LessThanOrEqualConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        value
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds a LIKE condition to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param value The string value to compare against, including wildcards (%).
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereLike(String fieldName, String value) {
    String method = 'whereLike(String fieldName, String value)';
    this.validateConditionClause(method, fieldName, value);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (value == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new LikeConditionClause(clonedScribe.sObjectType, null, fieldName, value);
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds a NOT LIKE condition to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param value The string value to compare against, including wildcards (%).
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereNotLike(String fieldName, String value) {
    String method = 'whereNotLike(String fieldName, String value)';
    this.validateConditionClause(method, fieldName, value);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (value == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new NotLikeConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        value
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds an IN condition to the WHERE clause.
   *
   * Handles empty lists gracefully by creating a logically impossible condition.
   * @param fieldName The field to filter on.
   * @param values A List or Set of values to include.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereIn(String fieldName, Object values) {
    String method = 'whereIn(String fieldName, Object values)';
    this.validateConditionClause(method, fieldName, values);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (values == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new InConditionClause(clonedScribe.sObjectType, null, fieldName, values);
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds an IN condition with a subquery to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param subQuery A Scribe instance representing the subquery.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereIn(String fieldName, Scribe subQuery) {
    String method = 'whereIn(String fieldName, Scribe subQuery)';
    this.validateConditionClause(method, fieldName, subQuery);

    Scribe clonedScribe = this.deepClone();
    if (clonedScribe.isNextConditionOr) {
      String error = 'SOQL Semi-Join Restriction';
      String reason =
        'The ' +
        method +
        ' method cannot be combined with an OR operator due to Salesforce SOQL limitations.';
      String action = 'Remove the preceding .orCondition() to use a default AND condition, or use whereIn(fieldName, List<Object>) instead of a subquery.';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    IConditionClause conditionClause;
    if (subQuery == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new InSubQueryConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        subQuery
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds a NOT IN condition to the WHERE clause.
   *
   * Handles empty lists gracefully by ignoring the condition.
   * @param fieldName The field to filter on.
   * @param values A List or Set of values to exclude.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereNotIn(String fieldName, Object values) {
    String method = 'whereNotIn(String fieldName, Object values)';
    this.validateConditionClause(method, fieldName, values);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (values == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new NotInConditionClause(clonedScribe.sObjectType, null, fieldName, values);
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds a NOT IN condition with a subquery to the WHERE clause.
   *
   * @param fieldName The field to filter on.
   * @param subQuery A Scribe instance representing the subquery.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereNotIn(String fieldName, Scribe subQuery) {
    String method = 'whereNotIn(String fieldName, Scribe subQuery)';
    this.validateConditionClause(method, fieldName, subQuery);

    Scribe clonedScribe = this.deepClone();
    if (clonedScribe.isNextConditionOr) {
      String error = 'SOQL Semi-Join Restriction';
      String reason =
        'The ' +
        method +
        ' method cannot be combined with an OR operator due to Salesforce SOQL limitations.';
      String action = 'Remove the preceding .orCondition() to use a default AND condition, or use whereIn(fieldName, List<Object>) instead of a subquery.';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    IConditionClause conditionClause;
    if (subQuery == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new NotInSubQueryConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        subQuery
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds an INCLUDES condition to the WHERE clause for multi-select picklists.
   *
   * @param fieldName The multi-select picklist field to filter on.
   * @param values A list of values to include.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereIncludes(String fieldName, List<String> values) {
    String method = 'whereIncludes(String fieldName, List<String> values)';
    this.validateConditionClause(method, fieldName, values);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (values == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new IncludesConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        values
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds an EXCLUDES condition to the WHERE clause for multi-select picklists.
   *
   * @param fieldName The multi-select picklist field to filter on.
   * @param values A list of values to exclude.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereExcludes(String fieldName, List<String> values) {
    String method = 'whereExcludes(String fieldName, List<String> values)';
    this.validateConditionClause(method, fieldName, values);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause;
    if (values == null) {
      // null at chain time: defer the error to build time so a following
      // ignoreWhen() can retract the condition first (issue #71)
      conditionClause = new InvalidConditionClause(method, fieldName);
    } else {
      conditionClause = new ExcludeConditionClause(
        clonedScribe.sObjectType,
        null,
        fieldName,
        values
      );
    }
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds an IS NULL condition to the WHERE clause.
   *
   * @param fieldName The field to check for null.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereNull(String fieldName) {
    String method = 'whereNull(String fieldName)';
    this.validateConditionClause(method, fieldName, null);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new IsNullConditionClause(clonedScribe.sObjectType, null, fieldName);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Adds an IS NOT NULL condition to the WHERE clause.
   *
   * @param fieldName The field to check for non-null.
   * @return A new, immutable Scribe instance with the WHERE condition.
   */
  public Scribe whereNotNull(String fieldName) {
    String method = 'whereNotNull(String fieldName)';
    this.validateConditionClause(method, fieldName, null);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new IsNotNullConditionClause(clonedScribe.sObjectType, null, fieldName);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Builds a FieldStructure object representing the fields selected in this Scribe instance.
   * This is used by MockEntry to validate mocked data.
   * @return A FieldStructure instance representing the query shape.
   */
  public FieldStructure buildFieldStructure() {
    Map<String, Schema.SObjectField> fieldMap = this.describe.fields.getMap();

    Map<String, FieldStructure> relationFieldStructures = new Map<String, FieldStructure>();
    if (!this.parents.isEmpty()) {
      for (ParentScribe parent : this.parents) {
        String parentFieldName = parent.getRelationFieldName().toLowerCase();
        FieldStructure parentFieldStructure = parent.buildFieldStructure(fieldMap);
        relationFieldStructures.put(parentFieldName, parentFieldStructure);
      }
    }

    if (!this.children.isEmpty()) {
      for (Scribe child : this.children) {
        String childObjectname = String.isBlank(child.relationName)
          ? child.getDescribe().getName().toLowerCase()
          : child.relationName.toLowerCase();
        FieldStructure childFieldStructure = child.buildFieldStructure();
        relationFieldStructures.put(childObjectname, childFieldStructure);
      }
    }

    List<String> selectedFields = this.getSelectedFields(fieldMap);
    return new FieldStructure(selectedFields, relationFieldStructures);
  }

  // =================================================================================================================
  // Grouping Methods
  // =================================================================================================================

  /**
   * Groups multiple WHERE conditions using parentheses.
   *
   * @param groupScribe A Scribe instance created with `Scribe.asGroup()` and configured with WHERE conditions.
   * @return A new, immutable Scribe instance with the grouped condition.
   */
  public Scribe whereGroup(Scribe groupScribe) {
    String method = 'whereGroup(Scribe groupScribe)';
    this.validateConditionOperator(method, null, null);

    if (groupScribe == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'groupScribe', null).build();
    }

    Scribe clonedScribe = this.deepClone();
    ConditionPart groupConditionPart = new ConditionPart(groupScribe, this.isNextConditionOr);
    clonedScribe.sObjectType = this.sObjectType;
    clonedScribe.conditionParts.add(groupConditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  // =================================================================================================================
  // Relationship Methods
  // =================================================================================================================

  /**
   * Explicitly sets the child relationship name for a child subquery.
   * This is required when there are multiple relationships between the parent and child objects.
   * Example: `.withChildren(Scribe.asChild(Opportunity.getSObjectType()).relationName('Opportunities').field('Id'))`
   *
   * @param relationName The exact child relationship name (e.g., 'Opportunities').
   * @return A new, immutable Scribe instance with the relationship name set.
   */
  public Scribe relationName(String relationName) {
    String method = 'relationName(String relationName)';
    if (String.isBlank(relationName)) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'relationName', relationName).build();
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.relationName = relationName;

    return clonedScribe;
  }

  /**
   * Adds a child subquery.
   *
   * @param childScribe A Scribe instance created with `Scribe.asChild()`.
   * @return A new, immutable Scribe instance with the child subquery.
   */
  public Scribe withChildren(Scribe childScribe) {
    String method = 'withChildren(Scribe childScribe)';
    this.validateOrConditionNotAllowed(method);

    if (childScribe == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'childScribe', null).build();
    }

    if (!this.groupByClauses.isEmpty() || !this.aggregateClauses.isEmpty()) {
      String error = 'SOQL Aggregate Restriction';
      String reason = 'Aggregate functions and child relationship queries (withChildren) are incompatible in a single SOQL statement.';
      String action = 'Remove the withChildren() calls, or separate the aggregate and child queries.';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    if (!childScribe.isChild) {
      String error = 'Invalid Scribe Context';
      String reason = 'The Scribe instance passed to withChildren() must be initialized using the Scribe.asChild() method.';
      String action = 'Initialize the child query using `Scribe.asChild(System.Type childRecordType)` and pass it to withChildren().';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.children.add(childScribe);

    return clonedScribe;
  }

  /**
   * Adds a condition on a parent relationship field.
   *
   * @param parentScribe A Scribe instance created with `Scribe.asParent()` and configured with WHERE conditions.
   * @return A new, immutable Scribe instance with the parent condition.
   */
  public Scribe parentCondition(Scribe parentScribe) {
    String method = 'parentCondition(Scribe parentScribe)';
    this.validateOrConditionNotAllowed(method);

    if (parentScribe == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'parentScribe', null).build();
    }

    if (!parentScribe.isParent) {
      String error = 'Invalid Scribe Context';
      String reason = 'The Scribe instance passed to parentField() must be initialized using the Scribe.asParent() method.';
      String action = 'Initialize the parent Scribe using `Scribe.asChild(System.Type childRecordType)` and pass it to withParent().';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    Scribe clonedScribe = this.deepClone();
    ConditionPart parentConditionPart = new ConditionPart(
      new ParentScribe(parentScribe.parentRelationIdFieldName, parentScribe)
    );
    clonedScribe.conditionParts.add(parentConditionPart);
    clonedScribe.isNextConditionOr = false;
    clonedScribe.isAfterWhereClause = true;

    return clonedScribe;
  }

  /**
   * Selects fields from a parent relationship.
   *
   * @param parentScribe A Scribe instance created with `Scribe.asParent()` and configured with fields to select.
   * @return A new, immutable Scribe instance with the parent fields in the SELECT clause.
   */
  public Scribe parentField(Scribe parentScribe) {
    String method = 'parentField(Scribe parentScribe)';
    this.validateOrConditionNotAllowed(method);

    if (parentScribe == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'parentScribe', null).build();
    }

    if (!parentScribe.isParent) {
      String error = 'Invalid Scribe Context';
      String reason = 'The Scribe instance passed to parentField() must be initialized using the Scribe.asParent() method.';
      String action = 'Initialize the parent Scribe using `Scribe.asChild(System.Type childRecordType)` and pass it to withParent().';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.parents.add(new ParentScribe(parentScribe.parentRelationIdFieldName, parentScribe));

    return clonedScribe;
  }

  /**
   * Eager loads a many-to-many relationship by traversing through a junction object.
   * This is an abstraction over a `withChildren` subquery on a junction object that includes `parentField` and `parentCondition`.
   * Example: `.through(Scribe.asThrough(JunctionSObjectType, 'relationIdField').field(...).whereEqual(...))`
   *
   * @param throughScribe The Scribe instance defining the junction object and the final target, created via `Scribe.asThrough()`.
   * @return The Scribe instance for method chaining.
   */
  public Scribe through(Scribe throughScribe) {
    String method = 'through(Scribe throughScribe)';
    if (throughScribe == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'throughScribe', null).build();
    }
    if (!throughScribe.isThrough) {
      String error = 'Invalid Scribe Context';
      String reason = 'The Scribe instance passed to through() must be initialized using the Scribe.asThrough() method.';
      String action = 'Initialize the through Scribe using `asThrough(System.Type junctionType, String targetLookupField)` and pass it to through().';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }
    throughScribe.isParent = true;
    Scribe childScribe = Scribe.asChild(throughScribe.junctionSObjectType)
      .field(throughScribe.parentRelationIdFieldName)
      .parentField(throughScribe)
      .parentCondition(throughScribe);
    if (String.isNotBlank(throughScribe.relationName)) {
      childScribe = childScribe.relationName(throughScribe.relationName);
    }
    Scribe clonedScribe = this.deepClone();
    clonedScribe = clonedScribe.withChildren(childScribe);

    return clonedScribe;
  }

  // =================================================================================================================
  // Other Clause Methods
  // =================================================================================================================

  /**
   * Adds a LIMIT clause to the query.
   *
   * @param limitNumber The maximum number of records to return.
   * @return A new, immutable Scribe instance with the LIMIT clause.
   */
  public Scribe take(Integer limitNumber) {
    String method = 'take(Integer limitNumber)';
    if (limitNumber == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'limitNumber', limitNumber).build();
    }
    if (limitNumber < 0) {
      String reason = 'The limit number cannot be negative.';
      String action = 'Please provide a non-negative integer for the limit.';
      throw ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'limitNumber', limitNumber)
        .build();
    }
    Scribe clonedScribe = this.deepClone();
    clonedScribe.limitNumber = limitNumber;

    return clonedScribe;
  }

  /**
   * Adds an OFFSET clause to the query.
   *
   * @param offsetNumber The number of records to skip.
   * @return A new, immutable Scribe instance with the OFFSET clause.
   */
  public Scribe offset(Integer offsetNumber) {
    String method = 'offset(Integer offsetNumber)';
    if (offsetNumber == null) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'offsetNumber', offsetNumber).build();
    }
    if (offsetNumber < 0) {
      String reason = 'The offset number cannot be negative.';
      String action = 'Please provide a non-negative integer for the offset.';
      throw ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'offsetNumber', offsetNumber)
        .build();
    }

    if (offsetNumber > 2000) {
      String reason = 'Salesforce SOQL has a maximum offset limit of 2000 records.';
      String action = 'Please provide an offset number less than or equal to 2000';
      throw ApexEloquentException.invalidArgument(CLASS_NAME, method, reason, action, 'offsetNumber', offsetNumber)
        .build();
    }
    Scribe clonedScribe = this.deepClone();
    clonedScribe.offsetNumber = offsetNumber;

    return clonedScribe;
  }

  /**
   * Adds a FOR UPDATE clause to the query.
   *
   * @return A new, immutable Scribe instance with the FOR UPDATE clause.
   */
  public Scribe forUpdate() {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.isForUpdate = true;
    return clonedScribe;
  }

  /**
   * Adds an ORDER BY clause to the query (defaults to ASC).
   *
   * @param field The field to order by.
   * @return A new, immutable Scribe instance with the ORDER BY clause.
   */
  public Scribe orderBy(String field) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClauses.add(new Scribe.OrderByClause(field));
    return clonedScribe;
  }

  /**
   * Adds an ORDER BY clause to the query.
   *
   * @param field The field to order by.
   * @param order The direction ('ASC' or 'DESC').
   * @return A new, immutable Scribe instance with the ORDER BY clause.
   */
  public Scribe orderBy(String field, String order) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClauses.add(new Scribe.OrderByClause(field, order));
    return clonedScribe;
  }

  /**
   * Adds an ORDER BY clause with nulls ordering to the query.
   *
   * @param field The field to order by.
   * @param order The direction ('ASC' or 'DESC').
   * @param nullsOperator The nulls ordering ('FIRST' or 'LAST').
   * @return A new, immutable Scribe instance with the ORDER BY clause.
   */
  public Scribe orderBy(String field, String order, String nullsOperator) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClauses.add(new Scribe.OrderByClause(field, order, nullsOperator));
    return clonedScribe;
  }

  // =================================================================================================================
  // Build Methods
  // =================================================================================================================

  /**
   * Asserts that this query carries the expected condition, failing the test when it
   * does not. Pair it with `MockEloquent.scribeAt(label)` to fix, in a unit test, that a
   * Usecase used the input it was handed — the defect this exists for is a query that
   * ignores its input entirely and touches every matching record in the org, which no
   * amount of mocked data can reveal.
   *
   * This checks that the condition is PRESENT, not that the query is thereby narrowed: a
   * condition joined with `orCondition()` satisfies it, even though an OR can widen the
   * query back to everything. Assert the absence of the widening condition as well when
   * that matters.
   *
   * ```
   * mock.scribeAt('fetch')
   *   .assertCondition(new InConditionClause('Id', contactIds))
   *   .assertCondition(new EqualConditionClause(Account.class, 'Status__c', 'Active'));
   * ```
   *
   * Which conditions are searched is decided by the expected clause itself: one built
   * without an SObject type (the two-argument constructors) is matched against the
   * queried object — top-level conditions and those inside `whereGroup` — while one
   * built with a type is matched against every nested scribe for that object, so a
   * `parentCondition` or a `withChildren` subquery can be named directly.
   *
   * When naming the object is not enough to say where — a self-referencing parent, or two
   * subqueries over the same object — this refuses to guess: it throws and lists the paths
   * involved, so use `assertConditionAt(path, ...)` to name one. It never quietly passes
   * on the wrong one.
   *
   * HAVING conditions are never searched: their field name is an aggregate alias, not a
   * field, so matching them here would compare unrelated things.
   *
   * Matching is by the kind of condition, its field, and the SOQL it renders as, with the
   * expected clause built from the same metadata as the recorded one — so a change to how
   * conditions render moves both sides together, and two different conditions that happen
   * to render alike stay distinct.
   *
   * Collection values keep the semantics of the container they were given in: a Set is
   * sorted (it has no order), a List is compared in the order it was written. Expect the
   * same container kind the production code passes, or the two will not line up.
   *
   * An empty collection is a normal expectation: `ignoreWhen(ids.isEmpty())` removes the
   * condition from the query outright, so `assertNoCondition(new InConditionClause('Id',
   * ids))` is how both sides of that branch are fixed. Such a condition renders as
   * degenerate SOQL (an empty `IN` becomes `<field> = null`, an empty `NOT IN` becomes
   * nothing), which is precisely why the kind and the field are part of the key: text
   * alone would let those collapse into one another.
   *
   * A failure raises System.AssertException, which Apex does not allow to be caught
   * (measured on API v67.0). That is deliberate: a test wrapping its Act in
   * `catch (Exception e)` cannot swallow the assertion and go green. Use `hasCondition`
   * when a Boolean is what you want.
   *
   * The field name is checked against the object being searched. A misspelling would
   * otherwise render as tidy SOQL and simply match nothing, which fails loudly here but
   * would let `assertNoCondition` pass for ever — including after the code under test
   * starts filtering on the field the test meant to guard.
   *
   * @param expected The condition the query is expected to carry.
   * @return This Scribe, so assertions can be chained.
   * @throws ApexEloquentException when the expected condition names a field the searched
   *         object does not have.
   */
  @TestVisible
  private Scribe assertCondition(IConditionClause expected) {
    ConditionMatch match = this.findCondition(expected, null, false);
    Assert.isTrue(match.found, this.describeAssertionFailure(expected, match, true));
    return this;
  }

  /**
   * Reports whether this query carries the given condition, using the same search rules
   * as `assertCondition`. Use it when a test needs its own message, or needs to accept
   * one of several shapes; `assertCondition` is the shorter form for the usual case.
   *
   * @param expected The condition to look for.
   * @return True when the query carries it.
   * @throws ApexEloquentException when the expected condition names a field the searched
   *         object does not have.
   */
  @TestVisible
  private Boolean hasCondition(IConditionClause expected) {
    return this.findCondition(expected, null, false).found;
  }

  /**
   * Asserts that the part of this query reached by `path` carries the expected condition.
   * Use it when naming the object is not enough to say where — a self-referencing parent
   * (`Account` filtered by `ParentId`, itself an Account), a parent two hops up, or two
   * subqueries over the same object. `assertCondition` refuses to guess in those cases,
   * and its message lists the paths to choose from.
   *
   * A path is the chain of hops from the queried object, written the same way the query
   * was built: a parent hop is the field passed to `Scribe.asParent(...)`, a child hop is
   * the child's relationship name when `relationName(...)` was used, otherwise the child
   * object's name, and a semi-join hop is the field passed to `whereIn(field, Scribe)` or
   * `whereNotIn(field, Scribe)`. `whereGroup` is not a hop — a group filters the same
   * object at the same place.
   *
   * Those three sources share one namespace, so a name can reach two places at once (a
   * lookup field and a semi-join on the same field, say). Both are then searched, and the
   * expectation is read against whichever of them has the field it names; add the object
   * to the expected condition to say which one is meant.
   *
   * ```
   * // Scribe.of(Account.class).parentCondition(Scribe.asParent('ParentId')...)
   * scribe.assertConditionAt('ParentId', new EqualConditionClause('Type', 'X'));
   * scribe.assertConditionAt('ParentId.ParentId', new EqualConditionClause('Type', 'Y'));
   * scribe.assertConditionAt('Contact', new EqualConditionClause('LastName', 'Z'));
   * ```
   *
   * The path already says where to look, so the expected condition is normally built with
   * the short two-argument constructor. Naming an object as well is allowed — it reads as
   * documentation — but the two must agree: an object that the path does not lead to is
   * refused rather than silently ignored.
   *
   * @param path The path to the part of the query being asserted.
   * @param expected The condition it is expected to carry.
   * @return This Scribe, so assertions can be chained.
   * @throws ApexEloquentException when the path reaches no part of this query, when the
   *         expected condition names a field the object at that path does not have, or
   *         when it names a different object than the path leads to.
   */
  @TestVisible
  private Scribe assertConditionAt(String path, IConditionClause expected) {
    ConditionMatch match = this.findCondition(expected, path, true);
    Assert.isTrue(match.found, this.describeAssertionFailure(expected, match, true));
    return this;
  }

  /**
   * Asserts that the part of this query reached by `path` does NOT carry the given
   * condition. Path rules are those of `assertConditionAt`.
   *
   * @param path The path to the part of the query being asserted.
   * @param unexpected The condition it must not carry.
   * @return This Scribe, so assertions can be chained.
   * @throws ApexEloquentException when the path reaches no part of this query, when the
   *         expected condition names a field the object at that path does not have, or
   *         when it names a different object than the path leads to.
   */
  @TestVisible
  private Scribe assertNoConditionAt(String path, IConditionClause unexpected) {
    ConditionMatch match = this.findCondition(unexpected, path, true);
    Assert.isFalse(match.found, this.describeAssertionFailure(unexpected, match, false));
    return this;
  }

  /**
   * Reports whether the part of this query reached by `path` carries the given condition.
   * Path rules are those of `assertConditionAt`.
   *
   * @param path The path to the part of the query being examined.
   * @param expected The condition to look for.
   * @return True when that part of the query carries it.
   * @throws ApexEloquentException when the path reaches no part of this query, when the
   *         expected condition names a field the object at that path does not have, or
   *         when it names a different object than the path leads to.
   */
  @TestVisible
  private Boolean hasConditionAt(String path, IConditionClause expected) {
    return this.findCondition(expected, path, true).found;
  }

  /**
   * Builds the message `assertCondition` / `assertNoCondition` would report for the
   * given expectation. Exposed so the framework's own tests can verify the diagnosis:
   * System.AssertException cannot be caught, so a failing assertion cannot be inspected
   * from inside a test.
   *
   * @param expected The condition the message is about.
   * @param shouldExist True to phrase it as a missing condition, false as a forbidden one.
   * @return The message.
   * @throws ApexEloquentException when the expected condition names a field the searched
   *         object does not have.
   */
  @TestVisible
  private String conditionAssertionMessage(IConditionClause expected, Boolean shouldExist) {
    return this.describeAssertionFailure(expected, this.findCondition(expected, null, false), shouldExist);
  }

  /**
   * Asserts that this query does NOT carry the given condition — the guard for "this
   * filter must never be added", such as a soft-delete flag a Usecase is meant to ignore.
   * Search rules are identical to `assertCondition`.
   *
   * @param unexpected The condition the query must not carry.
   * @return This Scribe, so assertions can be chained.
   * @throws ApexEloquentException when the expected condition names a field the searched
   *         object does not have. A misspelling would otherwise leave this
   *         assertion passing for ever, which is the defect the check exists for.
   */
  @TestVisible
  private Scribe assertNoCondition(IConditionClause unexpected) {
    ConditionMatch match = this.findCondition(unexpected, null, false);
    Assert.isFalse(match.found, this.describeAssertionFailure(unexpected, match, false));
    return this;
  }

  /**
   * Outcome of searching the condition tree: whether the expected clause was found, the
   * SOQL fragment it was compared as, every fragment that was compared against it, and
   * the paths that were in scope — the material the failure message is built from.
   */
  private class ConditionMatch {
    private Boolean found = false;
    private String expectedFragment;
    private String expectedKey;
    private List<String> comparedFragments = new List<String>();
    private List<String> otherObjectHits = new List<String>();
    // Paths whose scribe was searched, so an ambiguous target can name them.
    private List<String> matchedPaths = new List<String>();
    // Every path in the query, so a mistyped path can be answered with the real ones.
    private List<String> allPaths = new List<String>();
  }

  /**
   * Walks the condition tree looking for the expected clause.
   *
   * @param expected The condition to look for.
   * @return The search outcome, including what was compared, for the failure message.
   */
  private ConditionMatch findCondition(IConditionClause expected, String path, Boolean pathGiven) {
    String method = pathGiven
      ? 'assertConditionAt(String path, IConditionClause expected)'
      : 'assertCondition(IConditionClause expected)';
    if (expected == null) {
      ApexEloquentException.required(CLASS_NAME, method, 'expected', null).fire();
    }
    // Build once so nested scribes learn which object they filter before types are
    // compared (toSoql is idempotent). ⚠️ Scribe.deepClone is shallow, so this also rewrites
    // state shared with any Scribe cloned from this one: aggregateAliasMap is reset, nested
    // sObjectType is assigned, and ConditionPart.isOr is recomputed. MockEloquent already
    // calls toSoql on the recorded query, so the values settle the same way.
    this.toSoql();

    Schema.SObjectType targetType = expected instanceof AbstractConditionClause
      ? ((AbstractConditionClause) expected).getSObjectType()
      : null;
    String searchPath = path;
    Boolean searchByPath = pathGiven;
    if (targetType == null && !pathGiven) {
      // Naming no object means the queried object itself, which is one exact place — not a
      // type to look for. Treating it as a type would call a self-referencing parent
      // ambiguous and refuse an assertion that was never ambiguous.
      searchPath = '';
      searchByPath = true;
    }

    ConditionMatch match = new ConditionMatch();
    Schema.SObjectType metaType = targetType;
    List<Schema.SObjectType> pathTypes = this.typesAtPath(searchPath);
    // Whether the objects being searched are known. They are not when a path leads nowhere:
    // the expectation is then read against the root just to render a failure message, and
    // must not be judged as if the root were the target.
    Boolean targetResolved = !pathTypes.isEmpty();
    if (metaType == null) {
      // A parent holding no condition never has its type filled in (ParentScribe returns
      // before assigning it), so the relationship is followed to find it rather than
      // dereferencing null or reporting the expectation in the wrong object's terms.
      metaType = targetResolved ? typeHolding(pathTypes, expected.getFieldName()) : this.sObjectType;
    } else if (searchByPath && targetResolved && !pathTypes.contains(metaType)) {
      // Both a path and an object were named, and they disagree. Silently honouring one
      // would report the expectation in terms of an object the path does not lead to.
      String error = 'Conflicting query target';
      String reason =
        'The path \'' +
        searchPath +
        '\' leads to ' +
        describeTypes(pathTypes) +
        ', but the expected condition names ' +
        metaType.getDescribe().getName() +
        '.';
      String action = 'Drop the object from the condition (the path already says where to look), or correct one of them.';
      ApexEloquentException.at(CLASS_NAME)
        .method('assertConditionAt(String path, IConditionClause expected)')
        .error(error)
        .reason(reason)
        .action(action)
        .param('path', searchPath)
        .fire();
    }
    Map<String, Schema.SObjectField> metaFieldMap = metaType.getDescribe().fields.getMap();
    match.expectedFragment = expected.overrideMetaData(metaType, metaFieldMap).build();
    match.expectedKey = comparisonKey(expected, match.expectedFragment);
    this.collectConditionMatches(targetType, searchByPath ? searchPath : null, '', match);

    if (searchByPath && match.matchedPaths.isEmpty()) {
      String error = 'Unknown query path';
      String reason = 'No part of this query is reached by the path \'' + searchPath + '\'.';
      String action = 'Use one of the paths this query actually has: ' + describePaths(match.allPaths);
      ApexEloquentException.at(CLASS_NAME)
        .method('assertConditionAt(String path, IConditionClause expected)')
        .error(error)
        .reason(reason)
        .action(action)
        .param('path', searchPath)
        .fire();
    }
    if (!searchByPath && match.matchedPaths.size() > 1) {
      // Naming only the object cannot say WHICH of them, and quietly passing on the
      // wrong one is the very failure this feature exists to prevent.
      String error = 'Ambiguous query target';
      String reason =
        '\'' +
        targetType.getDescribe().getName() +
        '\' is filtered at ' +
        match.matchedPaths.size() +
        ' places in this query: ' +
        describePaths(match.matchedPaths) +
        '.';
      String action = 'Name one with assertConditionAt(\'<path>\', ...) instead of passing the object.';
      ApexEloquentException.at(CLASS_NAME)
        .method('assertCondition(IConditionClause expected)')
        .error(error)
        .reason(reason)
        .action(action)
        .param('sObjectType', targetType.getDescribe().getName())
        .fire();
    }
    // Checked last, and only when the condition turned up nowhere at all. A field the
    // searched object lacks can still be a real field of another part of the query, and
    // "the same condition exists elsewhere" is the more useful answer in that case.
    if (targetResolved && !match.found && match.otherObjectHits.isEmpty()) {
      // Naming an object pins the search to it, so the message must name that one. Without
      // one, every object the path reaches was a candidate and all of them are listed.
      List<Schema.SObjectType> searched = targetType == null
        ? pathTypes
        : new List<Schema.SObjectType>{ metaType };
      this.rejectUnknownField(method, expected, searched, metaFieldMap);
    }
    return match;
  }

  /**
   * Refuses an expectation naming a field the target object does not have.
   *
   * A misspelled field still renders as tidy SOQL — `getFieldType` falls back to STRING for
   * anything absent from the describe map — so it simply matches nothing. `assertCondition`
   * fails loudly at that point, but `assertNoCondition` would pass forever, and go on
   * passing after the implementation starts filtering on the field it was meant to guard.
   *
   * Called only once the search has come up empty everywhere. A field the searched object
   * lacks may still belong to another part of the query — an expectation aimed at the
   * queried object when the condition sits on a parent, say — and telling the caller the
   * condition exists elsewhere says more than telling them the field does not exist.
   *
   * Dotted names are left alone: they are the polymorphic and relationship forms
   * (`Queue.Name`, `Account.Type`) that the same describe fallback exists to support.
   *
   * @param method Calling method signature, for the error.
   * @param expected The expected condition.
   * @param candidates The objects that were searched, for the error.
   * @param metaFieldMap The field map of the object the expectation is read against.
   */
  private void rejectUnknownField(
    String method,
    IConditionClause expected,
    List<Schema.SObjectType> candidates,
    Map<String, Schema.SObjectField> metaFieldMap
  ) {
    String fieldName = expected.getFieldName();
    if (String.isBlank(fieldName) || fieldName.contains('.')) {
      return;
    }
    // The map keys are lower-case but containsKey ignores case (measured on API v67.0);
    // lowering keeps the lookup right either way.
    if (metaFieldMap.containsKey(fieldName.toLowerCase())) {
      return;
    }
    String error = 'Unknown field in expected condition';
    String reason = describeTypes(candidates) + ' has no field named \'' + fieldName + '\'.';
    String action = 'Correct the field name — a misspelling would make assertNoCondition pass for ever.';
    ApexEloquentException.at(CLASS_NAME)
      .method(method)
      .error(error)
      .reason(reason)
      .action(action)
      .param('field', fieldName)
      .fire();
  }

  /**
   * Every object filtered at a path.
   *
   * A path normally reaches one place, but hop names come from three sources that share
   * one namespace — a parent's lookup field, a child's relationship name, and a semi-join's
   * field — so the same name can reach two objects in one query. All of them are returned:
   * judging an expectation against only the first would refuse an assertion about the
   * second, which is a place the query really does filter.
   *
   * @param path The dot-separated path from this query.
   * @return The objects at that path, empty when the path leads nowhere.
   */
  private List<Schema.SObjectType> typesAtPath(String path) {
    List<Schema.SObjectType> found = new List<Schema.SObjectType>();
    this.collectTypesAtPath(path, found);
    return found;
  }

  /**
   * Accumulates the objects reached by a path, following the same hops as `scribeAtPath`.
   *
   * @param path The path remaining from this scribe.
   * @param found The accumulating list, deduplicated by object.
   */
  private void collectTypesAtPath(String path, List<Schema.SObjectType> found) {
    if (String.isBlank(path)) {
      addType(found, this.sObjectType);
      return;
    }
    for (ConditionPart part : this.conditionParts) {
      if (part.condition != null) {
        Scribe subQuery = subQueryOf(part.condition);
        if (subQuery == null) {
          continue;
        }
        String hop = part.condition.getFieldName();
        if (path == hop) {
          addType(found, subQuery.sObjectType);
        } else if (path.startsWithIgnoreCase(hop + '.')) {
          subQuery.collectTypesAtPath(path.substring(hop.length() + 1), found);
        }
      } else if (part.parentScribe != null) {
        String hop = part.parentScribe.relationFieldName;
        if (path == hop) {
          // A parent holding no condition never has its type assigned (ParentScribe returns
          // before doing so), so the lookup it was built from is described instead. Only a
          // single-reference lookup can get here: ParentScribe.validate rejects polymorphic
          // ones before that early return.
          Schema.SObjectType parentType = part.parentScribe.scribe.sObjectType == null
            ? this.parentTypeOf(hop)
            : part.parentScribe.scribe.sObjectType;
          addType(found, parentType);
        } else if (path.startsWithIgnoreCase(hop + '.')) {
          part.parentScribe.scribe.collectTypesAtPath(path.substring(hop.length() + 1), found);
        }
      } else if (part.groupScribe != null) {
        // A group filters the same object at the same place, so it consumes no hop.
        part.groupScribe.collectTypesAtPath(path, found);
      }
    }
    for (Scribe child : this.children) {
      String hop = childHopName(child);
      if (path == hop) {
        addType(found, child.sObjectType);
      } else if (path.startsWithIgnoreCase(hop + '.')) {
        child.collectTypesAtPath(path.substring(hop.length() + 1), found);
      }
    }
  }

  /**
   * Adds an object to the accumulator unless it is null or already there.
   *
   * @param found The accumulating list.
   * @param type The object to add.
   */
  private static void addType(List<Schema.SObjectType> found, Schema.SObjectType type) {
    if (type != null && !found.contains(type)) {
      found.add(type);
    }
  }

  /**
   * The object an expectation should be read against, when a path reaches more than one.
   *
   * The one that has the named field is chosen, so a condition written for the second of
   * two colliding hops is understood as being about that one. When no candidate has the
   * field, the first is returned and `rejectUnknownField` reports them all.
   *
   * @param types The objects the path reaches, never empty.
   * @param fieldName The field the expectation names.
   * @return The object to read the expectation against.
   */
  private static Schema.SObjectType typeHolding(List<Schema.SObjectType> types, String fieldName) {
    if (types.size() == 1 || String.isBlank(fieldName) || fieldName.contains('.')) {
      return types[0];
    }
    for (Schema.SObjectType type : types) {
      if (type.getDescribe().fields.getMap().containsKey(fieldName.toLowerCase())) {
        return type;
      }
    }
    return types[0];
  }

  /**
   * Resolves the object a lookup field points at, for a parent whose scribe never had its
   * type assigned.
   *
   * @param relationFieldName The lookup field given to Scribe.asParent.
   * @return The referenced object, or null when it cannot be resolved.
   */
  private Schema.SObjectType parentTypeOf(String relationFieldName) {
    if (this.sObjectType == null) {
      return null;
    }
    Schema.SObjectField relationField = this.sObjectType.getDescribe().fields.getMap().get(relationFieldName);
    if (relationField == null) {
      return null;
    }
    List<Schema.SObjectType> referenced = relationField.getDescribe().getReferenceTo();
    return referenced.isEmpty() ? null : referenced[0];
  }

  /**
   * The query a semi-join condition wraps (`whereIn(field, Scribe)` / `whereNotIn`), or null
   * for any other condition.
   *
   * @param clause The condition to inspect.
   * @return The subquery, or null.
   */
  private static Scribe subQueryOf(IConditionClause clause) {
    if (clause instanceof InSubQueryConditionClause) {
      return ((InSubQueryConditionClause) clause).getSubQueryScribe();
    }
    if (clause instanceof NotInSubQueryConditionClause) {
      return ((NotInSubQueryConditionClause) clause).getSubQueryScribe();
    }
    return null;
  }

  /**
   * The key two conditions are compared by: the kind of condition, the field, and the SOQL
   * it renders as. The fragment alone is not enough — an empty `IN` renders `Id = null`,
   * `IS NULL` renders `Id = NULL`, and Apex compares those two Strings as equal, so
   * matching on text alone would let one condition satisfy an assertion about another.
   *
   * @param clause The condition to key.
   * @param fragment The SOQL it renders as.
   * @return The comparison key.
   */
  private static String comparisonKey(IConditionClause clause, String fragment) {
    return clause.clauseKind() + '|' + clause.getFieldName() + '|' + fragment;
  }

  /**
   * Formats a list of query paths for a message, naming the empty path (the queried
   * object) rather than printing nothing for it.
   *
   * @param paths The paths to format.
   * @return A readable, comma-separated list.
   */
  private static String describePaths(List<String> paths) {
    List<String> shown = new List<String>();
    for (String path : paths) {
      shown.add(String.isBlank(path) ? '\'\' (the queried object)' : '\'' + path + '\'');
    }
    return shown.isEmpty() ? '(none)' : String.join(shown, ', ');
  }

  /**
   * Renders a list of objects for a message.
   *
   * @param types The objects to name.
   * @return Their names, separated by a slash.
   */
  private static String describeTypes(List<Schema.SObjectType> types) {
    List<String> names = new List<String>();
    for (Schema.SObjectType type : types) {
      names.add(type.getDescribe().getName());
    }
    return String.join(names, ' / ');
  }

  /**
   * Returns the nested scribe reached by a path, or null when the path leads nowhere.
   *
   * @param path The dot-separated path from this query.
   * @return The scribe at that path, or null.
   */
  private Scribe scribeAtPath(String path) {
    if (String.isBlank(path)) {
      return this;
    }
    for (ConditionPart part : this.conditionParts) {
      if (part.condition != null) {
        Scribe subQuery = subQueryOf(part.condition);
        if (subQuery != null) {
          String hop = part.condition.getFieldName();
          if (path == hop) {
            return subQuery;
          }
          if (path.startsWithIgnoreCase(hop + '.')) {
            return subQuery.scribeAtPath(path.substring(hop.length() + 1));
          }
        }
      } else if (part.parentScribe != null) {
        String hop = part.parentScribe.relationFieldName;
        if (path == hop) {
          return part.parentScribe.scribe;
        }
        if (path.startsWithIgnoreCase(hop + '.')) {
          return part.parentScribe.scribe.scribeAtPath(path.substring(hop.length() + 1));
        }
      } else if (part.groupScribe != null) {
        Scribe found = part.groupScribe.scribeAtPath(path);
        if (found != null) {
          return found;
        }
      }
    }
    for (Scribe child : this.children) {
      String hop = childHopName(child);
      if (path == hop) {
        return child;
      }
      if (path.startsWithIgnoreCase(hop + '.')) {
        return child.scribeAtPath(path.substring(hop.length() + 1));
      }
    }
    return null;
  }

  /**
   * The path segment that names a child subquery: its relationship name when one was
   * given via `relationName(...)`, otherwise the child object's name — the same rule
   * the framework already uses to key child data in a FieldStructure.
   *
   * @param child The child scribe.
   * @return The segment naming it.
   */
  private static String childHopName(Scribe child) {
    return String.isBlank(child.relationName) ? child.getDescribe().getName() : child.relationName;
  }

  /**
   * Recursively compares this scribe's conditions — and those of its groups, parent
   * conditions and child subqueries — against the expected fragment held in `match`.
   *
   * A scribe is in scope when its object matches `targetType`, or when its path equals
   * `targetPath`; exactly one of the two is supplied.
   *
   * @param targetType The object whose conditions are compared, or null when a path was given.
   * @param targetPath The path whose conditions are compared, or null when a type was given.
   * @param path This scribe's own path from the query root.
   * @param match The accumulating search outcome.
   */
  private void collectConditionMatches(
    Schema.SObjectType targetType,
    String targetPath,
    String path,
    ConditionMatch match
  ) {
    Boolean isTarget = targetPath == null ? this.sObjectType == targetType : path == targetPath;
    Map<String, Schema.SObjectField> fieldMap = this.sObjectType == null
      ? null
      : this.sObjectType.getDescribe().fields.getMap();

    for (ConditionPart part : this.conditionParts) {
      if (part.condition != null) {
        if (fieldMap == null) {
          continue;
        }
        IConditionClause resolved = part.condition.overrideMetaData(this.sObjectType, fieldMap);
        String fragment = resolved.build();
        String key = comparisonKey(resolved, fragment);
        if (isTarget) {
          match.comparedFragments.add(String.isBlank(path) ? fragment : path + ' -> ' + fragment);
          if (key == match.expectedKey) {
            match.found = true;
          }
        } else if (key == match.expectedKey) {
          // Same condition, wrong place — worth naming in the failure message.
          match.otherObjectHits.add(describePaths(new List<String>{ path }) + ': ' + fragment);
        }
        // A semi-join carries a whole query inside the condition; its conditions are part
        // of what this query filters on, so they are searched one hop further along.
        Scribe subQuery = subQueryOf(part.condition);
        if (subQuery != null) {
          String hop = part.condition.getFieldName();
          subQuery.collectConditionMatches(
            targetType,
            targetPath,
            String.isBlank(path) ? hop : path + '.' + hop,
            match
          );
        }
      } else if (part.groupScribe != null) {
        // A group filters the same object at the same place, so it keeps this path.
        part.groupScribe.collectConditionMatches(targetType, targetPath, path, match);
      } else if (part.parentScribe != null) {
        String hop = part.parentScribe.relationFieldName;
        part.parentScribe.scribe.collectConditionMatches(
          targetType,
          targetPath,
          String.isBlank(path) ? hop : path + '.' + hop,
          match
        );
      }
    }
    if (isTarget && !match.matchedPaths.contains(path)) {
      // A group shares its container's path, so the same place is counted once.
      match.matchedPaths.add(path);
    }
    if (!match.allPaths.contains(path)) {
      // Every reachable place is listed, including those holding no condition: asserting
      // that a place carries nothing is exactly when the list is needed.
      match.allPaths.add(path);
    }
    // Child subqueries filter their own object, one hop further along the path.
    for (Scribe child : this.children) {
      String hop = childHopName(child);
      child.collectConditionMatches(targetType, targetPath, String.isBlank(path) ? hop : path + '.' + hop, match);
    }
    // HAVING is deliberately not searched: its "field" is an aggregate alias.
  }

  /**
   * Builds the assertion failure message: what was expected, what the query actually
   * carries, and the SOQL itself — the context a hand-written `toSoql().contains(...)`
   * check cannot give.
   *
   * @param expected The condition that was searched for.
   * @param match The search outcome.
   * @param shouldExist True when the condition was required, false when it was forbidden.
   * @return The message passed to Assert.
   */
  private String describeAssertionFailure(IConditionClause expected, ConditionMatch match, Boolean shouldExist) {
    String headline = shouldExist
      ? 'Expected the query to carry this condition, but it does not.'
      : 'Expected the query NOT to carry this condition, but it does.';
    String found = match.comparedFragments.isEmpty()
      ? '(the query has no condition on this object)'
      : String.join(match.comparedFragments, ', ');
    String message =
      '\n====== APEX ELOQUENT ASSERTION ======\n' +
      headline +
      '\n  Expected : ' +
      match.expectedFragment +
      '\n  Found    : ' +
      found;
    message += '\n  Searched : ' + describePaths(match.matchedPaths);
    if (shouldExist && !match.otherObjectHits.isEmpty()) {
      message +=
        '\n  Note     : the same condition exists elsewhere in this query (' +
        String.join(match.otherObjectHits, ', ') +
        '). Use assertConditionAt with that path, or name that object.';
    }
    message += '\n  SOQL     : ' + this.toSoql() + '\n';
    return message;
  }

  /**
   * Builds the final SOQL query string.
   *
   * @return The complete, executable SOQL query string.
   */
  public String toSoql() {
    // Reset accumulator state so toSoql() is idempotent across multiple calls
    // (otherwise alias entries from the previous build trigger Duplicate Alias Error).
    this.aggregateAliasMap = new Map<String, AliasStructure>();

    this.validateAndInitialize();

    Map<String, Schema.SObjectField> fieldMap = this.describe.fields.getMap();

    String selectFieldsString = this.buildSelectFields(fieldMap, 0);
    String fromString = this.describe.getName();

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });

    query = this.buildQueryTrail(query, fieldMap, selectFieldsString);

    System.debug('SOQL Query: ' + query);
    return query;
  }

  /**
   * Builds the clauses that follow the FROM clause.
   *
   * @param query The query string up to the FROM clause.
   * @param fieldMap A map of the source object's fields.
   * @param selectFieldsString The already built SELECT clause string.
   * @return The complete query string.
   */
  private String buildQueryTrail(
    String query,
    Map<String, Schema.SObjectField> fieldMap,
    String selectFieldsString
  ) {
    WhereClauseData whereClauseData = this.buildWhereClause(fieldMap, null);
    String whereString = whereClauseData.whereClauseString;
    if (String.isNotBlank(whereString)) {
      query += ' WHERE ' + whereString;
    }

    FieldStructure fieldStructure = this.buildFieldStructure();
    query = this.buildGroupByClause(query, fieldMap, fieldStructure, new List<String>(), new List<String>());

    query = this.buildHavingClause(query);

    query = this.buildOrderByClause(query);

    query = this.buildLimitClause(query);

    query = this.buildOffsetClause(query);

    query = this.buildForUpdateClause(query);

    return query;
  }

  /**
   * Gets the list of fields to be included in the SELECT clause, validating their existence.
   *
   * @param fieldMap A map of the source object's fields.
   * @return A list of validated field names.
   */
  public List<String> getSelectedFields(Map<String, Schema.SObjectField> fieldMap) {
    List<String> selectFields = new List<String>();

    if (this.isSelectAll) {
      for (String fieldName : fieldMap.keyset()) {
        selectFields.add(fieldName.toLowerCase());
      }
    } else {
      for (String fieldName : this.selectFields) {
        if (!fieldMap.containsKey(fieldName.toLowerCase())) {
          String error = 'Field Selection Failed';
          String reason = String.format(
            'The field `{0}` does not exist on the SObject `{1}`.',
            new List<String>{ fieldName, this.describe.getName() }
          );
          String action = 'Please check the field API name for typos or ensure the field is accessible in the current Org.';
          throw ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).build();
        }
        selectFields.add(fieldName.toLowerCase());
      }
    }

    return selectFields;
  }

  // =================================================================================================================
  // Private Helper Methods
  // =================================================================================================================

  /**
   * Creates a deep clone of the current Scribe instance to maintain immutability.
   *
   * @return A new Scribe instance with the same state.
   */
  private Scribe deepClone() {
    Scribe newScribe = new Scribe(this.sObjectType);
    newScribe.describe = this.describe;

    newScribe.selectFields = this.selectFields.clone();
    newScribe.aggregateClauses = this.aggregateClauses.clone();
    newScribe.isSelectAll = this.isSelectAll;

    newScribe.conditionParts = this.conditionParts.clone();
    newScribe.isNextConditionOr = this.isNextConditionOr;
    newScribe.canOnlyAddOrCondition = this.canOnlyAddOrCondition;

    newScribe.parents = this.parents.clone();
    newScribe.children = this.children.clone();
    newScribe.throughScribes = this.throughScribes.clone();
    newScribe.junctionSObjectType = this.junctionSObjectType;
    newScribe.parentRelationIdFieldName = this.parentRelationIdFieldName;
    newScribe.relationName = this.relationName;

    newScribe.groupByClauses = this.groupByClauses.clone();
    newScribe.aggregateAliasMap = this.aggregateAliasMap.clone();
    newScribe.havingScribe = this.havingScribe;

    newScribe.orderByClauses = this.orderByClauses.clone();

    newScribe.limitNumber = this.limitNumber;

    newScribe.offsetNumber = this.offsetNumber;

    newScribe.isParent = this.isParent;
    newScribe.isChild = this.isChild;
    newScribe.isGroup = this.isGroup;
    newScribe.isThrough = this.isThrough;
    newScribe.isHaving = this.isHaving;
    newScribe.isForUpdate = this.isForUpdate;

    return newScribe;
  }

  /**
   * Gets the map of aggregate aliases..
   *
   * @return The map of aliases to their structures.
   */
  private Map<String, AliasStructure> getAggregateAliasMap() {
    return this.aggregateAliasMap;
  }

  /**
   * Constructs the complete SELECT clause, including fields, aggregates, and subqueries.
   *
   * @param fieldMap A map of the source object's fields.
   * @param lowerNestingDepth The current nesting depth for child subqueries.
   * @return The formatted SELECT clause string.
   */
  private String buildSelectFields(Map<String, Schema.SObjectField> fieldMap, Integer lowerNestingDepth) {
    String selectFieldsString = '';

    // add select fields
    if (this.isSelectAll || !this.selectFields.isEmpty()) {
      selectFieldsString = String.join(this.getSelectedFields(fieldMap), ', ');
    }

    // add aggregate clauses
    for (IAggregateClause aggregateClause : this.aggregateClauses) {
      if (String.isNotBlank(selectFieldsString)) {
        selectFieldsString += ', ';
      }
      aggregateClause = aggregateClause.overrideMetaData(this.sObjectType, fieldMap);
      String aggregateClauseString = aggregateClause.build();
      selectFieldsString += aggregateClauseString;
      String alias = aggregateClause.getAlias();
      if (this.aggregateAliasMap.containsKey(alias)) {
        String error = 'Duplicate Alias Error';
        String reason = String.format(
          'The alias {0} is already defined in the aggregate clause.',
          new List<String>{ alias }
        );
        String action = 'Ensure each aggregate function has a unique alias.';
        throw ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).build();
      }
      String aggregateField = aggregateClause.getFieldName();
      String aggregateTarget = aggregateClauseString.split(' ')[0];
      this.aggregateAliasMap.put(alias, new AliasStructure(aggregateField, aggregateTarget, fieldMap));
    }

    // Add parent queries
    for (ParentScribe parent : this.parents) {
      if (String.isNotBlank(selectFieldsString)) {
        selectFieldsString += ', ';
      }
      selectFieldsString += parent.buildSelectClause(fieldMap, null, 0);
      Map<String, AliasStructure> parentAggregateAliasMap = parent.getAggregateAliasMap();
      for (String alias : parentAggregateAliasMap.keySet()) {
        if (this.aggregateAliasMap.containsKey(alias)) {
          String error = 'Duplicate Alias Error';
          String reason = String.format(
            'The alias {0} in the parent query is already defined in the aggregate clause.',
            new List<String>{ alias }
          );
          String action = 'Ensure each aggregate function has a unique alias.';
          throw ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).build();
        }
        this.aggregateAliasMap.put(alias, parentAggregateAliasMap.get(alias));
      }
    }

    // Add child queries
    if (!this.children.isEmpty()) {
      if (String.isNotBlank(selectFieldsString)) {
        selectFieldsString += ', ';
      }
      lowerNestingDepth++;
      if (lowerNestingDepth > this.MAX_LOWER_NESTING_DEPTH) {
        List<String> overNestedChildrenNames = new List<String>();
        for (Scribe child : this.children) {
          overNestedChildrenNames.add(child.getDescribe().getName());
        }
        String error = 'Query Nesting Limit Exceeded';
        String reason = String.format(
          'The query reached the maximum allowed nesting depth ({0}). Over-nested child relationship: [{1}]',
          new List<String>{
            String.valueOf(this.MAX_LOWER_NESTING_DEPTH),
            String.join(overNestedChildrenNames, ', ')
          }
        );
        String action = 'Reduce the nesting depth.';
        throw ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).build();
      }
      List<String> childSoqls = new List<String>();
      for (Scribe child : this.children) {
        String childSoql = String.format(
          '({0})',
          new List<String>{ child.buildChildSoql(this.sObjectType, lowerNestingDepth) }
        );
        childSoqls.add(childSoql);
      }
      if (!childSoqls.isEmpty()) {
        selectFieldsString += String.join(childSoqls, ', ');
      }
    }

    return selectFieldsString;
  }

  /**
   * Constructs the complete WHERE clause string from all condition parts.
   *
   * @param fieldMap A map of the source object's fields.
   * @param childObjectName The relationship name, if this is part of a parent condition.
   * @return A WhereClauseData object containing the WHERE string and operator info.
   */
  private WhereClauseData buildWhereClause(Map<String, Schema.SObjectField> fieldMap, String childObjectName) {
    String whereClauseString = '';

    if (this.conditionParts.isEmpty()) {
      return new WhereClauseData('', false, false);
    }

    Boolean isFirstOperatorOr = null;
    Boolean isLastOperatorOr = false;
    Integer renderedCount = 0;
    Boolean usedAnd = false;
    Boolean usedOr = false;
    for (ConditionPart conditionPart : this.conditionParts) {
      if (isLastOperatorOr && !conditionPart.isOr) {
        String error = 'Logical Operator Mismatch';
        String reason = 'A condition following an orWhere() must also be an OR condition to maintain logical consistency.';
        String action = 'Ensure all subsequent where clauses after the first `orCondition()` in this chain are used with the `orCondition()` method.';
        throw ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).build();
      }
      isFirstOperatorOr = isFirstOperatorOr == null ? conditionPart.isOr : isFirstOperatorOr;
      WhereClauseData whereClauseData = null;
      String clause = '';

      if (conditionPart.condition != null) {
        IConditionClause condition = conditionPart.condition.overrideMetaData(this.sObjectType, fieldMap);
        clause = condition.build();
        if (String.isBlank(clause)) {
          continue;
        }
        if (String.isNotBlank(childObjectName)) {
          clause = childObjectName + '.' + clause;
        }
        isLastOperatorOr = conditionPart.isOr;
      } else if (conditionPart.groupScribe != null) {
        Scribe groupScribe = conditionPart.groupScribe;
        groupScribe.sObjectType = this.sObjectType;
        WhereClauseData groupWhereClauseData = groupScribe.buildWhereClause(fieldMap, null);
        if (String.isBlank(groupWhereClauseData.whereClauseString)) {
          continue;
        }
        String groupBody = groupWhereClauseData.whereClauseString;
        if (groupWhereClauseData.renderedCount == 1 && groupBody.startsWith('(') && groupBody.endsWith(')')) {
          // the group holds exactly one already-parenthesized unit (a nested group or a
          // multi-condition parent fragment) — wrapping again would render ((...))
          clause = groupBody;
        } else {
          clause = String.format('({0})', new List<String>{ groupBody });
        }
        isLastOperatorOr = conditionPart.isOr;
      } else if (conditionPart.parentScribe != null) {
        ParentScribe parentScribe = conditionPart.parentScribe;
        WhereClauseData parentWhereClauseData = parentScribe.buildWhereClause(fieldMap, childObjectName);
        clause = parentWhereClauseData.whereClauseString;
        if (parentWhereClauseData.renderedCount > 1) {
          // a multi-condition parent fragment is one structural unit — parenthesize
          // it like a whereGroup, so it cannot create an unparenthesized AND/OR mix
          // at this level (issue #75). SOQL rejects such a mix as invalid.
          clause = String.format('({0})', new List<String>{ clause });
        }
        isLastOperatorOr = parentWhereClauseData.isLastOperatorOr;
        conditionPart.isOr = parentWhereClauseData.isFirstOperatorOr;
      }

      if (String.isNotBlank(clause)) {
        if (String.isNotBlank(whereClauseString)) {
          if (conditionPart.isOr) {
            usedOr = true;
          } else {
            usedAnd = true;
          }
          if (usedAnd && usedOr) {
            this.fireMixedOperatorError();
          }
          whereClauseString += conditionPart.isOr ? ' OR ' : ' AND ';
        }
        whereClauseString += clause;
        renderedCount++;
      }
    }

    WhereClauseData result = new WhereClauseData(whereClauseString, isFirstOperatorOr, isLastOperatorOr);
    result.renderedCount = renderedCount;
    return result;
  }

  /**
   * SOQL rejects mixing AND and OR at one nesting level without parentheses
   * (the query fails at run time with "unexpected token"). Checked at build
   * time, not chain time: ignoreWhen() may retract conditions and legitimately
   * resolve — or create — the mix only at build (issue #75).
   */
  private void fireMixedOperatorError() {
    String error = 'Mixed AND and OR at the same level';
    String reason = 'SOQL rejects mixing AND and OR at one nesting level without parentheses — the generated query would fail with "unexpected token".';
    String action = 'Wrap one side in whereGroup(Scribe.asGroup()...) to make the grouping explicit.';
    ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).fire();
  }

  /**
   * Constructs the complete HAVING clause string.
   *
   * @param aggregateAliasMap A map of all defined aggregate aliases.
   * @return A WhereClauseData object containing the HAVING string.
   */
  private WhereClauseData buildHavingClause(Map<String, AliasStructure> aggregateAliasMap) {
    String whereClauseString = '';

    if (this.conditionParts.isEmpty()) {
      return new WhereClauseData('', false, false);
    }

    Boolean isFirstOperatorOr = null;
    Boolean isLastOperatorOr = false;
    Boolean usedAnd = false;
    Boolean usedOr = false;

    for (ConditionPart conditionPart : this.conditionParts) {
      if (isLastOperatorOr && !conditionPart.isOr) {
        String error = 'Logical Operator Mismatch';
        String reason = 'A condition following an orWhere() must also be an OR condition to maintain logical consistency.';
        String action = 'Ensure all subsequent having clauses after the first orCondition() in this chain are used with the orCondition() method.';
        throw ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).build();
      }
      WhereClauseData whereClauseData = null;
      String clause = '';

      if (conditionPart.condition != null) {
        // We assume that in a HAVING clause, a where...() method is used with an alias instead of a field name.
        // Thus, getFieldName() retrieves the alias.
        String alias = conditionPart.condition.getFieldName();

        if (!aggregateAliasMap.containsKey(alias)) {
          String error = 'Aggregate Alias Not Found';
          String reason = String.format(
            'The alias "{0}" used in the HAVING clause does not match any alias defined in the aggregate clauses.',
            new List<String>{ alias }
          );
          String action = 'Ensure the alias is correctly defined using aggregate methods.';
          throw ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).build();
        }
        AliasStructure aliasStructure = aggregateAliasMap.get(alias);

        IConditionClause condition = conditionPart
          .condition
          .overrideMetaData(this.sObjectType, aliasStructure.getFieldMap())
          .overrideField(aliasStructure.getFieldName());
        String clauseWithAlias = condition.build();

        // The initial build() result uses the SObject field name, so we need to replace it with the full aggregate function.
        // e.g., 'Amount > 1000' becomes 'AVG(Amount) > 1000'
        List<String> clauseParts = clauseWithAlias.split(' ');
        clauseParts[0] = aliasStructure.getAggregateClause();

        // The initial build() formats the value based on the original field's data type.
        // However, for some aggregate functions (like COUNT, SUM, AVG), the result is numeric and should not be quoted.
        // We only preserve the original casting for MIN and MAX, as their return type matches the original field's type.
        Boolean needsCast = clauseParts[0].startsWith('MAX') || clauseParts[0].startsWith('MIN');
        if (!needsCast) {
          // The value part is everything from the 3rd element (index 2) onwards.
          List<String> valueList = new List<String>();
          for (Integer i = 2; i < clauseParts.size(); i++) {
            valueList.add(clauseParts[i]);
          }
          String valueString = String.join(valueList, ' ');
          // Remove the surrounding single quotes.
          valueString = valueString.replaceAll('^\'|\'$', '');
          clauseParts = new List<String>{ clauseParts[0], clauseParts[1], valueString };
        }
        clause = String.join(clauseParts, ' ');
        isLastOperatorOr = conditionPart.isOr;
      } else if (conditionPart.groupScribe != null) {
        Scribe groupScribe = conditionPart.groupScribe;
        groupScribe.sObjectType = this.sObjectType;
        WhereClauseData groupWhereClauseData = groupScribe.buildHavingClause(aggregateAliasMap);
        if (String.isBlank(groupWhereClauseData.whereClauseString)) {
          continue;
        }
        clause = String.format('({0})', new List<String>{ groupWhereClauseData.whereClauseString });
        isLastOperatorOr = conditionPart.isOr;
      }

      if (String.isNotBlank(clause)) {
        if (String.isNotBlank(whereClauseString)) {
          if (conditionPart.isOr) {
            usedOr = true;
          } else {
            usedAnd = true;
          }
          if (usedAnd && usedOr) {
            this.fireMixedOperatorError();
          }
          whereClauseString += conditionPart.isOr ? ' OR ' : ' AND ';
        }
        whereClauseString += clause;
      }
    }

    return new WhereClauseData(whereClauseString, isFirstOperatorOr, isLastOperatorOr);
  }

  /**
   * Constructs the ORDER BY clause string.
   *
   * @param query The current query string.
   * @return The query string with the ORDER BY clause appended.
   */
  private String buildOrderByClause(String query) {
    if (this.orderByClauses.isEmpty()) {
      return query;
    }
    if (this.isForUpdate) {
      String error = 'Order By Conflict';
      String reason = 'The ORDER BY clause cannot be used in conjunction with the FOR UPDATE clause due to Salesforce SOQL limitations.';
      String action = 'Remove either the orderBy() or forUpdate() method from your query chain.';

      ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).fire();
    }

    query += ' ORDER BY ';
    List<String> orderByStrings = new List<String>();
    for (OrderByClause orderByClause : this.orderByClauses) {
      orderByStrings.add(orderByClause.build());
    }
    query += String.join(orderByStrings, ', ');

    return query;
  }

  /**
   * Constructs the LIMIT clause string.
   *
   * @param query The current query string.
   * @return The query string with the LIMIT clause appended.
   */
  private String buildLimitClause(String query) {
    if (this.limitNumber == 0) {
      return query;
    }

    return query += ' LIMIT ' + String.valueOf(this.limitNumber);
  }

  /**
   * Constructs the OFFSET clause string.
   *
   * @param query The current query string.
   * @return The query string with the OFFSET clause appended.
   */
  private String buildOffsetClause(String query) {
    if (this.offsetNumber == 0) {
      return query;
    }
    if (this.isForUpdate) {
      String error = 'Offset Conflict';
      String reason = 'The OFFSET clause cannot be used in conjunction with the FOR UPDATE clause due to Salesforce SOQL limitations.';
      String action = 'Remove either the offset() or forUpdate() method from your query chain.';

      ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).fire();
    }

    return query += ' OFFSET ' + String.valueOf(this.offsetNumber);
  }

  /**
   * Constructs the FOR UPDATE clause string.
   *
   * @param query The current query string.
   * @return The query string with the FOR UPDATE clause appended.
   */
  private String buildForUpdateClause(String query) {
    if (!this.isForUpdate) {
      return query;
    }

    return query += ' FOR UPDATE';
  }

  /**
   * Constructs the child subquery string.
   *
   * @param parentSObjectType The SObjectType of the parent query.
   * @param lowerNestingdepth The current nesting depth.
   * @return The complete child subquery string.
   */
  private String buildChildSoql(Schema.SObjectType parentSObjectType, Integer lowerNestingdepth) {
    this.validateAndInitialize();

    Map<String, Schema.SObjectField> fieldMap = this.describe.fields.getMap();
    String selectFieldsString = this.buildSelectFields(fieldMap, lowerNestingDepth);

    String objectName = this.describe.getName();
    String fromString;
    List<Schema.ChildRelationship> childRelationships = parentSObjectType.getDescribe().getChildRelationships();
    Integer foundIndex = findChildRelationshipIndex(childRelationships, objectName);

    if (String.isNotBlank(this.relationName)) {
      fromString = this.relationName;

      boolean isValid = false;
      // checking amibibuity
      if (foundIndex != -1) {
        for (
          Integer i = foundIndex;
          i >= 0 &&
          childRelationships[i].getChildSObject().getDescribe().getName() == objectName;
          i--
        ) {
          if (childRelationships[i].getRelationshipName() == fromString) {
            isValid = true;
            break;
          }
        }
        for (
          Integer i = foundIndex + 1;
          !isValid &&
          i < childRelationships.size() &&
          childRelationships[i].getChildSObject().getDescribe().getName() == objectName;
          i++
        ) {
          if (childRelationships[i].getRelationshipName() == fromString) {
            isValid = true;
            break;
          }
        }
      }

      if (!isValid) {
        String parentObjectName = parentSObjectType.getDescribe().getName();
        String errorLabel = 'Invalid Relationship Name';
        String reason = String.format(
          'The relationship "{2}" was not found between child SObject "{0}" and parent SObject "{1}".',
          new List<String>{ objectName, parentObjectName, fromString }
        );
        String action = 'Check for typos in the relationship name or verify the lookup field configuration in Salesforce.';
        ApexEloquentException.at(CLASS_NAME).error(errorLabel).reason(reason).action(action).fire();
      }
    } else {
      if (foundIndex == -1) {
        String parentObjectName = parentSObjectType.getDescribe().getName();
        String errorLabel = 'No Child Relationship Found';
        String reason = String.format(
          'The parent SObject "{0}" does not have any defined child relationships with SObject "{1}".',
          new List<String>{ parentObjectName, objectName }
        );
        String action = 'Ensure a Lookup or Master-Detail field exists on "{1}" pointing to "{0}", or verify that the parent and child objects are not swapped in your Scribe definition.';

        ApexEloquentException.at(CLASS_NAME).error(errorLabel).reason(reason).action(action).fire();
      }

      // checking amibibuity
      Boolean isAmbiguous = false;
      if (
        foundIndex > 0 &&
        childRelationships[foundIndex - 1].getChildSObject().getDescribe().getName() == objectName
      ) {
        isAmbiguous = true;
      }
      if (
        !isAmbiguous &&
        foundIndex < childRelationships.size() - 1 &&
        childRelationships[foundIndex + 1].getChildSObject().getDescribe().getName() == objectName
      ) {
        isAmbiguous = true;
      }

      if (isAmbiguous) {
        String parentObjectName = parentSObjectType.getDescribe().getName();
        String error = 'Ambiguous Relationship';
        String reason = String.format(
          'Multiple relationships exist for {0} on {1}. The system cannot determine which one to use automatically.',
          new List<String>{ objectName, parentObjectName }
        );
        String action = 'Explicitly specify the relationship name using the relationName() method to resolve the ambiguity.';

        ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).fire();
      }

      fromString = childRelationships[foundIndex].getRelationshipName();

      if (fromString == null) {
        String parentObjectName = parentSObjectType.getDescribe().getName();
        String error = 'Inaccessible Relationship';
        String reason = String.format(
          'The identified relationship for {0} on {1} does not have a valid name and cannot be used in a SOQL subquery.',
          new List<String>{ objectName, parentObjectName }
        );
        String action = 'Verify if this relationship supports subqueries, or explicitly provide the correct relationship name using the relationName() method.';
        ApexEloquentException.at(CLASS_NAME).error(error).reason(reason).action(action).fire();
      }
    }

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });
    query = this.buildQueryTrail(query, fieldMap, selectFieldsString);

    return query;
  }

  private Integer findChildRelationshipIndex(
    List<Schema.ChildRelationship> relationships,
    String targetChildObjectName
  ) {
    Integer low = 0;
    Integer high = relationships.size() - 1;

    while (low <= high) {
      Integer mid = (low + high) / 2;
      String midName = relationships[mid].getChildSObject().getDescribe().getName();
      System.debug('midName: ' + midName);
      Integer res = targetChildObjectName.compareTo(midName);

      if (res == 0) {
        return mid;
      } else if (res > 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return -1;
  }

  /**
   * Gets the describe result for the source SObject.
   *
   * @return The describe result.
   */
  private Schema.DescribeSObjectResult getDescribe() {
    return this.describe;
  }

  /**
   * Constructs the GROUP BY clause and validates selected fields against it.
   *
   * @param query The current query string.
   * @param fieldMap A map of the source object's fields.
   * @param fieldStructure The field structure representing all selected fields.
   * @param childObjectNames The list of child relationship names for context.
   * @param parentIdFieldNames The list of parent relationship ID fields for context.
   * @return The query string with the GROUP BY clause appended.
   */
  private String buildGroupByClause(
    String query,
    Map<String, Schema.SObjectField> fieldMap,
    FieldStructure fieldStructure,
    List<String> childObjectNames,
    List<String> parentIdFieldNames
  ) {
    if (this.groupByClauses.isEmpty()) {
      return query;
    }

    List<String> groupByStrings = this.buildGroupByFields(fieldMap, fieldStructure, childObjectNames);

    if (!fieldStructure.isEmpty()) {
      String reason = 'There are fields in the SELECT clause that are not included in the GROUP BY clause';
      String action = 'Add the non-grouped fields to a groupByField(), or remove them from the SELECT';
      String nonGrouped = String.join(fieldStructure.getFieldsAsFlattenWithRelationName(null), ', ');
      ApexEloquentException.invalidOperation(CLASS_NAME, null, reason)
        .param('nonGroupedFields', nonGrouped)
        .action(action)
        .fire();
    }
    return query + ' GROUP BY ' + String.join(groupByStrings, ', ');
  }

  /**
   * Helper method to build the list of GROUP BY field strings.
   *
   * @param fieldMap A map of the source object's fields.
   * @param fieldStructure The field structure for validation.
   * @param childObjectNames The list of child relationship names for context.
   * @return A list of formatted GROUP BY field strings.
   */
  private List<String> buildGroupByFields(
    Map<String, Schema.SObjectField> fieldMap,
    FieldStructure fieldStructure,
    List<String> childObjectNames
  ) {
    List<String> groupByStrings = new List<String>();
    for (GroupByClause groupByClause : this.groupByClauses) {
      groupByStrings.addAll(
        groupByClause.buildGroupField(this.describe, fieldStructure, fieldMap, childObjectNames)
      );
    }

    return groupByStrings;
  }

  /**
   * Constructs the complete HAVING clause string.
   *
   * @param query The current query string.
   * @return The query string with the HAVING clause appended.
   */
  private String buildHavingClause(String query) {
    if (this.havingScribe == null) {
      return query;
    }

    this.havingScribe.sObjectType = this.sObjectType;
    WhereClauseData havingClauseData = this.havingScribe.buildHavingClause(this.aggregateAliasMap);
    String havingString = havingClauseData.whereClauseString;
    if (String.isNotBlank(havingString)) {
      query += ' HAVING ' + havingString;
    }

    return query;
  }

  // =================================================================================================================
  // Validation Methods
  // =================================================================================================================

  /**
   * Validates that a field name is provided and that the operator logic is valid.
   *
   * @param fieldName The field name being added to a condition.
   */
  private void validateConditionClause(String method, String fieldName, Object value) {
    if (fieldName == null || String.isBlank(fieldName)) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'fieldName', fieldName).build();
    }
    // NOTE: a null value is NOT rejected here. Methods that cannot accept null record
    // an InvalidConditionClause instead, deferring the error to SOQL build time so
    // ignoreWhen() can retract the condition first (issue #71).
    this.validateConditionOperator(method, fieldName, value);
  }

  /**
   * Validates the OR/AND operator chaining logic.
   */
  private void validateConditionOperator(String method, String fieldName, Object value) {
    if (this.canOnlyAddOrCondition && !this.isNextConditionOr) {
      String error = 'Illegal Logical Transition';
      String reason = 'Once an OR condition is introduced, all subsequent conditions must be explicitly prefixed with .orCondition()';
      String action = 'Insert .orCondition() before this ' + method + ' call';
      ApexEloquentException transitionError = ApexEloquentException.at(CLASS_NAME)
        .method(method)
        .error(error)
        .reason(reason)
        .action(action);

      if (fieldName != null) {
        transitionError.param('fieldName', fieldName).fire();
      }
      transitionError.fire();
    }
  }

  /**
   * Validates that OR is not followed by a non-WHERE clause method.
   */
  private void validateOrConditionNotAllowed(String method) {
    if (this.isNextConditionOr) {
      String error = 'Incomplete Logical Expression';
      String reason = 'The .orCondition() method was called, but the required following condition is missing.';
      String action = 'After calling .orCondition(), you must immediately follow it with a where...() method (e.g., .whereEqual()) or the .whereGroup() method to complete the expression.';
      ApexEloquentException.at(CLASS_NAME).method(method).error(error).reason(reason).action(action).fire();
    }
  }

  private void validateAggregateClauseParams(String method, String fieldName, String alias) {
    if (fieldName == null || String.isBlank(fieldName)) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'fieldName', fieldName).build();
    }
    if (alias == null || String.isBlank(alias)) {
      throw ApexEloquentException.required(CLASS_NAME, method, 'alias', fieldName).build();
    }
  }

  /**
   * Validates that aggregate functions are not used in unsupported contexts.
   */
  private void validateAddAggregateClause(String method) {
    if (this.isChild) {
      ApexEloquentException.at(CLASS_NAME)
        .method(method)
        .error('Contextual Violation: Aggregate Function Forbidden')
        .reason(
          'Currently within a children context. aggregate function addition is not permitted in child context.'
        )
        .action('Please add aggregate functions to the root Scribe instance.')
        .fire();
    }

    if (this.isHaving) {
      ApexEloquentException.at(CLASS_NAME)
        .method(method)
        .error('Contextual Violation: Aggregate Function Forbidden')
        .reason(
          'Currently within a HAVING clause context. aggregate function addition is not permitted in having context.'
        )
        .action('Please finish your .havingCondition() block before adding aggregate functions')
        .fire();
    }

    if (!this.children.isEmpty()) {
      ApexEloquentException.at(CLASS_NAME)
        .method(method)
        .error('SOQL Aggregate Restriction')
        .reason(
          'Aggregate functions and child relationship queries (withChildren) are incompatible in a single SOQL statement.'
        )
        .action('Remove the withChildren() calls, or separate the aggregate and child queries.')
        .fire();
    }

    this.validateOrConditionNotAllowed(method);
  }

  /**
   * Validates that fields are not added in unsupported contexts.
   */
  private ApexEloquentException validateAddFieldClause() {
    if (this.isGroup) {
      return ApexEloquentException.at(CLASS_NAME)
        .error('Contextual Violation: Field Addition Forbidden')
        .reason(
          'Currently within a grouping context (whereGroup). Field selection is not permitted in grouping context'
        )
        .action('Please finish your .whereGroup() block before adding additional SELECT fields');
    }

    if (this.isHaving) {
      return ApexEloquentException.at(CLASS_NAME)
        .error('Contextual Violation: Field Addition Forbidden')
        .reason('Currently within a HAVING clause context. Field selection is not permitted in having context')
        .action('Please finish your .havingCondition() block before adding additional SELECT fields');
    }

    return null;
  }

  /**
   * Validates essential parameters and initializes defaults if necessary.
   * For example, adds 'Id' to the select fields if no other fields are specified.
   */
  private void validateAndInitialize() {
    Boolean isSObjectTypeNull = this.sObjectType == null;
    if (isSObjectTypeNull) {
      ApexEloquentException.invalidOperation(CLASS_NAME, null, 'source SObjectType is not set').fire();
    }
    if (
      this.selectFields.isEmpty() &&
      !this.isSelectAll &&
      this.aggregateClauses.isEmpty() &&
      this.parents.isEmpty() &&
      this.children.isEmpty()
    ) {
      this.selectFields.add('Id');
    }
  }

  // =================================================================================================================
  // Inner Classes
  // =================================================================================================================

  /**
   * Private inner class to hold a part of a WHERE clause.
   * It can represent a single condition, a grouped condition, or a parent condition.
   */
  private class ConditionPart {
    public IConditionClause condition = null;
    public Scribe groupScribe = null;
    public ParentScribe parentScribe = null;
    public Boolean isOr = false;

    public ConditionPart(IConditionClause condition, Boolean isOr) {
      this.condition = condition;
      this.isOr = isOr;
    }

    public ConditionPart(Scribe groupScribe, Boolean isOr) {
      this.groupScribe = groupScribe;
      this.isOr = isOr;
    }

    public ConditionPart(ParentScribe parentScribe) {
      this.parentScribe = parentScribe;
      this.isOr = false;
    }
  }

  /**
   * Private inner class to hold describe information for a parent object relationship.
   */
  private class ParentObjectData {
    public Schema.DescribeFieldResult relationFieldDescribe;
    public String relationFieldName;
    public Schema.SObjectType relationSObjectType;

    public ParentObjectData(
      Schema.DescribeFieldResult relationFieldDescribe,
      String relationFieldName,
      Schema.SObjectType relationSObjectType
    ) {
      this.relationFieldDescribe = relationFieldDescribe;
      this.relationFieldName = relationFieldName;
      this.relationSObjectType = relationSObjectType;
    }
  }

  /**
   * Private inner class to hold the result of building a WHERE clause string.
   */
  private class WhereClauseData {
    public String whereClauseString;
    public boolean isFirstOperatorOr;
    public boolean isLastOperatorOr;
    public Integer renderedCount = 0;

    public WhereClauseData(String whereClauseString, boolean isFirstOperatorOr, boolean isLastOperatorOr) {
      this.whereClauseString = whereClauseString;
      this.isFirstOperatorOr = isFirstOperatorOr;
      this.isLastOperatorOr = isLastOperatorOr;
    }
  }

  /**
   * Private inner class to represent a parent relationship query component.
   * It holds the relationship field name and the Scribe instance for the parent.
   */
  private class ParentScribe {
    public String relationFieldName;
    public Scribe scribe;

    private final Integer MAX_UPPER_NESTING_DEPTH = 5;

    public ParentScribe(String relationFieldName, Scribe scribe) {
      this.relationFieldName = relationFieldName;
      this.scribe = scribe;
    }

    public String getRelationFieldName() {
      return this.relationFieldName;
    }

    public Map<String, AliasStructure> getAggregateAliasMap() {
      return this.scribe.getAggregateAliasMap();
    }

    public String buildSelectClause(
      Map<String, Schema.SObjectField> childFieldMap,
      String childObjectName,
      Integer upperNestingDepth
    ) {
      // Reset the inner scribe's aggregate alias map so this method is idempotent
      // across multiple top-level toSoql() invocations (mirrors Scribe.toSoql()).
      this.scribe.aggregateAliasMap = new Map<String, AliasStructure>();

      ParentObjectData parentObjectData = this.validate(childFieldMap);

      Integer currentUpperNestingDepth = upperNestingDepth + 1;
      if (currentUpperNestingDepth > this.MAX_UPPER_NESTING_DEPTH) {
        String reason = 'Maximum nesting depth for parent queries reached';
        ApexEloquentException.invalidOperation('Scribe.ParentScribe', null, reason)
          .param('maxDepth', this.MAX_UPPER_NESTING_DEPTH)
          .param('objectName', parentObjectData.relationSObjectType.getDescribe().getName())
          .fire();
      }

      if (this.scribe.sObjectType == null) {
        this.scribe.sObjectType = parentObjectData.relationSObjectType;
      }

      String parentObjectRelationName = parentObjectData.relationFieldName;
      String currentChainedParentObjectName = childObjectName == null
        ? parentObjectRelationName
        : childObjectName + '.' + parentObjectRelationName;
      Map<String, Schema.SObjectField> parentFieldMap = parentObjectData
        .relationSObjectType
        .getDescribe()
        .fields
        .getMap();
      List<String> parentSelects = new List<String>();
      for (String parentFieldName : this.scribe.getSelectedFields(parentFieldMap)) {
        String parentSelect = '';
        parentSelect += currentChainedParentObjectName + '.' + parentFieldName;
        parentSelects.add(parentSelect);
      }

      for (IAggregateClause aggregateClause : this.scribe.aggregateClauses) {
        aggregateClause = aggregateClause.overrideMetaData(this.scribe.sObjectType, parentFieldMap);

        String aggregateClauseString = aggregateClause.buildWithChild(currentChainedParentObjectName);
        parentSelects.add(aggregateClauseString);

        String alias = aggregateClause.getAlias();
        String aggregateField = aggregateClause.getFieldName();
        String aggregateTarget = aggregateClauseString.split(' ')[0];
        this.scribe.aggregateAliasMap.put(
          alias,
          new AliasStructure(aggregateField, aggregateTarget, parentFieldMap)
        );
      }

      if (!this.scribe.parents.isEmpty()) {
        for (ParentScribe grandParentScribe : this.scribe.parents) {
          String grandParentSelectsAsString = grandParentScribe.buildSelectClause(
            parentFieldMap,
            currentChainedParentObjectName,
            currentUpperNestingDepth
          );
          parentSelects.add(grandParentSelectsAsString);
          Map<String, AliasStructure> grandParentAggregateAliasMap = grandParentScribe.getAggregateAliasMap();
          for (String alias : grandParentAggregateAliasMap.keySet()) {
            if (this.scribe.aggregateAliasMap.containsKey(alias)) {
              String reason = 'The alias in the parent query conflicts with an existing alias';
              ApexEloquentException.invalidOperation('Scribe.ParentScribe', null, reason)
                .param('alias', alias)
                .action('Use a unique alias for each aggregate clause in nested parent queries')
                .fire();
            }
            this.scribe.aggregateAliasMap.put(alias, grandParentAggregateAliasMap.get(alias));
          }
        }
      }
      if (parentSelects.isEmpty()) {
        ApexEloquentException.invalidOperation('Scribe.ParentScribe', null, 'The parent fields list is empty')
          .fire();
      }
      return String.join(parentSelects, ', ');
    }

    public WhereClauseData buildWhereClause(Map<String, Schema.SObjectField> fieldMap, String childObjectName) {
      ParentObjectData parentObjectData = this.validate(fieldMap);

      if (this.scribe.conditionParts.isEmpty()) {
        return new WhereClauseData('', false, false);
      }

      String newChildObjectName;
      if (childObjectName == null) {
        newChildObjectName = parentObjectData.relationFieldName;
      } else {
        newChildObjectName = childObjectName + '.' + parentObjectData.relationFieldName;
      }

      Schema.SObjectType parentSObjectType = parentObjectData.relationSObjectType;
      this.scribe.sObjectType = parentSObjectType;
      Map<String, Schema.SObjectField> parentFieldMap = parentSObjectType.getDescribe().fields.getMap();

      return this.scribe.buildWhereClause(parentFieldMap, newChildObjectName);
    }

    public List<String> buildGroupByClause(
      Map<String, Schema.SObjectField> childFieldMap,
      FieldStructure parentFieldStructure,
      List<String> childObjectNames
    ) {
      ParentObjectData parentObjectData = this.validate(childFieldMap);

      if (this.scribe.sObjectType == null) {
        this.scribe.sObjectType = parentObjectData.relationSObjectType;
      }

      String lowerParentObjectIdFieldName = this.scribe.parentRelationIdFieldName.toLowerCase();

      FieldStructure parentFieldStruture = parentFieldStructure.getRelationFieldStructure(
        lowerParentObjectIdFieldName
      );

      childObjectNames.add(parentObjectData.relationFieldName);

      Map<String, Schema.SObjectField> parentFieldMap = parentObjectData
        .relationSObjectType
        .getDescribe()
        .fields
        .getMap();

      return this.scribe.buildGroupByFields(parentFieldMap, parentFieldStruture, childObjectNames);
    }

    private ParentObjectData validate(Map<String, Schema.SObjectField> fieldMap) {
      if (!fieldMap.containsKey(this.relationFieldName)) {
        ApexEloquentException.invalidArgument(
            'Scribe.ParentScribe',
            null,
            'The specified relation ID field does not exist in the object\'s fields',
            'Use a valid relation ID field name on the source object',
            'relationFieldName',
            this.relationFieldName
          )
          .fire();
      }

      Schema.SObjectField relationField = fieldMap.get(this.relationFieldName);
      Schema.DescribeFieldResult relationFieldDescribe = relationField.getDescribe();

      if (relationFieldDescribe.getType() != Schema.DisplayType.REFERENCE) {
        ApexEloquentException.invalidArgument(
            'Scribe.ParentScribe',
            null,
            'The specified relation ID field is not of reference type',
            'Pass a lookup/master-detail field name',
            'relationFieldName',
            this.relationFieldName
          )
          .fire();
      }

      String relationFieldNameString = relationFieldDescribe.getRelationshipName();
      if (relationFieldNameString == null) {
        ApexEloquentException.invalidArgument(
            'Scribe.ParentScribe',
            null,
            'The specified relation ID field does not have a relationship name',
            'Pass a relation ID field that has a defined relationship name',
            'relationFieldName',
            this.relationFieldName
          )
          .fire();
      }

      if (relationFieldDescribe.isNamePointing()) {
        ApexEloquentException.invalidOperation(
            'Scribe.ParentScribe',
            null,
            'Polymorphic relation IDs (pointing to multiple SObject types) are not supported yet'
          )
          .param('relationFieldName', this.relationFieldName)
          .fire();
      }

      Schema.SObjectType relationSObjectType = relationFieldDescribe.getReferenceTo()[0];
      return new ParentObjectData(relationFieldDescribe, relationFieldNameString, relationSObjectType);
    }

    public FieldStructure buildFieldStructure(Map<String, Schema.SObjectField> childFieldMap) {
      ParentObjectData parentObjectData = this.validate(childFieldMap);
      if (this.scribe.sObjectType == null) {
        this.scribe.sObjectType = parentObjectData.relationSObjectType;
      }

      List<String> parentSelects = new List<String>();
      List<String> parentFieldNames = this.scribe.getSelectedFields(
        parentObjectData.relationSObjectType.getDescribe().fields.getMap()
      );
      for (String parentFieldName : parentFieldNames) {
        parentSelects.add(parentFieldName);
      }

      Map<String, FieldStructure> grandParentFieldStructures = new Map<String, FieldStructure>();
      if (!this.scribe.parents.isEmpty()) {
        Map<String, Schema.sObjectField> parentFieldMap = parentObjectData.relationSObjectType.getDescribe()
          .fields.getMap();
        for (ParentScribe grandParentScribe : this.scribe.parents) {
          String grandParentRelationFieldName = grandParentScribe.getRelationFieldName().toLowerCase();
          FieldStructure grandParentFieldStructure = grandParentScribe.buildFieldStructure(parentFieldMap);
          grandParentFieldStructures.put(grandParentRelationFieldName, grandParentFieldStructure);
        }
      }
      return new FieldStructure(parentSelects, grandParentFieldStructures);
    }
  }

  /**
   * Private inner class to represent an ORDER BY clause component.
   */
  private class OrderByClause {
    private Set<String> ORDERS = new Set<String>{ 'ASC', 'DESC' };
    private Set<String> NULLS_OPERATORS = new Set<String>{ 'FIRST', 'LAST' };

    private final String field;
    private final String order;
    private final String nullsOperator;

    public OrderByClause(String field) {
      this.validateField(field);
      this.field = field;
      this.order = 'ASC';
      this.nullsOperator = null;
    }

    public OrderByClause(String field, String order) {
      this.validateField(field);
      this.validateOrder(order);
      this.field = field;
      this.order = order;
      this.nullsOperator = null;
    }

    public OrderByClause(String field, String order, String nullsOperator) {
      this.validateField(field);
      this.validateOrder(order);
      this.validateNullsOperator(nullsOperator);
      this.field = field;
      this.order = order;
      this.nullsOperator = nullsOperator;
    }

    public String build() {
      String orderBy = this.field + ' ' + this.order;
      if (this.nullsOperator != null) {
        orderBy += ' NULLS ' + this.nullsOperator;
      }
      return orderBy;
    }

    private void validateField(String field) {
      if (String.isBlank(field)) {
        ApexEloquentException.required('Scribe.OrderByClause', null, 'field', field).fire();
      }
    }

    private void validateFields(List<String> fields) {
      if (fields == null || fields.isEmpty()) {
        ApexEloquentException.required('Scribe.OrderByClause', null, 'fields', fields).fire();
      }
      for (String field : fields) {
        this.validateField(field);
      }
    }

    private void validateOrder(String order) {
      if (String.isBlank(order) || !this.ORDERS.contains(order.toUpperCase())) {
        ApexEloquentException.invalidArgument(
            'Scribe.OrderByClause',
            null,
            'Invalid order direction for orderBy()',
            'Pass \'ASC\' or \'DESC\'',
            'order',
            order
          )
          .fire();
      }
    }

    private void validateNullsOperator(String nullsOperator) {
      if (String.isBlank(nullsOperator) || !this.NULLS_OPERATORS.contains(nullsOperator.toUpperCase())) {
        ApexEloquentException.invalidArgument(
            'Scribe.OrderByClause',
            null,
            'Invalid nulls operator for orderBy()',
            'Pass \'FIRST\' or \'LAST\'',
            'nullsOperator',
            nullsOperator
          )
          .fire();
      }
    }
  }

  /**
   * Private inner class to represent a GROUP BY clause component.
   */
  private class GroupByClause {
    private final String fieldName;
    private final ParentScribe parentScribe;
    private Boolean isGroupByField = false;
    private Boolean isGroupByParent = false;

    public GroupByClause(String fieldName) {
      if (String.isBlank(fieldName)) {
        ApexEloquentException.required('Scribe.GroupByClause', null, 'fieldName', fieldName).fire();
      }
      this.fieldName = fieldName;
      this.parentScribe = null;
      this.isGroupByField = true;
    }

    public GroupByClause(ParentScribe parentScribe) {
      if (parentScribe == null) {
        ApexEloquentException.required('Scribe.GroupByClause', null, 'parentScribe', parentScribe).fire();
      }
      this.fieldName = null;
      this.parentScribe = parentScribe;
      this.isGroupByParent = true;
    }

    public List<String> buildGroupField(
      Schema.DescribeSObjectResult describe,
      FieldStructure fieldStructure,
      Map<String, Schema.SObjectField> fieldMap,
      List<String> childObjectNames
    ) {
      if (this.isGroupByField) {
        String lowerFieldName = this.fieldName.toLowerCase();
        if (!fieldMap.containsKey(lowerFieldName)) {
          ApexEloquentException.invalidArgument(
              'Scribe.GroupByClause',
              null,
              'The specified group by field does not exist in the object\'s fields',
              'Pass a field name that exists on the SObject',
              'fieldName',
              this.fieldName
            )
            .param('objectName', describe.getName())
            .fire();
        }

        fieldStructure.removeField(lowerFieldName);

        String groupField = childObjectNames.isEmpty()
          ? this.fieldName
          : String.join(childObjectNames, '.') + '.' + this.fieldName;
        return new List<String>{ groupField };
      }

      return this.parentScribe.buildGroupByClause(fieldMap, fieldStructure, childObjectNames);
    }
  }

  /**
   * Private inner class to store metadata about an aggregate function alias.
   */
  private class AliasStructure {
    private final String fieldName;
    private final String aggregateClause;
    private final Map<String, Schema.SObjectField> fieldMap;

    public AliasStructure(String fieldName, String aggregateClause, Map<String, Schema.SObjectField> fieldMap) {
      this.fieldName = fieldName;
      this.aggregateClause = aggregateClause;
      this.fieldMap = fieldMap;
    }

    public String getFieldName() {
      return this.fieldName;
    }

    public String getAggregateClause() {
      return this.aggregateClause;
    }

    public Map<String, Schema.SObjectField> getFieldMap() {
      return this.fieldMap;
    }
  }
}
