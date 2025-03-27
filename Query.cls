public class Query {
  private final Schema.SObjectType sObjectType;
  private final List<String> selectFields;
  private final List<Query> children;
  private final List<WhereClauseInterface> andWhereClauses;
  private final List<WhereClauseInterface> orWhereClauses;
  private final List<Query> andQueries;
  private final List<Query> orQueries;
  private final List<WhereClauseInterface> joinClauses;
  private final boolean isSelectAll;
  private final OrderByClause orderByClause;
  private final Integer limitNumber;

  /**
   * default constructor
   */
  public Query() {
    this.sObjectType = null;
    this.selectFields = new List<String>();
    this.children = new List<Query>();
    this.andWhereClauses = new List<WhereClauseInterface>();
    this.orWhereClauses = new List<WhereClauseInterface>();
    this.andQueries = new List<Query>();
    this.orQueries = new List<Query>();
    this.joinClauses = new List<WhereClauseInterface>();
    this.isSelectAll = false;
    this.limitNumber = null;
  }

  /**
   * constructor
   */
  public Query(
    Schema.SObjectType sObjectType,
    List<String> selectFields,
    List<Query> children,
    List<WhereClauseInterface> andWhereClauses,
    List<WhereClauseInterface> orWhereClauses,
    List<Query> andQueries,
    List<Query> orQueries,
    List<WhereClauseInterface> joinClauses,
    Boolean isSelectAll,
    OrderByClause orderByClause,
    Integer limitNumber
  ) {
    this.sObjectType = sObjectType;
    this.selectFields = selectFields;
    this.children = children;
    this.andWhereClauses = andWhereClauses;
    this.orWhereClauses = orWhereClauses;
    this.andQueries = andQueries;
    this.orQueries = orQueries;
    this.joinClauses = joinClauses;
    this.isSelectAll = isSelectAll;
    this.orderByClause = orderByClause;
    this.limitNumber = limitNumber;
  }

  // ---------- FROM clause ----------
  /**
  * Sets the source (FROM) of the query.
  * Please specify the sObjectType argument as follows:
  * .source(Opportunity.getSObjectType())
  *
  * @param sObjectType: The sObjectType of the source object
  * @return Query
  */
  public Query source(Schema.SObjectType sObjectType) {
    return new Query(
      sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  // ---------- SELECT clause ----------
  /**
  * Sets the fields (SELECT) of the query.
  *
  * @param selectField: The name of the field to select
  * @return Query
  */
  public Query pick(String selectField) {
    List<String> newSelectFields = this.selectFields;
    newSelectFields.add(selectField);
    return new Query(
      this.sObjectType,
      newSelectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }


  /**
  * Sets the fields (SELECT) of the query.
  *
  * @param selectFields: The fields to select (multiple)
  * @return Query
  */
  public Query pick(List<String> selectFields) {
    List<String> newSelectFields = this.selectFields;
    newSelectFields.addAll(selectFields);
    return new Query(
      this.sObjectType,
      newSelectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  /**
  * Selects all fields.
  *
  * @return Query
  */
  public Query pickAll() {
    return new Query(
      this.sObjectType,
      new List<String>(),
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      true,
      this.orderByClause,
      this.limitNumber
    );
  }


  /**
  * Add Child query
  *
  * @param child: The child query to be added
  * @return A new Query object with the child query added
  */
  public Query withChildren(Query child) {
    List<Query> newChildren = this.children;
    newChildren.add(child);
    return new Query(
      this.sObjectType,
      this.selectFields,
      newChildren,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  // ---------- WHERE clause (add one field) ----------
  /**
  * Sets the WHERE (AND) condition.
  *
  * @param field: The field name
  * @param operator: The operator
  * @param value: The value
  * @return Query
  */
  public Query condition(String field, String operator, Object value) {
    WhereClauseInterface whereClause = WhereClauseFactory.create(this.sObjectType, field, operator, value);
    List<WhereClauseInterface> newWhereClauses = this.andWhereClauses;
    newWhereClauses.add(whereClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      newWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  /**
  * Sets the WHERE (OR) condition.
  *
  * @param field: The field name
  * @param operator: The operator
  * @param value: The value
  * @return Query
  */
  public Query orCondition(String field, String operator, Object value) {
    if (this.andWhereClauses.isEmpty() && this.orWhereClauses.isEmpty()) {
      throw new QueryException('The first condition must be specified as an AND condition');
    }
    WhereClauseInterface whereClause = WhereClauseFactory.create(this.sObjectType, field, operator, value);
    List<WhereClauseInterface> newWhereClauses = this.orWhereClauses;
    newWhereClauses.add(whereClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      newWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  // ---------- WHERE clause(add multiple fields) ----------
  /**
  * Sets the WHERE (AND) condition.
  *
  * @param field: The field name
  * @param operator: The operator
  * @param values: The values (multiple)
  * @return Query
  */
  public Query condition(String field, String operator, List<Object> values) {
    if(values.isEmpty()) {
      // Convert to a condition that never hits if an empty list is passed
      return this.condition('Id', '=', (Object) null);
    }
    WhereClauseInterface whereClause = WhereClauseFactory.create(this.sObjectType, field, operator, values);
    List<WhereClauseInterface> newWhereClauses = this.andWhereClauses;
    newWhereClauses.add(whereClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      newWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  /**
  * Sets the WHERE (OR) condition.
  * Cannot be combined with join clauses.
  *
  * @param field: The field name
  * @param operator: The operator
  * @param values: The values (multiple)
  * @return Query
  */
  public Query orCondition(String field, String operator, List<Object> values) {
    if (this.andWhereClauses.isEmpty() && this.orWhereClauses.isEmpty()) {
      throw new QueryException('The first condition must be specified as an AND condition');
    }
    if(values.isEmpty()) {
      // Convert to a condition that never hits if an empty list is passed
      return this.orCondition('Id', '=', (Object) null); 
    }
    WhereClauseInterface whereClause = WhereClauseFactory.create(this.sObjectType, field, operator, values);
    List<WhereClauseInterface> newWhereClauses = this.orWhereClauses;
    newWhereClauses.add(whereClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      newWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  // ---------- WHERE clause (add conditions enclosed in parentheses in the query) ----------
  /**
  * Sets the WHERE (AND) condition.
  * You can add conditions enclosed in parentheses using a query.
  *
  * @param query: The query
  * @return Query
  */
  public Query condition(Query query) {
    List<Query> newAndQueries = this.andQueries;
    newAndQueries.add(query);

    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      newAndQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  /**
  * Sets the WHERE (OR) condition.
  * You can add conditions enclosed in parentheses using a query.
  * Cannot be combined with join clauses.
  *
  * @param query: The query
  * @return Query
  */
  public Query orCondition(Query query) {
    if (this.andWhereClauses.isEmpty() && this.orWhereClauses.isEmpty()) {
      throw new QueryException('The first condition must be specified as an AND condition');
    }
    List<Query> newOrQueries = this.orQueries;
    newOrQueries.add(query);

    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      newOrQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  // ---------- join clause ----------
  /**
  * Sets the JOIN clause.
  * Cannot be combined with OR conditions.
  *
  * @param field: The field name
  * @param operator: The operator
  * @param subQuery: The subquery
  * @return Query
  */
  public Query join(String field, String operator, Query subQuery) {
    List<WhereClauseInterface> newJoinClauses = this.joinClauses;
    WhereClauseInterface joinClause = WhereClauseFactory.create(this.sObjectType, field, operator, subQuery);
    newJoinClauses.add(joinClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      newJoinClauses,
      this.isSelectAll,
      this.orderByClause,
      this.limitNumber
    );
  }

  // ---------- limit clause ----------
  /**
  * Sets the LIMIT clause.
  *
  * @param limitNumber: The number of records to retrieve
  * @return Query
  */
  public Query restrict(Integer limitNumber) {
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      this.orderByClause,
      limitNumber
    );
  }

  // ---------- ORDER BY clause ----------
  /**
  * Sets the ORDER BY clause.
  *
  * @param field: The field name
  * @return Query
  */
  public Query orderBy(String field) {
    OrderByClause orderByClause = new OrderByClause(field);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      orderByClause,
      this.limitNumber
    );
  }

  /**
  * Sets the ORDER BY clause.
  *
  * @param field: The field name
  * @param order: The sort order
  * @return Query
  */
  public Query orderBy(String field, String order) {
    OrderByClause orderByClause = new OrderByClause(field, order);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      orderByClause,
      this.limitNumber
    );
  }

  /**
  * Sets the ORDER BY clause.
  *
  * @param field: The field name
  * @param order: The sort order
  * @param nullsOperator: The order for NULLS
  * @return Query
  */
  public Query orderBy(String field, String order, String nullsOperator) {
    OrderByClause orderByClause = new OrderByClause(field, order, nullsOperator);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      orderByClause,
      this.limitNumber
    );
  }

  /**
  * Sets the ORDER BY clause.
  *
  * @param fields: The field names (multiple)
  * @return Query
  */
  public Query orderBy(List<String> fields) {
    OrderByClause orderByClause = new OrderByClause(fields);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      orderByClause,
      this.limitNumber
    );
  }

  /**
  * Sets the ORDER BY clause.
  *
  * @param fields: The field names (multiple)
  * @param order: The sort order
  * @return Query
  */
  public Query orderBy(List<String> fields, String order) {
    OrderByClause orderByClause = new OrderByClause(fields, order);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      orderByClause,
      this.limitNumber
    );
  }

  /**
  * Sets the ORDER BY clause.
  *
  * @param fields: The field names (multiple)
  * @param order: The sort order
  * @param nullsOperator: The order for NULLS
  * @return Query
  */
  public Query orderBy(List<String> fields, String order, String nullsOperator) {
    OrderByClause orderByClause = new OrderByClause(fields, order, nullsOperator);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.children,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll,
      orderByClause,
      this.limitNumber
    );
  }


  // ---------- Useful methods ----------
  /**
  * Adds a condition to retrieve records by specifying the Id.
  *
  * @param recordId: The record Id
  * @return Query
  */
  public Query find(Id recordId) {
    return this.condition('Id', '=', recordId);
  }

  /**
  * Adds a condition to retrieve records by specifying multiple IDs.
  *
  * @param recordIds: The record IDs (multiple)
  * @return Query
  */
  public Query findMany(List<Id> recordIds) {
    return this.condition('Id', 'IN', recordIds);
  }

  /**
  * Adds a condition to retrieve records where the field value is between from and to (inclusive).
  *
  * @param field: The field name
  * @param fromValue: The lower bound of the range
  * @param toValue: The upper bound of the range
  * @return Query
  */
  public Query betweenInclusive(String field, Object fromValue, Object toValue) {
    return this.condition(field, '>=', fromValue).condition(field, '<=', toValue);
  }

  /**
  * Adds a condition to retrieve records where the field value is between from and to (exclusive).
  *
  * @param field: The field name
  * @param fromValue: The lower bound of the range
  * @param toValue: The upper bound of the range
  * @return Query
  */
  public Query betweenExclusive(String field, Object fromValue, Object toValue) {
    return this.condition(field, '>', fromValue).condition(field, '<', toValue);
  }

  /**
  * Sets a condition where the specified field is NULL.
  *
  * @param field: The name of the field
  * @return Query
  */
  public Query isNull(String field) {
    return this.condition(field, '=', (Object) null);
  }

  /**
  * Sets a condition where the specified field is NOT NULL.
  *
  * @param field: The name of the field
  * @return Query
  */
  public QUery isNotNull(String field) {
    return this.condition(field, '!=', (Object) null);
  }

  // ---------- Concatenate and output the state of the WHERE clause ----------

  // ---------- generate SOQL ----------
  /**
  * Generates the SOQL query.
  *
  * @return The SOQL query
  */
  public String toSoql() {
    this.validateParams();

    Map<String, Schema.SObjectField> fieldMap = this.sObjectType.getDescribe().fields.getMap();

    String selectFieldsString = this.buildSelectFields(fieldMap);
    String fromString = this.sObjectType.getDescribe().getName();

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });
    query = this.buildQueryTrail(query, fieldMap);

    System.debug('SOQL: ' + query);
    return query;
  }

  /**
  * Generate the Children SOQL query.
  *
  * @return The SOQL query
  */
  private String toChildrenSoql() {
    this.validateParams();

    Map<String, Schema.SObjectField> fieldMap = this.sObjectType.getDescribe().fields.getMap();

    String selectFieldsString = this.buildSelectFields(fieldMap);
    
    String fromString;
    Boolean isCustom = this.sObjectType.getDescribe().isCustom();
    String objectName = this.sObjectType.getDescribe().getName();
    if(isCustom) {
      fromString = objectName.left(objectName.length() -1) + 'r';
    } else {
      fromString = this.generatePluralName(objectName);
    }

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });
    query = this.buildQueryTrail(query, fieldMap);

    return query;
  }

  /**
  * A method to construct the portion of a SOQL query following the WHERE clause 
  * (including WHERE clause, LIMIT clause, and ORDER BY clause).
  *
  * @param query The SOQL query string to be constructed
  * @param fieldMap A mapping of field names to Schema.SObjectField
  * @return The constructed SOQL query string
  */
  private String buildQueryTrail(String query, Map<String, Schema.SObjectField> fieldMap){
    String whereClause = this.buildWhereClause(fieldMap);
    if (whereClause != '') {
      query += ' WHERE ' + whereClause;
    }

    if(this.limitNumber != null) {
      query += ' LIMIT ' + this.limitNumber;
    }

    if(this.orderByClause != null) {
      query += ' ' + this.orderByClause.build();
    }

    return query;
  }

  /**
  * Validates the parameters.
  */
  private void validateParams() {
    Boolean isSObjectTypeNull = this.sObjectType == null;
    if (isSObjectTypeNull) {
      throw new QueryException('source is not set');
    }
    if (this.selectFields.isEmpty() && !this.isSelectAll) {
      throw new QueryException('pick is not set');
    }
  }

  /**
  * A method to construct the SELECT clause of a SOQL query based on the specified field map.
  *
  * @param fieldMap A mapping of field names to Schema.SObjectField
  * @return The constructed SELECT clause as a string
  */
  private String buildSelectFields(Map<String, Schema.SObjectField> fieldMap) {
    String selectFieldsString = '';
    if (this.isSelectAll) {
      for (String fieldName : fieldMap.keyset()) {
        if (selectFieldsString == null || selectFieldsString == '') {
          selectFieldsString = fieldName;
        } else {
          selectFieldsString = selectFieldsString + ', ' + fieldName;
        }
      }
    } else {
      selectFieldsString = String.join(this.selectFields, ', ');
    }

    for(Query child : this.children) {
      selectFieldsString += ', (' + child.toChildrenSoql() + ')';
    }

    return selectFieldsString;
  }

  /**
  * Constructs the WHERE clause.
  *
  * @param fieldMap: The map of fields
  * @return The constructed WHERE clause
  */
  private String buildWhereClause(Map<String, Schema.SObjectField> fieldMap) {
    Boolean hasOrCondition = false;

    String whereClauseString = '';

    if (!this.andWhereClauses.isEmpty()) {
      whereClauseString += '(';
      List<String> whereClauseStrings = new List<String>();
      for (WhereClauseInterface whereClause : this.andWhereClauses) {
        WhereClauseInterface whereClauseWithSource = whereClause.overrideMetaData(this.sObjectType, fieldMap);
        whereClauseStrings.add(whereClauseWithSource.build());
      }
      whereClauseString += String.join(whereClauseStrings, ' AND ');
      whereClauseString += ')';
    }

    if (!this.orWhereClauses.isEmpty()) {
      hasOrCondition = true;
      if (whereClauseString != '') {
        whereClauseString += ' OR ';
      }
      whereClauseString += '(';
      List<String> whereClauseStrings = new List<String>();
      for (WhereClauseInterface whereClause : this.orWhereClauses) {
        WhereClauseInterface whereClauseWithSource = whereClause.overrideMetaData(this.sObjectType, fieldMap);
        whereClauseStrings.add(whereClauseWithSource.build());
      }
      whereClauseString += String.join(whereClauseStrings, ' OR ');
      whereClauseString += ')';
    }

    if (!this.andQueries.isEmpty()) {
      if (whereClauseString != '') {
        whereClauseString += ' AND ';
      }
      List<String> whereClauseStrings = new List<String>();
      for (Query query : this.andQueries) {
        Query queryWithSource = new Query(
          this.sObjectType,
          query.selectFields,
          query.children,
          query.andWhereClauses,
          query.orWhereClauses,
          query.andQueries,
          query.orQueries,
          query.joinClauses,
          query.isSelectAll,
          query.orderByClause,
          query.limitNumber
        );
        whereClauseStrings.add('(' + queryWithSource.buildWhereClause(fieldMap) + ')');
      }
      whereClauseString += String.join(whereClauseStrings, ' AND ');
    }

    if (!this.orQueries.isEmpty()) {
      hasOrCondition = true;
      if (whereClauseString != '') {
        whereClauseString += ' OR ';
      }
      List<String> whereClauseStrings = new List<String>();
      for (Query query : this.orQueries) {
        Query queryWithSource = new Query(
          this.sObjectType,
          query.selectFields,
          query.children,
          query.andWhereClauses,
          query.orWhereClauses,
          query.andQueries,
          query.orQueries,
          query.joinClauses,
          query.isSelectAll,
          query.orderByClause,
          query.limitNumber
        );
        whereClauseStrings.add('(' + queryWithSource.buildWhereClause(fieldMap) + ')');
      }
      whereClauseString += String.join(whereClauseStrings, ' OR ');
    }

    if (!this.joinClauses.isEmpty()) {
      if (hasOrCondition) {
        String error = 'Subqueries in joins cannot be placed inside nests, and combining with OR requires nesting, so this combination cannot be executed.';
        throw new QueryException(error);
      }
      for (WhereClauseInterface joinClause : this.joinClauses) {
        if (whereClauseString != '') {
          whereClauseString += ' AND ';
        }
        whereClauseString += '(' + joinClause.build() + ')';
      }
    }

    return whereClauseString;
  }

  /**
  * A method to generate a plural name based on the specified object name.
  *
  * @param objectName The singular form of the object name
  * @return The generated plural form of the object name
  */
  private String generatePluralName(String objectName) {
    if (objectName.endsWith('y')) {
        return objectName.left(objectName.length() - 1) + 'ies'; // ex) "Company" → "Companies"
    } else if (objectName.endsWith('s') || objectName.endsWith('x') || objectName.endsWith('z')) {
        return objectName + 'es'; // ex) "Box" → "Boxes"
    } else {
        return objectName + 's'; // ex) "Car" → "Cars"
    }
  }
}
