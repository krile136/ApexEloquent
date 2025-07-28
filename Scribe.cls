public with sharing class Scribe {
  @TestVisible
  private Schema.SObjectType sObjectType;
  @TestVisible
  private Set<String> selectFields = new Set<String>();
  private List<IConditionClause> andConditions = new List<IConditionClause>();
  private Boolean isSelectAll = false;

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

  // ------ where methods ------

  public Scribe equal(String fieldName, Object value) {
    this.validateConditionClause(fieldName, value);

    Scribe clonedScribe = this.deepClone();
    clonedScribe.andConditions.add(new EqualConditionClause(clonedScribe.sObjectType, null, fieldName, value));

    return clonedScribe;
  }

  public String toSoql() {
    this.validateAndInitialize();

    Map<String, Schema.SObjectField> fieldMap = this.sObjectType.getDescribe().fields.getMap();

    String selectFieldsString = this.buildSelectFields(fieldMap);
    String fromString = this.sObjectType.getDescribe().getName();

    String query = String.format('SELECT {0} FROM {1}', new List<String>{ selectFieldsString, fromString });

    query = this.buildWhereClause(query, fieldMap);

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

    return newScribe;
  }

  private void validateConditionClause(String fieldName, Object value) {
    if (String.isBlank(fieldName)) {
      throw new QueryException('フィールド名が空です。');
    }
    if (value == null) {
      throw new QueryException('値がnullです。');
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

    if (!this.andConditions.isEmpty()) {
      List<String> andConditionsAsString = new List<String>();
      for (IConditionClause condition : this.andConditions) {
        IConditionClause overridedCondition = condition.overrideMetaData(this.sObjectType, fieldMap);
        andConditionsAsString.add(overridedCondition.build());
      }
      whereClauseString += '(' + String.join(andConditionsAsString, ' AND ') + ')';
    }

    if(whereClauseString != '') {
      query += ' WHERE ' + whereClauseString;
    }

    return query;
  }
}
