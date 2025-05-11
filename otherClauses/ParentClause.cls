public with sharing class ParentClause {
  private String relationFieldName;
  private Query parentQuery;

  /**
   * constroctor with multiple parent field names
   *
   * @param relationFieldName The name of the relationship Field
   * @param parentFields The names of the parent fields
   */
  public ParentClause(String relationFieldName, Query parentQuery) {
    this.relationFieldName = relationFieldName;
    this.parentQuery = parentQuery;
  }

  /**
   * Constructs the relationship names of parent fields using the specified field map.
   *
   * @param childFieldMap A mapping of object field names to Schema.SObjectField
   * @return A comma-separated string of parent field relationship names
   * @throws QueryException If the parent field list is empty
   * @throws QueryException If the specified relationship ID field does not exist in the field map
   * @throws QueryException If the specified relationship ID field is not of a reference type
   * @throws QueryException If the specified relationship ID field does not have a relationship name
   */
  public String buildSelectClause(Map<String, Schema.SObjectField> childFieldMap, String childObjectName) {
    Validated validated = this.validate(childFieldMap);

    List<String> parentSelects = new List<String>();
    for (String parentFieldName : this.parentQuery.getSelectFields()) {
      String parentSelect = '';
      if (childObjectName != null) {
        parentSelect = childObjectName + '.';
      }
      parentSelect += validated.relationName + '.' + parentFieldName;
      parentSelects.add(parentSelect);
    }

    if (this.parentquery.hasParent()) {
      if (childObjectName == null) {
        childObjectName = validated.relationName;
      } else {
        childObjectName += '.' + validated.relationName;
      }
      for (ParentClause grandParentClause : this.parentQuery.getParents()) {
        Map<String, Schema.SObjectField> parentFieldMap = validated.relationSObjectType.getDescribe().fields.getMap();
        String grandParentSelectsAsString = grandParentClause.buildSelectClause(parentFieldMap, childObjectName);
        parentSelects.add(grandParentSelectsAsString);
      }
    }
    if (parentSelects.isEmpty()) {
      throw new QueryException('The parent fields list is empty');
    }
    return String.join(parentSelects, ', ');
  }

  public String buildWhereClause(Map<String, Schema.SObjectField> fieldMap, String childObjectName) {
    return buildCombinedWhereClause(fieldMap, childObjectName, ' AND ');
  }

  public String buildOrWhereClause(Map<String, Schema.SObjectField> fieldMap, String childObjectName) {
    return buildCombinedWhereClause(fieldMap, childObjectName, ' OR ');
  }

  private String buildCombinedWhereClause(Map<String, Schema.SObjectField> fieldMap, String childObjectName, String separator) {
    Validated validated = this.validate(fieldMap);

    List<WhereClauseInterface> whereClauses = separator == ' AND ' ? this.parentQuery.getAndWhereClauses() : this.parentQuery.getOrWhereClauses();

    if (whereClauses.isEmpty() && !this.parentQuery.hasParent()) {
      return '';
    }

    if (childObjectName == null) {
      childObjectName = validated.relationName;
    } else {
      childObjectName += '.' + validated.relationName;
    }

    List<String> whereClauseStrings = new List<String>();
    Schema.SObjectType parentSObjectType = validated.relationSObjectType;
    Map<String, Schema.SObjectField> parentFieldMap = parentSObjectType.getDescribe().fields.getMap();

    for (WhereClauseInterface whereClause : whereClauses) {
      WhereClauseInterface whereClauseWithSource = whereClause.overrideMetaData(parentSObjectType, parentFieldMap);
      String whereClauseAsString = whereClauseWithSource.build();
      whereClauseStrings.add(childObjectName + '.' + whereClauseAsString);
    }

    if (this.parentQuery.hasParent()) {
      for (ParentClause grandParentClause : this.parentQuery.getParents()) {
        String grandParentWhereClauseAsString = '';
        if (separator == ' AND ') {
          grandParentWhereClauseAsString = grandParentClause.buildWhereClause(parentFieldMap, childObjectName);
        } else {
          grandParentWhereClauseAsString = grandParentClause.buildOrWhereClause(parentFieldMap, childObjectName);
        }
        whereClauseStrings.add(grandParentWhereClauseAsString);
      }
    }

    return String.join(whereClauseStrings, separator);
  }

  private Validated validate(Map<String, Schema.SObjectField> fieldMap) {
    if (!fieldMap.containsKey(this.relationFieldName)) {
      throw new QueryException('The specified relation ID field does not exist in the object\'s fields. field name: ' + this.relationFieldName);
    }

    Schema.SObjectField relationField = fieldMap.get(this.relationFieldName);
    Schema.DescribeFieldResult relationFieldDescribe = relationField.getDescribe();

    if (relationFieldDescribe.getType() != Schema.DisplayType.REFERENCE) {
      throw new QueryException('The specified relation ID field is not of reference type. field name: ' + this.relationFieldName);
    }

    String relationName = relationFieldDescribe.getRelationshipName();
    if (relationName == null) {
      throw new QueryException('The specified relation ID field does not have a relationship name. field name: ' + this.relationFieldName);
    }

    if (relationFieldDescribe.isNamePointing()) {
      throw new QueryException('Sorry, we don\'t support relation IDs that can point to multiple SObject types yet. ' + this.relationFieldName);
    }

    Schema.SObjectType relationSObjectType = relationFieldDescribe.getReferenceTo()[0];
    return new Validated(relationFieldDescribe, relationName, relationSObjectType);
  }

  private class Validated {
    public Schema.DescribeFieldResult relationFieldDescribe;
    public String relationName;
    public Schema.SObjectType relationSObjectType;

    public Validated(Schema.DescribeFieldResult relationFieldDescribe, String relationName, Schema.SObjectType relationSObjectType) {
      this.relationFieldDescribe = relationFieldDescribe;
      this.relationName = relationName;
      this.relationSObjectType = relationSObjectType;
    }
  }
}
