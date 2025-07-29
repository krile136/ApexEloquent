public with sharing class Scribe {
  @TestVisible
  private Schema.SObjectType sObjectType;
  @TestVisible
  private Set<String> selectFields = new Set<String>();
  private List<IConditionClause> andConditions = new List<IConditionClause>();
  private List<IConditionClause> orConditions = new List<IConditionClause>();
  private List<ConditionPart> conditionParts = new List<ConditionPart>();

  private Boolean isSelectAll = false;
  private Boolean isNextConditionOr = false;
  private Boolean canOnlyAddOrCondition = false;

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

  // ------------ instance methods ------------

  // ------ select methods ------

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

  // ------ add or condition ------
  public Scribe orCondition() {
    Scribe clonedScribe = this.deepClone();
    clonedScribe.isNextConditionOr = true;
    clonedScribe.canOnlyAddOrCondition = true;

    return clonedScribe;
  }

  // ------ where methods ------

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

  public Scribe whereNotIn(String fieldName, Object values) {
    this.validateConditionClause(fieldName);

    Scribe clonedScribe = this.deepClone();
    IConditionClause conditionClause = new NotInConditionClause(clonedScribe.sObjectType, null, fieldName, values);
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
    Scribe clonedScribe = this.deepClone();
    IconditionClause conditionClause = new IsNullConditionClause(clonedScribe.sObjectType, null, fieldName);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public Scribe whereNotNull(String fieldName) {
    Scribe clonedScribe = this.deepClone();
    IconditionClause conditionClause = new IsNotNullConditionClause(clonedScribe.sObjectType, null, fieldName);
    ConditionPart conditionPart = new ConditionPart(conditionClause, this.isNextConditionOr);
    clonedScribe.conditionParts.add(conditionPart);
    clonedScribe.isNextConditionOr = false;

    return clonedScribe;
  }

  public String toSoql() {
    this.validateAndInitialize();

    Map<String, Schema.SObjectField> fieldMap = this.sObjectType.getDescribe().fields.getMap();

    String selectFieldsString = this.buildSelectFields(fieldMap);
    String fromString = this.sObjectType.getDescribe().getName();

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });

    query = this.buildWhereClause(query, fieldMap);

    System.debug('SOQL Query: ' + query);
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
    newScribe.andConditions = this.andConditions.clone();
    newScribe.conditionParts = this.conditionParts.clone();

    newScribe.isSelectAll = this.isSelectAll;
    newScribe.isNextConditionOr = this.isNextConditionOr;
    newScribe.canOnlyAddOrCondition = this.canOnlyAddOrCondition;

    return newScribe;
  }

  private void validateConditionClause(String fieldName) {
    if (String.isBlank(fieldName)) {
      throw new QueryException('フィールド名が空です。');
    }
    System.debug('isNextConditionOr: ' + this.isNextConditionOr);
    System.debug('canOnlyAddOrCondition: ' + this.canOnlyAddOrCondition);
    if (this.canOnlyAddOrCondition && !this.isNextConditionOr) {
      throw new QueryException(
        'ORに続く条件はORでなければなりません。複雑な条件を作成する場合はgroupメソッドで条件をグルーピングしてください。'
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
  private String buildSelectFields(Map<String, Schema.SObjectField> fieldMap) {
    // add select fields
    String selectFieldsString = String.join(this.getSelectedFields(fieldMap), ', ');

    // Add parent queries
    // for (ParentClause parent : this.parents) {
    //  selectFieldsString += ', ' + parent.buildSelectClause(fieldMap, null);
    // }

    // Add child queries
    // for (Query child : this.children) {
    //  selectFieldsString += ', (' + child.toChildrenSoql(this.sObjectType) + ')';
    // }

    return selectFieldsString;
  }

  private String buildWhereClause(String query, Map<String, Schema.SObjectField> fieldMap) {
    String whereClauseString = '';

    if (this.conditionParts.isEmpty()) {
      return '';
    }

    for (ConditionPart conditionPart : this.conditionParts) {
      IConditionClause condition = conditionPart.condition.overrideMetaData(this.sObjectType, fieldMap);
      if (conditionPart.isOr) {
        if (whereClauseString != '') {
          whereClauseString += ' OR ';
        }
        whereClauseString += condition.build();
      } else {
        if (whereClauseString != '') {
          whereClauseString += ' AND ';
        }
        whereClauseString += condition.build();
      }
    }

    if (whereClauseString != '') {
      query += ' WHERE ' + whereClauseString;
    }

    return query;
  }

  private class ConditionPart {
    public IConditionClause condition;
    public Boolean isOr = false;

    public ConditionPart(IConditionClause condition, Boolean isOr) {
      this.condition = condition;
      this.isOr = isOr;
    }
  }
}
