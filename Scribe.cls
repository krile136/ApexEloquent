public with sharing class Scribe implements IScribe {
  @TestVisible
  private Schema.SObjectType sObjectType;
  private Schema.DescribeSObjectResult describe;
  @TestVisible
  private Set<String> selectFields = new Set<String>();
  private List<IAggregateClause> aggregateClauses = new List<IAggregateClause>();
  private List<ConditionPart> conditionParts = new List<ConditionPart>();
  private Scribe.OrderByClause orderByClause;

  private List<String> groupByFields = new List<String>();

  private Boolean isSelectAll = false;
  private Boolean isNextConditionOr = false;
  private Boolean canOnlyAddOrCondition = false;

  private List<ParentScribe> parents = new List<ParentScribe>();
  private Boolean isParent = false;
  String parentRelationIdFieldName;

  private List<Scribe> children = new List<Scribe>();
  private Boolean isChild = false;

  private Boolean isGroup = false;
  private Map<String, AliasStructure> groupAliasMap = new Map<String, AliasStructure>();
  private Boolean isHaving = false;
  private Scribe havingScribe;

  private Integer limitNumber = 0;

  private final Integer MAX_UPPER_NESTING_DEPTH = 5;
  private final Integer MAX_LOWER_NESTING_DEPTH = 4;

  /**
   * constructor
   *
   * @param sObjectType 対象のSObjectType
   * @throws QueryException SObjectTypeがnullの場合
   */
  public Scribe(Schema.SObjectType sObjectType) {
    this.sObjectType = sObjectType;
    this.describe = sObjectType != null ? sObjectType.getDescribe() : null;
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

  public static Scribe asGroup() {
    Scribe newScribe = new Scribe(null);
    newScribe.isGroup = true;
    return newScribe;
  }

  public static Scribe asParent(String parentRelationIdFieldName) {
    if (String.isBlank(parentRelationIdFieldName)) {
      throw new QueryException('親のリレーションIDフィールド名が空です。');
    }
    Scribe newScribe = new Scribe(null);
    newScribe.isParent = true;
    newScribe.parentRelationIdFieldName = parentRelationIdFieldName;
    return newScribe;
  }

  public static Scribe asChild(Schema.SObjectType childSObjectType) {
    if (childSObjectType == null) {
      throw new QueryException('childSObjectTypeがnullです。');
    }
    Scribe newScribe = new Scribe(childSObjectType);
    newScribe.isChild = true;

    return newScribe;
  }

  public static Scribe asHaving() {
    Scribe newScribe = new Scribe(null);
    newScribe.isHaving = true;
    return newScribe;
  }

  // ------------ select methods ------------

  public Scribe field(String fieldName) {
    this.validateAddFieldClause();

    if (String.isBlank(fieldName)) {
      throw new QueryException('フィールド名が空です。');
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.selectFields.add(fieldName);

    return clonedScribe;
  }

  public Scribe fields(List<String> fieldNames) {
    this.validateAddFieldClause();

    if (fieldNames == null || fieldNames.isEmpty()) {
      throw new QueryException('フィールド名のリストが空です。');
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.selectFields.addAll(new Set<String>(fieldNames));

    return clonedScribe;
  }

  public Scribe allFields() {
    this.validateAddFieldClause();

    Scribe clonedScribe = this.deepClone();
    clonedScribe.isSelectAll = true;

    return clonedScribe;
  }

  // ------------ aggregate methods ------------

  public Scribe average(String fieldName, String alias) {
    this.validateAddAggregateClause();
    IAggregateClause averageClause = new AverageClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(averageClause);

    return clonedScribe;
  }

  public Scribe count(String fieldName, String alias) {
    this.validateAddAggregateClause();
    IAggregateClause countClause = new CountClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(countClause);

    return clonedScribe;
  }

  public Scribe countDistinct(String fieldName, String alias) {
    this.validateAddAggregateClause();
    IAggregateClause countDistinctClause = new CountDistinctClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(countDistinctClause);

    return clonedScribe;
  }

  public Scribe min(String fieldName, String alias) {
    this.validateAddAggregateClause();
    IAggregateClause minClause = new MinClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(minClause);

    return clonedScribe;
  }

  public Scribe max(String fieldName, String alias) {
    this.validateAddAggregateClause();
    IAggregateClause maxClause = new MaxClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(maxClause);

    return clonedScribe;
  }

  public Scribe sum(String fieldName, String alias) {
    this.validateAddAggregateClause();
    IAggregateClause sumClause = new SumClause(this.sObjectType, null, fieldName, alias);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.aggregateClauses.add(sumClause);

    return clonedScribe;
  }

  public Scribe groupByField(string fieldName) {
    this.validateAddAggregateClause();

    if (String.isBlank(fieldName)) {
      throw new QueryException('グループ化するフィールド名が空です。');
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.groupByFields.add(fieldName);

    return clonedScribe;
  }

  public Scribe groupByFields(List<String> fieldNames) {
    this.validateAddAggregateClause();

    if (fieldNames == null || fieldNames.isEmpty()) {
      throw new QueryException('グループ化するフィールド名のリストが空です。');
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.groupByFields.addAll(fieldNames);

    return clonedScribe;
  }

  public Scribe havingCondition(Scribe havingScribe) {
    if (this.groupByFields.isEMpty()) {
      throw new QueryException('havingConditionメソッドは、groupByFieldと同時に使用する必要があります。');
    }
    if (!havingScribe.isHaving) {
      String error = 'havingConditionメソッドの引数のScribeクラスは、Scribe.asHaving()で生成されたScribeクラスを入れてください。';
      throw new QueryException(error);
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.havingScribe = havingScribe;

    return clonedScribe;
  }

  // ------------ add OR methods ------------
  public Scribe orCondition() {
    this.validateOrConditionNotAllowed();

    Scribe clonedScribe = this.deepClone();

    if (clonedScribe.conditionParts.isEmpty() && !clonedScribe.isParent) {
      throw new QueryException(
        'OR条件を最初に設定することはできません。where系メソッドを使用してAND条件を追加してください。parentCondition内でエラーが起きている場合は引数のScribeクラスをScribe.asParent()から始めてください。'
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
        String childObjectname = child.getDescribe().getName().toLowerCase();
        FieldStructure childFieldStructure = child.buildFieldStructure();
        relationFieldStructures.put(childObjectname, childFieldStructure);
      }
    }

    List<String> selectedFields = this.getSelectedFields(fieldMap);
    return new FieldStructure(selectedFields, relationFieldStructures);
  }

  // ------------ group methods ------------

  public Scribe whereGroup(Scribe groupScribe) {
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

    if (!this.groupByFields.isEmpty() || !this.aggregateClauses.isEmpty()) {
      throw new QueryException('集計関数はwithChildrenメソッドと同時に使用することはできません。');
    }

    System.debug(childScribe);

    if (!childScribe.isChild) {
      String error = 'withChildrenメソッドの引数のScribeクラスは、はScribe.asChild()で生成されたScribeクラスを入れてください。';
      throw new QueryException(error);
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.children.add(childScribe);

    return clonedScribe;
  }

  public Scribe parentCondition(Scribe parentScribe) {
    this.validateOrConditionNotAllowed();

    if (parentScribe == null) {
      throw new QueryException('親のScribeがnullです。');
    }

    if (!parentScribe.isParent) {
      String error = 'parentConditionメソッドの引数のScribeクラスは、Scribe.asParent()で生成されたScribeクラスを入れてください。';
      throw new QueryException(error);
    }

    Scribe clonedScribe = this.deepClone();
    ConditionPart parentConditionPart = new ConditionPart(
      new ParentScribe(parentScribe.parentRelationIdFieldName, parentScribe)
    );
    clonedScribe.conditionParts.add(parentConditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe parentField(Scribe parentScribe) {
    this.validateOrConditionNotAllowed();

    if (parentScribe == null) {
      throw new QueryException('親のScribeがnullです。');
    }

    if (!parentScribe.isParent) {
      String error = 'parentFieldメソッドの引数のScribeクラスは、Scribe.asParent()で生成されたScribeクラスを入れてください。';
      throw new QueryException(error);
    }

    Scribe clonedScribe = this.deepClone();
    clonedScribe.parents.add(new ParentScribe(parentScribe.parentRelationIdFieldName, parentScribe));

    return clonedScribe;
  }

  // ------------ other clauses ------------

  public Scribe take(Integer limitNumber) {
    if (limitNumber == null || limitNumber <= 0) {
      throw new QueryException('takeの値は1以上の整数でなければなりません。');
    }
    Scribe clonedScribe = this.deepClone();
    clonedScribe.limitNumber = limitNumber;

    return clonedScribe;
  }

  public Scribe orderBy(String field) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClause = new Scribe.OrderByClause(field);
    return clonedScribe;
  }

  public Scribe orderBy(String field, String order) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClause = new Scribe.OrderByClause(field, order);
    return clonedScribe;
  }

  public Scribe orderBy(String field, String order, String nullsOperator) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClause = new Scribe.OrderByClause(field, order, nullsOperator);
    return clonedScribe;
  }

  public Scribe orderBy(List<String> fields) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClause = new Scribe.OrderByClause(fields);
    return clonedScribe;
  }

  public Scribe orderBy(List<String> fields, String order) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClause = new Scribe.OrderByClause(fields, order);
    return clonedScribe;
  }

  public Scribe orderBy(List<String> fields, String order, String nullsOperator) {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.orderByClause = new Scribe.OrderByClause(fields, order, nullsOperator);
    return clonedScribe;
  }

  // ------------ build methods ------------

  public String toSoql() {
    this.validateAndInitialize();

    Map<String, Schema.SObjectField> fieldMap = this.describe.fields.getMap();

    String selectFieldsString = this.buildSelectFields(fieldMap, 0);
    String fromString = this.describe.getName();

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });

    query = this.buildQueryTrail(query, fieldMap, selectFieldsString);

    System.debug('SOQL Query: ' + query);
    return query;
  }

  private String buildQueryTrail(
    String query,
    Map<String, Schema.SObjectField> fieldMap,
    String selectFieldsString
  ) {
    WhereClauseData whereClauseData = this.buildWhereClause(fieldMap, null);
    String whereString = whereClauseData.whereClauseString;
    if (whereString != '') {
      query += ' WHERE ' + whereString;
    }

    query = this.buildGroupByFields(query, fieldMap, selectFieldsString);

    query = this.buildHavingClause(query, fieldMap);

    if (this.orderByClause != null) {
      query += ' ' + this.orderByClause.build();
    }

    if (this.limitNumber > 0) {
      query += ' LIMIT ' + String.valueOf(this.limitNumber);
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
        if (!fieldMap.containsKey(fieldName.toLowerCase())) {
          String error = String.format(
            'The specified field does not exist in the object\'s fields. object name: {0}, field name: {1}',
            new List<String>{ this.describe.getName(), fieldName }
          );
          throw new QueryException(error);
        }
        selectFields.add(fieldName.toLowerCase());
      }
    }

    return selectFields;
  }

  // ------------ private methods ------------

  private Scribe deepClone() {
    Scribe newScribe = new Scribe(this.sObjectType);
    newScribe.selectFields = this.selectFields.clone();
    newScribe.aggregateClauses = this.aggregateClauses.clone();
    newScribe.conditionParts = this.conditionParts.clone();
    newScribe.children = this.children.clone();
    newScribe.parents = this.parents.clone();
    newScribe.groupByFields = this.groupByFields.clone();

    newScribe.isSelectAll = this.isSelectAll;
    newScribe.isNextConditionOr = this.isNextConditionOr;
    newScribe.canOnlyAddOrCondition = this.canOnlyAddOrCondition;
    newScribe.isParent = this.isParent;
    newScribe.parentRelationIdFieldName = this.parentRelationIdFieldName;
    newScribe.isChild = this.isChild;
    newScribe.isGroup = this.isGroup;
    newScribe.groupAliasMap = this.groupAliasMap.clone();
    newScribe.isHaving = this.isHaving;
    newScribe.havingScribe = this.havingScribe;

    return newScribe;
  }

  /**
   * A method to construct the SELECT clause of a SOQL query based on the specified field map.
   *
   * @param fieldMap A mapping of field names to Schema.SObjectField
   * @return The constructed SELECT clause as a string
   */
  private String buildSelectFields(Map<String, Schema.SObjectField> fieldMap, Integer lowerNestingDepth) {
    String selectFieldsString = '';

    // add select fields
    if (this.isSelectAll || !this.selectFields.isEmpty()) {
      selectFieldsString = String.join(this.getSelectedFields(fieldMap), ', ');
    }

    // add aggregate clauses
    for (IAggregateClause aggregateClause : this.aggregateClauses) {
      if (selectFieldsString != '') {
        selectFieldsString += ', ';
      }
      aggregateClause = aggregateClause.overrideMetaData(this.sObjectType, fieldMap);
      String aggregateClauseString = aggregateClause.build();
      selectFieldsString += aggregateClauseString;
      String alias = aggregateClause.getAlias();
      String aggregateField = aggregateClause.getFieldName();
      String aggregateTarget = aggregateClauseString.split(' ')[0];
      this.groupAliasMap.put(alias, new AliasStructure(aggregateField, aggregateTarget));
    }

    // Add parent queries
    for (ParentScribe parent : this.parents) {
      selectFieldsString += ', ' + parent.buildSelectClause(fieldMap, null, 0);
    }

    // Add child queries
    if (!this.children.isEmpty()) {
      lowerNestingDepth++;
      if (lowerNestingDepth > this.MAX_LOWER_NESTING_DEPTH) {
        List<String> overNestedChildrenNames = new List<String>();
        for (Scribe child : this.children) {
          overNestedChildrenNames.add(child.getDescribe().getName());
        }
        String error = String.format(
          'ネストの深度が最大値を超えました。最大ネスト深度: {0}, オブジェクト名: {1}',
          new List<String>{
            String.valueOf(this.MAX_LOWER_NESTING_DEPTH),
            String.join(overNestedChildrenNames, ', ')
          }
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

  private WhereClauseData buildWhereClause(Map<String, Schema.SObjectField> fieldMap, String childObjectName) {
    String whereClauseString = '';

    if (this.conditionParts.isEmpty()) {
      return new WhereClauseData('', false, false);
    }

    Boolean isFirstOperatorOr = null;
    Boolean isLastOperatorOr = false;
    for (ConditionPart conditionPart : this.conditionParts) {
      if (isLastOperatorOr && !conditionPart.isOr) {
        throw new QueryException(
          'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。'
        );
      }
      isFirstOperatorOr = isFirstOperatorOr == null ? conditionPart.isOr : isFirstOperatorOr;
      WhereClauseData whereClauseData = null;
      String clause = '';

      if (conditionPart.condition != null) {
        IConditionClause condition = conditionPart.condition.overrideMetaData(this.sObjectType, fieldMap);
        clause = condition.build();
        if (childObjectName != null) {
          clause = childObjectName + '.' + clause;
        }
        isLastOperatorOr = conditionPart.isOr;
      } else if (conditionPart.groupScribe != null) {
        Scribe groupScribe = conditionPart.groupScribe;
        groupScribe.sObjectType = this.sObjectType;
        WhereClauseData groupWhereClauseData = groupScribe.buildWhereClause(fieldMap, null);
        clause = String.format('({0})', new List<String>{ groupWhereClauseData.whereClauseString });
        isLastOperatorOr = conditionPart.isOr;
      } else if (conditionPart.parentScribe != null) {
        ParentScribe parentScribe = conditionPart.parentScribe;
        WhereClauseData parentWhereClauseData = parentScribe.buildWhereClause(fieldMap, childObjectName);
        clause = parentWhereClauseData.whereClauseString;
        isLastOperatorOr = parentWhereClauseData.isLastOperatorOr;
        conditionPart.isOr = parentWhereClauseData.isFirstOperatorOr;
      }

      if (clause != '') {
        if (whereClauseString != '') {
          whereClauseString += conditionPart.isOr ? ' OR ' : ' AND ';
        }
        whereClauseString += clause;
      }
    }

    return new WhereClauseData(whereClauseString, isFirstOperatorOr, isLastOperatorOr);
  }

  private WhereClauseData buildHavingClause(
    Map<String, AliasStructure> aggregateAliasMap,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    String whereClauseString = '';

    if (this.conditionParts.isEmpty()) {
      return new WhereClauseData('', false, false);
    }

    Boolean isFirstOperatorOr = null;
    Boolean isLastOperatorOr = false;

    for (ConditionPart conditionPart : this.conditionParts) {
      if (isLastOperatorOr && !conditionPart.isOr) {
        throw new QueryException(
          'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。'
        );
      }
      isFirstOperatorOr = isFirstOperatorOr == null ? conditionPart.isOr : isFirstOperatorOr;
      WhereClauseData whereClauseData = null;
      // HavingではwhereEqual(alias, value) のような形でwhere系メソッドを使用することを想定しているので
      // getFieldName()でエイリアスを取得できる
      String alias = conditionPart.condition.getFieldName();

      // エイリアスがgroupByで作成されているか確認する
      if (!aggregateAliasMap.containsKey(alias)) {
        String error = String.format(
          'The alias {0} in the HAVING clause does not match any aggregate alias',
          new List<String>{ alias }
        );
        throw new QueryException(error);
      }
      AliasStructure aliasStructure = aggregateAliasMap.get(alias);

      // HAVINGの条件をビルドする
      IConditionClause condition = conditionPart
        .condition
        .overrideMetaData(this.sObjectType, fieldMap)
        .overrideField(aliasStructure.getFieldName());
      String clauseWithAlias = condition.build();

      // ビルド結果のフィールドはSObjectのフィールドになっているので、集計関数に置き換える
      // 例: amount > 1000 -> AVG(Amount) > 1000
      List<String> clauseParts = clauseWithAlias.split(' ');
      clauseParts[0] = aliasStructure.getAggregateClause();
      String clause = String.join(clauseParts, ' ');

      if (clause != '') {
        if (whereClauseString != '') {
          whereClauseString += conditionPart.isOr ? ' OR ' : ' AND ';
        }
        whereClauseString += clause;
      }
    }

    return new WhereClauseData(whereClauseString, isFirstOperatorOr, isLastOperatorOr);
  }

  private String buildChildSoql(Schema.SObjectType parentSObjectType, Integer lowerNestingdepth) {
    this.validateAndInitialize();

    Map<String, Schema.SObjectField> fieldMap = this.describe.fields.getMap();
    String selectFieldsString = this.buildSelectFields(fieldMap, lowerNestingDepth);

    String fromString;
    String objectName = this.describe.getName();
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
    query = this.buildQueryTrail(query, fieldMap, selectFieldsString);

    return query;
  }

  private Schema.DescribeSObjectResult getDescribe() {
    return this.describe;
  }

  private String buildGroupByFields(
    String query,
    Map<String, Schema.SObjectField> fieldMap,
    String selectFieldsString
  ) {
    if (this.groupByFields.isEmpty()) {
      return query;
    }

    for (String groupByField : this.groupByFields) {
      if (!fieldMap.containsKey(groupByField.toLowerCase())) {
        String error = String.format(
          'The specified group by field does not exist in the object\'s fields. object name: {0}, field name: {1}',
          new List<String>{ this.describe.getName(), groupByField }
        );
        throw new QueryException(error);
      }
    }

    List<String> nonGroupedFields = new List<String>();
    for (String selectField : this.selectFields) {
      if (!this.groupByFields.contains(selectField)) {
        nonGroupedFields.add(selectField);
      }
    }
    if (!nonGroupedFields.isEmpty()) {
      String error = String.format(
        'There are fields in the SELECT clause that are not included in the GROUP BY clause. Non-grouped fields: {0}',
        new List<String>{ String.join(nonGroupedFields, ', ') }
      );
      throw new QueryException(error);
    }

    return query + ' GROUP BY ' + String.join(this.groupByFields, ', ');
  }

  private String buildHavingClause(String query, Map<String, Schema.SObjectField> fieldMap) {
    if (this.havingScribe == null) {
      return query;
    }
 
    this.havingScribe.sObjectType = this.sObjectType;
    WhereClauseData havingClauseData = this.havingScribe.buildHavingClause(this.groupAliasMap, fieldmap);
    String havingString = havingClauseData.whereClauseString;
    if (havingString != '') {
      query += ' HAVING ' + havingString;
    }

    return query;
  }

  //  ------------ validation methods ------------

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

  private void validateAddAggregateClause() {
    if (this.isChild) {
      throw new QueryException('子のScribeでは集計関数を使用できません。');
    }
    if (this.isHaving) {
      throw new QueryException('HAVING句の中では集計関数を使用できません。');
    }
    if (!this.children.isEmpty()) {
      throw new QueryException('集計関数はwithChildrenメソッドと同時に使用することはできません。');
    }
  }

  private void validateAddFieldClause() {
    if (this.isGroup) {
      throw new QueryException('グループ条件追加中はScribeではフィールドの追加はできません。');
    }
    if (this.isHaving) {
      throw new QueryException('HAVING句の中ではフィールドの追加はできません。');
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
    if (this.selectFields.isEmpty() && !this.isSelectAll && this.aggregateClauses.isEmpty()) {
      this.selectFields.add('Id');
    }
  }

  // ------------ inner classes ------------

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

  private class ParentScribe implements IScribe {
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

    public String buildSelectClause(
      Map<String, Schema.SObjectField> childFieldMap,
      String childObjectName,
      Integer upperNestingDepth
    ) {
      ParentObjectData parentObjectData = this.validate(childFieldMap);

      Integer currentUpperNestingDepth = upperNestingDepth + 1;
      if (currentUpperNestingDepth > this.MAX_UPPER_NESTING_DEPTH) {
        String error = String.format(
          '親方向のネスト深度が最大値を超えました。最大ネスト深度: {0}, オブジェクト名: {1}',
          new List<String>{
            String.valueOf(this.MAX_UPPER_NESTING_DEPTH),
            parentObjectData.relationSObjectType.getDescribe().getName()
          }
        );
        throw new QueryException(error);
      }

      if (this.scribe.sObjectType == null) {
        this.scribe.sObjectType = parentObjectData.relationSObjectType;
      }

      List<String> parentSelects = new List<String>();
      for (
        String parentFieldName : this.scribe.getSelectedFields(
          parentObjectData.relationSObjectType.getDescribe().fields.getMap()
        )
      ) {
        String parentSelect = '';
        if (childObjectName != null) {
          parentSelect = childObjectName + '.';
        }
        parentSelect += parentObjectData.relationFieldName + '.' + parentFieldName;
        parentSelects.add(parentSelect);
      }

      if (!this.scribe.parents.isEmpty()) {
        if (childObjectName == null) {
          childObjectName = parentObjectData.relationFieldName;
        } else {
          childObjectName += '.' + parentObjectData.relationFieldName;
        }
        for (ParentScribe grandParentScribe : this.scribe.parents) {
          Map<String, Schema.SObjectField> parentFieldMap = parentObjectData.relationSObjectType.getDescribe()
            .fields.getMap();
          String grandParentSelectsAsString = grandParentScribe.buildSelectClause(
            parentFieldMap,
            childObjectName,
            currentUpperNestingDepth
          );
          parentSelects.add(grandParentSelectsAsString);
        }
      }
      if (parentSelects.isEmpty()) {
        throw new QueryException('The parent fields list is empty');
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

    private ParentObjectData validate(Map<String, Schema.SObjectField> fieldMap) {
      if (!fieldMap.containsKey(this.relationFieldName)) {
        throw new QueryException(
          'The specified relation ID field does not exist in the object\'s fields. field name: ' +
          this.relationFieldName
        );
      }

      Schema.SObjectField relationField = fieldMap.get(this.relationFieldName);
      Schema.DescribeFieldResult relationFieldDescribe = relationField.getDescribe();

      if (relationFieldDescribe.getType() != Schema.DisplayType.REFERENCE) {
        throw new QueryException(
          'The specified relation ID field is not of reference type. field name: ' + this.relationFieldName
        );
      }

      String relationFieldNameString = relationFieldDescribe.getRelationshipName();
      if (relationFieldNameString == null) {
        throw new QueryException(
          'The specified relation ID field does not have a relationship name. field name: ' +
          this.relationFieldName
        );
      }

      if (relationFieldDescribe.isNamePointing()) {
        throw new QueryException(
          'Sorry, we don\'t support relation IDs that can point to multiple SObject types yet. ' +
          this.relationFieldName
        );
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

  private class OrderByClause {
    private Set<String> ORDERS = new Set<String>{ 'ASC', 'DESC' };
    private Set<String> NULLS_OPERATORS = new Set<String>{ 'FIRST', 'LAST' };

    private final List<String> fields;
    private final String order;
    private final String nullsOperator;

    public OrderByClause(String field) {
      this.validateField(field);
      this.fields = new List<String>{ field };
      this.order = 'ASC';
      this.nullsOperator = null;
    }

    public OrderByClause(String field, String order) {
      this.validateField(field);
      this.validateOrder(order);
      this.fields = new List<String>{ field };
      this.order = order;
      this.nullsOperator = null;
    }

    public OrderByClause(String field, String order, String nullsOperator) {
      this.validateField(field);
      this.validateOrder(order);
      this.validateNullsOperator(nullsOperator);
      this.fields = new List<String>{ field };
      this.order = order;
      this.nullsOperator = nullsOperator;
    }

    public OrderByClause(List<String> fields) {
      this.validateFields(fields);
      this.fields = fields;
      this.order = 'ASC';
      this.nullsOperator = null;
    }

    public OrderByClause(List<String> fields, String order) {
      this.validateFields(fields);
      this.validateOrder(order);
      this.fields = fields;
      this.order = order;
      this.nullsOperator = null;
    }

    public OrderByClause(List<String> fields, String order, String nullsOperator) {
      this.validateFields(fields);
      this.validateOrder(order);
      this.validateNullsOperator(nullsOperator);
      this.fields = fields;
      this.order = order;
      this.nullsOperator = nullsOperator;
    }

    public String build() {
      String orderBy = 'ORDER BY ' + String.join(this.fields, ', ') + ' ' + this.order;
      if (this.nullsOperator != null) {
        orderBy += ' NULLS ' + this.nullsOperator;
      }
      return orderBy;
    }

    private void validateField(String field) {
      if (String.isBlank(field)) {
        throw new QueryException('orderByのフィールド名が空です。');
      }
    }

    private void validateFields(List<String> fields) {
      if (fields == null || fields.isEmpty()) {
        throw new QueryException('orderByのフィールド名のリストが空です。');
      }
      for (String field : fields) {
        this.validateField(field);
      }
    }

    private void validateOrder(String order) {
      if (String.isBlank(order) || !this.ORDERS.contains(order.toUpperCase())) {
        throw new QueryException('orderByのorderが無効です。\'ASC\' or \'DESC\' を入力してください。');
      }
    }

    private void validateNullsOperator(String nullsOperator) {
      if (String.isBlank(nullsOperator) || !this.NULLS_OPERATORS.contains(nullsOperator.toUpperCase())) {
        throw new QueryException('orderByのnullsOperatorが無効です。\'FIRST\' or \'LAST\' を入力してください。');
      }
    }
  }

  private class AliasStructure {
    private final String fieldName;
    private final String aggregateClause;

    public AliasStructure(String fieldName, String aggregateClause) {
      this.fieldName = fieldName;
      this.aggregateClause = aggregateClause;
    }

    public String getFieldName() {
      return this.fieldName;
    }

    public String getAggregateClause() {
      return this.aggregateClause;
    }
  }
}
