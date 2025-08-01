public with sharing class Scribe {
  @TestVisible
  private Schema.SObjectType sObjectType;
  @TestVisible
  private Set<String> selectFields = new Set<String>();
  private List<ConditionPart> conditionParts = new List<ConditionPart>();
  private List<Scribe> children = new List<Scribe>();
  private List<ParentScribe> parents = new List<ParentScribe>();

  private Boolean isSelectAll = false;
  private Boolean isNextConditionOr = false;
  private Boolean canOnlyAddOrCondition = false;

  private final Integer MAX_NESTING_DEPTH = 4;

  /**
   * constructor
   *
   * @param sObjectType 対象のSObjectType
   * @throws QueryException SObjectTypeがnullの場合
   */
  public Scribe(Schema.SObjectType sObjectType) {
    this.sObjectType = sObjectType;
  }

  // ------------ static methods ------------
  /**
   * Scribeのsource(FROM) をセットします。
   * 次のように使用します。
   * .source(Opportunity.getSObjectType())
   *
   * @param sObjectType 対象のsObjectType
   * @return Scribe インスタンス
   */
  public static Scribe source(Schema.SObjectType sObjectType) {
    Scribe newScribe = new Scribe(sObjectType);
    return newScribe;
  }

  public static Scribe group() {
    return new Scribe(null);
  }

  // ------------ select methods ------------

  public Scribe field(String fieldName) {
    if (String.isBlank(fieldName)) {
      throw new QueryException('フィールド名が空です。');
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.selectFields.add(fieldName);

    return clonedScribe;
  }

  public Scribe fields(List<String> fieldNames) {
    if (fieldNames == null || fieldNames.isEmpty()) {
      throw new QueryException('フィールド名のリストが空です。');
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.selectFields.addAll(new Set<String>(fieldNames));

    return clonedScribe;
  }

  // ------------ add OR methods ------------
  public Scribe orCondition() {
    this.validateOrConditionNotAllowed();

    Scribe clonedScribe = this.deepClone();

    if (clonedScribe.conditionParts.isEmpty()) {
      throw new QueryException(
        'OR条件を最初に設定することはできません。where系メソッドを使用してAND条件を追加してください。'
      );
    }
    clonedScribe.isNextConditionOr = true;
    clonedScribe.canOnlyAddOrCondition = true;

    return clonedScribe;
  }

  // ------------ where methods ------------

  public Scribe whereEqual(String fieldName, Object value) {
    this.validateConditionClause(fieldName);

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

    return clonedScribe;
  }

  public Scribe whereNotEqual(String fieldName, Object value) {
    this.validateConditionClause(fieldName);

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

    return clonedScribe;
  }

  public Scribe whereGreaterThan(String fieldName, Object value) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new GreaterThanConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      value
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereGreaterThanOrEqual(String fieldName, Object value) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new GreaterThanOrEqualConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      value
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereLessThan(String fieldName, Object value) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new LessThanConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      value
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereLessThanOrEqual(String fieldName, Object value) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new LessThanOrEqualConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      value
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereLike(String fieldName, String value) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new LikeConditionClause(clonedScribe.sObjectType, null, fieldName, value);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereNotLike(String fieldName, String value) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new NotLikeConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      value
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereIn(String fieldName, Object values) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new InConditionClause(clonedScribe.sObjectType, null, fieldName, values);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereIn(String fieldName, Scribe subQuery) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    if (clonedScribe.isNextConditionOr) {
      throw new QueryException(
        'OR条件の後にINサブクエリを追加することはできません。クエリの分割や見直しを検討してください。'
      );
    }

    IConditionClause conditionClause = new InSubQueryConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      subQuery
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereNotIn(String fieldName, Object values) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new NotInConditionClause(clonedScribe.sObjectType, null, fieldName, values);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereNotIn(String fieldName, Scribe subQuery) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    if (clonedScribe.isNextConditionOr) {
      throw new QueryException(
        'OR条件の後にNOT INサブクエリを追加することはできません。クエリの分割や見直しを検討してください。'
      );
    }

    IConditionClause conditionClause = new NotInSubQueryConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      subQuery
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereIncludes(String fieldName, List<String> values) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new IncludesConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      values
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereExcludes(String fieldName, List<String> values) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new ExcludeConditionClause(
      clonedScribe.sObjectType,
      null,
      fieldName,
      values
    );
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereNull(String fieldName) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IconditionClause conditionClause = new IsNullConditionClause(clonedScribe.sObjectType, null, fieldName);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereNotNull(String fieldName) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IconditionClause conditionClause = new IsNotNullConditionClause(clonedScribe.sObjectType, null, fieldName);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  // ------------ group methods ------------

  public Scribe group(Scribe groupScribe) {
    this.validateConditionOperator();

    if (groupScribe == null) {
      throw new QueryException('グループ化するScribeがnullです。');
    }

    Scribe clonedScribe = this.deepClone();
    Conditionpart groupConditionPart = new ConditionPart(groupScribe, this.isNextConditionOr);
    clonedScribe.sObjectType = this.sObjectType;
    clonedScribe.conditionParts.add(groupConditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }


  // ------------ add relation methods ------------

  public Scribe withChildren(Scribe childScribe) {
    this.validateOrConditionNotAllowed();

    if (childScribe == null) {
      throw new QueryException('子のScribeがnullです。');
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.children.add(childScribe);

    return clonedScribe;
  }

  public Scribe whereParent(String relationIdFieldName, Scribe parentScribe) {
    this.validateConditionOperator();

    if (parentScribe == null) {
      throw new QueryException('親のScribeがnullです。');
    }

    Scribe clonedScribe = this.deepClone();
    ConditionPart parentConditionPart = new ConditionPart(new ParentScribe(relationIdFieldName, parentScribe));
    clonedScribe.conditionParts.add(parentConditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe parentField(String relationIdFieldName, Scribe parentScribe) {
    this.validateOrConditionNotAllowed();

    if (parentScribe == null) {
      throw new QueryException('親のScribeがnullです。');
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.parents.add(new ParentScribe(relationIdFieldName, parentScribe));

    return clonedScribe;
  }

  public String toSoql() {
    this.validateAndInitialize();

    Map<String, Schema.SObjectField> fieldMap = this.sObjectType.getDescribe().fields.getMap();

    String selectFieldsString = this.buildSelectFields(fieldMap, 0);
    String fromString = this.sObjectType.getDescribe().getName();

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });

    query = this.buildQueryTrail(query, fieldMap);

    System.debug('SOQL Query: ' + query);
    return query;
  }

  private String buildQueryTrail(String query, Map<String, Schema.SObjectField> fieldMap) {
    String whereString = this.buildWhereClause(fieldMap);
    if (whereString != '') {
      query += ' WHERE ' + whereString;
    }

    return query;
  }

  /**
   * get selected Fields.
   *
   * @param parentSObjectType: The parent SObject type
   * @return selected fields list
   */
  public List<String> getSelectedFields(Map<String, Schema.SObjectField> fieldMap) {
    List<String> selectFields = new List<String>();

    if (this.isSelectAll) {
      for (String fieldName : fieldMap.keyset()) {
        selectFields.add(fieldName.toLowerCase());
      }
    } else {
      for (String fieldName : this.selectFields) {
        selectFields.add(fieldName.toLowerCase());
      }
    }

    return selectFields;
  }

  // ------------ private methods ------------
  private Scribe deepClone() {
    Scribe newScribe = new Scribe(this.sObjectType);
    newScribe.selectFields = this.selectFields.clone();
    newScribe.conditionParts = this.conditionParts.clone();
    newScribe.children = this.children.clone();
    newScribe.parents = this.parents.clone();

    newScribe.isSelectAll = this.isSelectAll;
    newScribe.isNextConditionOr = this.isNextConditionOr;
    newScribe.canOnlyAddOrCondition = this.canOnlyAddOrCondition;

    return newScribe;
  }

  // ------------ validation methods ------------

  private void validateConditionClause(String fieldName) {
    if (String.isBlank(fieldName)) {
      throw new QueryException('フィールド名が空です。');
    }
    this.validateConditionOperator();
  }

  private void validateConditionOperator() {
    if (this.canOnlyAddOrCondition && !this.isNextConditionOr) {
      throw new QueryException(
        'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。'
      );
    }
  }

  private void validateOrConditionNotAllowed() {
    if (this.isNextConditionOr) {
      throw new QueryException(
        'orConditionメソッドに続くメソッドはWhere系もしくはgroupメソッドでなければなりません。'
      );
    }
  }

  /**
   * Validates the parameters.
   */
  private void validateAndInitialize() {
    Boolean isSObjectTypeNull = this.sObjectType == null;
    if (isSObjectTypeNull) {
      throw new QueryException('source is not set');
    }
    if (this.selectFields.isEmpty() && !this.isSelectAll) {
      this.selectFields.add('Id');
    }
  }

  /**
   * A method to construct the SELECT clause of a SOQL query based on the specified field map.
   *
   * @param fieldMap A mapping of field names to Schema.SObjectField
   * @return The constructed SELECT clause as a string
   */
  private String buildSelectFields(Map<String, Schema.SObjectField> fieldMap, Integer lowerNestingDepth) {
    // add select fields
    String selectFieldsString = String.join(this.getSelectedFields(fieldMap), ', ');

    // Add parent queries
    for (ParentScribe parent : this.parents) {
      selectFieldsString += ', ' + parent.buildSelectClause(fieldMap, null);
    }

    // Add child queries
    if (!this.children.isEmpty()) {
      lowerNestingDepth++;
      if (lowerNestingDepth > this.MAX_NESTING_DEPTH) {
        List<String> overNestedChildrenNames = new List<String>();
        for (Scribe child : this.children) {
          overNestedChildrenNames.add(child.sObjectType.getDescribe().getName());
        }
        String error = String.format(
          'ネストの深度が最大値を超えました。最大ネスト深度: {0}, オブジェクト名: {1}',
          new List<String>{ String.valueOf(this.MAX_NESTING_DEPTH), String.join(overNestedChildrenNames, ', ') }
        );
        throw new QueryException(error);
      }
      for (Scribe child : this.children) {
        selectFieldsString += String.format(
          ', ({0})',
          new List<String>{ child.buildChildSoql(this.sObjectType, lowerNestingDepth) }
        );
      }
    }

    return selectFieldsString;
  }

  private String buildWhereClause(Map<String, Schema.SObjectField> fieldMap) {
    String whereClauseString = '';

    if (this.conditionParts.isEmpty() && this.parents.isEmpty()) {
      return '';
    }

    for (ConditionPart conditionPart : this.conditionParts) {
      String clause = '';
      if (conditionPart.condition != null) {
        IConditionClause condition = conditionPart.condition.overrideMetaData(this.sObjectType, fieldMap);
        clause = condition.build();
      } else if (conditionPart.groupScribe != null) {
        Scribe groupScribe = conditionPart.groupScribe;
        groupScribe.sObjectType = this.sObjectType;
        clause = String.format('({0})', new List<String>{ groupScribe.buildWhereClause(fieldMap) });
      }

      if (clause != '') {
        if (whereClauseString != '') {
          whereClauseString += conditionPart.isOr ? ' OR ' : ' AND ';
        }
        whereClauseString += clause;
      }
    }

    for (ParentScribe parent : this.parents) {
      String parentWhereClause = parent.buildWhereClause(fieldMap, null);
      if (parentWhereClause != '') {
        if (whereClauseString != '') {
          whereClauseString += ' AND ';
        }
        whereClauseString += parentWhereClause;
      }
    }

    return whereClauseString;
  }

  private String buildChildSoql(Schema.SObjectType parentSObjectType, Integer lowerNestingdepth) {
    this.validateAndInitialize();

    Map<String, Schema.SObjectField> fieldMap = this.sObjectType.getDescribe().fields.getMap();

    String selectFieldsString = this.buildSelectFields(fieldMap, lowerNestingDepth);

    String fromString;
    String objectName = this.sObjectType.getDescribe().getName();
    List<Schema.ChildRelationship> childRelationships = parentSObjectType.getDescribe().getChildRelationships();
    for (Schema.ChildRelationship childRelationship : childRelationships) {
      if (childRelationship.getChildSObject().getDescribe().getName() == objectName) {
        fromString = childRelationship.getRelationshipName();
        break;
      }
    }
    if (fromString == null) {
      String parentObjectName = parentSObjectType.getDescribe().getName();
      String error = String.format(
        '{0} does not have a child relationship with {1}',
        new List<String>{ parentObjectName, objectName }
      );
      throw new QueryException(error);
    }

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });
    query = this.buildQueryTrail(query, fieldMap);

    return query;
  }

  private class ConditionPart {
    public IConditionClause condition;
    public Scribe groupScribe;
    public ParentScribe parentScribe;
    public Boolean isOr = false; 

    public ConditionPart(IConditionClause condition, Boolean isOr) {
      this.condition = condition;
      this.groupScribe = null;
      this.isOr = isOr;
    }

    public ConditionPart(Scribe groupScribe, Boolean isOr) {
      this.condition = null;
      this.groupScribe = groupScribe;
      this.isOr = isOr;
    }

    public ConditionPart(ParentScribe parentScribe) {
      this.condition = null;
      this.groupScribe = null;
      this.parentScribe = parentScribe;
      this.isOr = false;
    }
  }


  private class Validated {
    public Schema.DescribeFieldResult relationFieldDescribe;
    public String relationName;
    public Schema.SObjectType relationSObjectType;

    public Validated(
      Schema.DescribeFieldResult relationFieldDescribe,
      String relationName,
      Schema.SObjectType relationSObjectType
    ) {
      this.relationFieldDescribe = relationFieldDescribe;
      this.relationName = relationName;
      this.relationSObjectType = relationSObjectType;
    }
  }

  private class ParentScribe {
    public String relationName;
    public Scribe scribe;

    public ParentScribe(String relationName, Scribe scribe) {
      this.relationName = relationName;
      this.scribe = scribe;
    }

    public String buildSelectClause(Map<String, Schema.SObjectField> childFieldMap, String childObjectName) {
      Validated validated = this.validate(childFieldMap);
      if (this.scribe.sObjectType == null) {
        this.scribe.sObjectType = validated.relationSObjectType;
      }

      List<String> parentSelects = new List<String>();
      for (String parentFieldName : this.scribe.getSelectedFields(validated.relationSObjectType.getDescribe().fields.getMap())) {
        String parentSelect = '';
        if (childObjectName != null) {
          parentSelect = childObjectName + '.';
        }
        parentSelect += validated.relationName + '.' + parentFieldName;
        parentSelects.add(parentSelect);
      }

      if (!this.scribe.parents.isEmpty()) {
        if (childObjectName == null) {
          childObjectName = validated.relationName;
        } else {
          childObjectName += '.' + validated.relationName;
        }
        for (ParentScribe grandParentScribe : this.scribe.parents) {
          Map<String, Schema.SObjectField> parentFieldMap = validated.relationSObjectType.getDescribe().fields.getMap();
          String grandParentSelectsAsString = grandParentScribe.buildSelectClause(parentFieldMap, childObjectName);
          parentSelects.add(grandParentSelectsAsString);
        }
      }
      if (parentSelects.isEmpty()) {
        throw new QueryException('The parent fields list is empty');
      }
      return String.join(parentSelects, ', ');
    }

    public String buildWhereClause(Map<String, Schema.SObjectField> fieldMap, String childObjectName) {
      Validated validated = this.validate(fieldMap);

      if (this.scribe.conditionParts.isEmpty() && this.scribe.parents.isEmpty()) {
        return '';
      }

      String newChildObjectName;
      if (childObjectName == null) {
        newChildObjectName = validated.relationName;
      } else {
        newChildObjectName = childObjectName + '.' + validated.relationName;
      }

      Schema.SObjectType parentSObjectType = validated.relationSObjectType;
      Map<String, Schema.SObjectField> parentFieldMap = parentSObjectType.getDescribe().fields.getMap();

      String whereClauseString = this.scribe.buildWhereClause(parentFieldMap);

      List<String> whereClauses = whereClauseString.split(' AND ');
      List<String> newWhereClauses = new List<String>();
      for (String clause : whereClauses) {
        newWhereClauses.add(newChildObjectName + '.' + clause);
      }

      return String.join(newWhereClauses, ' AND ');
    }

    private Validated validate(Map<String, Schema.SObjectField> fieldMap) {
      if (!fieldMap.containsKey(this.relationName)) {
        throw new QueryException(
          'The specified relation ID field does not exist in the object\'s fields. field name: ' + this.relationName
        );
      }

      Schema.SObjectField relationField = fieldMap.get(this.relationName);
      Schema.DescribeFieldResult relationFieldDescribe = relationField.getDescribe();

      if (relationFieldDescribe.getType() != Schema.DisplayType.REFERENCE) {
        throw new QueryException(
          'The specified relation ID field is not of reference type. field name: ' + this.relationName
        );
      }

      String relationNameString = relationFieldDescribe.getRelationshipName();
      if (relationNameString == null) {
        throw new QueryException(
          'The specified relation ID field does not have a relationship name. field name: ' + this.relationName
        );
      }

      if (relationFieldDescribe.isNamePointing()) {
        throw new QueryException(
          'Sorry, we don\'t support relation IDs that can point to multiple SObject types yet. ' + this.relationName
        );
      }

      Schema.SObjectType relationSObjectType = relationFieldDescribe.getReferenceTo()[0];
      return new Validated(relationFieldDescribe, relationNameString, relationSObjectType);
    }
  }
}
