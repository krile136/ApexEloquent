public class Query {
  private final Schema.SObjectType sObjectType;
  private final List<String> selectFields;
  private final List<WhereClauseInterface> andWhereClauses;
  private final List<WhereClauseInterface> orWhereClauses;
  private final List<Query> andQueries;
  private final List<Query> orQueries;
  private final List<WhereClauseInterface> joinClauses;
  private final boolean isSelectAll;

  /**
   * default constructor
   */
  public Query() {
    this.sObjectType = null;
    this.selectFields = new List<String>();
    this.andWhereClauses = new List<WhereClauseInterface>();
    this.orWhereClauses = new List<WhereClauseInterface>();
    this.andQueries = new List<Query>();
    this.orQueries = new List<Query>();
    this.joinClauses = new List<WhereClauseInterface>();
    this.isSelectAll = false;
  }

  /**
   * constructor
   */
  public Query(
    Schema.SObjectType sObjectType,
    List<String> selectFields,
    List<WhereClauseInterface> andWhereClauses,
    List<WhereClauseInterface> orWhereClauses,
    List<Query> andQueries,
    List<Query> orQueries,
    List<WhereClauseInterface> joinClauses,
    Boolean isSelectAll
  ) {
    this.sObjectType = sObjectType;
    this.selectFields = selectFields;
    this.andWhereClauses = andWhereClauses;
    this.orWhereClauses = orWhereClauses;
    this.andQueries = andQueries;
    this.orQueries = orQueries;
    this.joinClauses = joinClauses;
    this.isSelectAll = isSelectAll;
  }

  // ---------- FROM句 ----------
  /**
   * クエリのソース(FROM)を設定する
   * 引数のsObjectTypeは次のように指定してください
   * .source(Opportunity.SObjectType)
   *
   * @param sObjectType ソースとなるオブジェクトのsObjectType
   * @return Query
   */
  public Query source(Schema.SObjectType sObjectType) {
    return new Query(
      sObjectType,
      this.selectFields,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  // ---------- SELECT句 ----------
  /**
   * クエリのフィールド(SELECT)を設定する
   *
   * @param selectField セレクトするフィールド名
   * @return Query
   */
  public Query pick(String selectField) {
    List<String> newSelectFields = this.selectFields;
    newSelectFields.add(selectField);
    return new Query(
      this.sObjectType,
      newSelectFields,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  /**
   * クエリのフィールド(SELECT)を設定する
   *
   * @param selectFields セレクトするフィールド（複数）
   * @return Query
   */
  public Query pick(List<String> selectFields) {
    List<String> newSelectFields = this.selectFields;
    newSelectFields.addAll(selectFields);
    return new Query(
      this.sObjectType,
      newSelectFields,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  /**
   * すべてのフィールドをセレクトする
   *
   * @return Query
   */
  public Query pickAll() {
    return new Query(
      this.sObjectType,
      new List<String>(),
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      true
    );
  }

  // ---------- WHERE句(フィールドを一つ追加) ----------
  /**
   * WHERE(AND)の条件を設定する
   *
   * @param field フィールド名
   * @param operator 演算子
   * @param value 値
   * @return Query
   */
  public Query condition(String field, String operator, Object value) {
    WhereClauseInterface whereClause = WhereClauseFactory.create(this.sObjectType, field, operator, value);
    List<WhereClauseInterface> newWhereClauses = this.andWhereClauses;
    newWhereClauses.add(whereClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      newWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  /**
   * WHERE(OR)の条件を設定する
   *
   * @param field フィールド名
   * @param operator 演算子
   * @param value 値
   * @return Query
   */
  public Query orCondition(String field, String operator, Object value) {
    if (this.andWhereClauses.isEmpty() && this.orWhereClauses.isEmpty()) {
      throw new QueryException('最初の条件はAND条件で指定してください');
    }
    WhereClauseInterface whereClause = WhereClauseFactory.create(this.sObjectType, field, operator, value);
    List<WhereClauseInterface> newWhereClauses = this.orWhereClauses;
    newWhereClauses.add(whereClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.andWhereClauses,
      newWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  // ---------- WHERE句(フィールドを複数追加) ----------
  /**
   * WHERE(AND)の条件を設定する
   *
   * @param field フィールド名
   * @param operator 演算子
   * @param values 値（複数）
   * @return Query
   */
  public Query condition(String field, String operator, List<Object> values) {
    if(values.isEmpty()) {
      // 空のリストが渡された場合必ずヒットしない条件に変換する
      return this.condition('Id', '=', (Object) null);
    }
    WhereClauseInterface whereClause = WhereClauseFactory.create(this.sObjectType, field, operator, values);
    List<WhereClauseInterface> newWhereClauses = this.andWhereClauses;
    newWhereClauses.add(whereClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      newWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  /**
   * WHERE(OR)の条件を設定する
   * * join句と組み合わせることはできません
   *
   * @param field フィールド名
   * @param operator 演算子
   * @param values 値（複数）
   * @return Query
   */
  public Query orCondition(String field, String operator, List<Object> values) {
    if (this.andWhereClauses.isEmpty() && this.orWhereClauses.isEmpty()) {
      throw new QueryException('最初の条件はAND条件で指定してください');
    }
    if(values.isEmpty()) {
      // 空のリストが渡された場合必ずヒットしない条件に変換する
      return this.orCondition('Id', '=', (Object) null); 
    }
    WhereClauseInterface whereClause = WhereClauseFactory.create(this.sObjectType, field, operator, values);
    List<WhereClauseInterface> newWhereClauses = this.orWhereClauses;
    newWhereClauses.add(whereClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.andWhereClauses,
      newWhereClauses,
      this.andQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  // ---------- WHERE句(クエリで括弧に囲まれた条件を追加) ----------
  /**
   * WHERE(AND)の条件を設定する
   * クエリを使用することで( )で囲まれた条件を追加できます
   *
   * @param query クエリ
   * @return Query
   */
  public Query condition(Query query) {
    List<Query> newAndQueries = this.andQueries;
    newAndQueries.add(query);

    return new Query(
      this.sObjectType,
      this.selectFields,
      this.andWhereClauses,
      this.orWhereClauses,
      newAndQueries,
      this.orQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  /**
   * WHERE(OR)の条件を設定する
   * クエリを使用することで( )で囲まれた条件を追加できます
   * * join句と組み合わせることはできません
   *
   * @param query クエリ
   * @return Query
   */
  public Query orCondition(Query query) {
    if (this.andWhereClauses.isEmpty() && this.orWhereClauses.isEmpty()) {
      throw new QueryException('最初の条件はAND条件で指定してください');
    }
    List<Query> newOrQueries = this.orQueries;
    newOrQueries.add(query);

    return new Query(
      this.sObjectType,
      this.selectFields,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      newOrQueries,
      this.joinClauses,
      this.isSelectAll
    );
  }

  // ---------- join句 ----------
  /**
   * JOIN句を設定する
   * * OR条件と組み合わせることはできません
   *
   * @param field フィールド名
   * @param operator 演算子
   * @param subQuery サブクエリ
   * @return Query
   */
  public Query join(String field, String operator, Query subQuery) {
    List<WhereClauseInterface> newJoinClauses = this.joinClauses;
    WhereClauseInterface joinClause = WhereClauseFactory.create(this.sObjectType, field, operator, subQuery);
    newJoinClauses.add(joinClause);
    return new Query(
      this.sObjectType,
      this.selectFields,
      this.andWhereClauses,
      this.orWhereClauses,
      this.andQueries,
      this.orQueries,
      newJoinClauses,
      this.isSelectAll
    );
  }

  // ---------- 便利なメソッド達 ----------
  /**
   * Idを指定してレコードを取得する条件を追加する
   *
   * @param recordId レコードのrecordId
   * @return Query
   */
  public Query find(Id recordId) {
    return this.condition('Id', '=', recordId);
  }

  /**
   * IDを複数指定してレコードを取得する条件を追加する
   *
   * @param recordIds レコードのrecordId（複数）
   * @return Query
   */
  public Query findMany(List<Id> recordIds) {
    return this.condition('Id', 'IN', recordIds);
  }

  /**
   * フィールドの値がfrom以上to以下の範囲にあるレコードを取得する条件を追加する
   *
   * @param field フィールド名
   * @param fromValue 範囲の下限
   * @param toValue 範囲の上限
   * @return Query
   */
  public Query betweenInclusive(String field, Object fromValue, Object toValue) {
    return this.condition(field, '>=', fromValue).condition(field, '<=', toValue);
  }

  /**
   * フィールドの値がfromより大きくtoより小さい範囲にあるレコードを取得する条件を追加する
   *
   * @param field フィールド名
   * @param fromValue 範囲の下限
   * @param toValue 範囲の上限
   * @return Query
   */
  public Query betweenExclusive(String field, Object fromValue, Object toValue) {
    return this.condition(field, '>', fromValue).condition(field, '<', toValue);
  }

  /**
   * 指定されたフィールドがNULLである条件を設定します。
   *
   * @param field 条件を設定するフィールドの名前
   * @return このクエリオブジェクト
   */
  public Query isNull(String field) {
    return this.condition(field, '=', (Object) null);
  }

  /**
   * 指定されたフィールドがNULLでない条件を設定します。
   *
   * @param field 条件を設定するフィールドの名前
   * @return このクエリオブジェクト
   */
  public QUery isNotNull(String field) {
    return this.condition(field, '!=', (Object) null);
  }

  // ---------- Where句の状態を連結して出力 ----------
  /**
   * Where句を組み立てる
   *
   * @param fieldMap フィールドのマップ
   * @return 組み立てたWhere句
   */
  private String buildWhereClause(Map<String, Schema.SObjectField> fieldMap) {
    Boolean hasOrCondition = false;

    String whereClauseString = '';
    // AND条件を結合
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

    // OR条件を結合
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

    // ANDのクエリ条件を結合
    if (!this.andQueries.isEmpty()) {
      if (whereClauseString != '') {
        whereClauseString += ' AND ';
      }
      List<String> whereClauseStrings = new List<String>();
      for (Query query : this.andQueries) {
        Query queryWithSource = new Query(
          this.sObjectType,
          query.selectFields,
          query.andWhereClauses,
          query.orWhereClauses,
          query.andQueries,
          query.orQueries,
          query.joinClauses,
          query.isSelectAll
        );
        whereClauseStrings.add('(' + queryWithSource.buildWhereClause(fieldMap) + ')');
      }
      whereClauseString += String.join(whereClauseStrings, ' AND ');
    }

    // ORのクエリ条件を結合
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
          query.andWhereClauses,
          query.orWhereClauses,
          query.andQueries,
          query.orQueries,
          query.joinClauses,
          query.isSelectAll
        );
        whereClauseStrings.add('(' + queryWithSource.buildWhereClause(fieldMap) + ')');
      }
      whereClauseString += String.join(whereClauseStrings, ' OR ');
    }

    // JOIN条件を結合
    if (!this.joinClauses.isEmpty()) {
      if (hasOrCondition) {
        String error = 'joinのサブクエリはネスト内に配置できず、ORと組み合わせるとネストが必要になるためこの組み合わせは実行不可です。';
        throw new QueryException(error);
      }
      if (whereClauseString != '') {
        whereClauseString += ' AND ';
      }
      for (WhereClauseInterface joinClause : this.joinClauses) {
        whereClauseString += '(' + joinClause.build() + ')';
      }
    }

    return whereClauseString;
  }

  // ---------- SOQL文を生成 ----------
  /**
   * SOQL文を生成する
   *
   * @return SOQL文
   */
  public String toSoql() {
    Boolean isSObjectTypeNull = this.sObjectType == null;
    if (isSObjectTypeNull) {
      throw new QueryException('sourceが設定されていません');
    }
    if (this.selectFields.isEmpty() && !this.isSelectAll) {
      throw new QueryException('pickが設定されていません');
    }

    String selectFieldsString = '';
    Map<String, Schema.SObjectField> fieldMap = this.sObjectType.getDescribe().fields.getMap();
    if (this.isSelectAll) {
      selectFieldsString = 'FIELDS(ALL)';
    } else {
      selectFieldsString = String.join(this.selectFields, ', ');
    }

    String query = 'SELECT ' + selectFieldsString + ' FROM ' + this.sObjectType.getDescribe().getName();

    String whereClause = this.buildWhereClause(fieldMap);
    if (whereClause != '') {
      query += ' WHERE ' + whereClause;
    }

    System.debug('SOQL: ' + query);
    return query;
  }
}
