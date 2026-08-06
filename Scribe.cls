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
        clause = String.format('({0})', new List<String>{ groupWhereClauseData.whereClauseString });
        isLastOperatorOr = conditionPart.isOr;
      } else if (conditionPart.parentScribe != null) {
        ParentScribe parentScribe = conditionPart.parentScribe;
        WhereClauseData parentWhereClauseData = parentScribe.buildWhereClause(fieldMap, childObjectName);
        clause = parentWhereClauseData.whereClauseString;
        isLastOperatorOr = parentWhereClauseData.isLastOperatorOr;
        conditionPart.isOr = parentWhereClauseData.isFirstOperatorOr;
      }

      if (String.isNotBlank(clause)) {
        if (String.isNotBlank(whereClauseString)) {
          whereClauseString += conditionPart.isOr ? ' OR ' : ' AND ';
        }
        whereClauseString += clause;
      }
    }

    return new WhereClauseData(whereClauseString, isFirstOperatorOr, isLastOperatorOr);
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
