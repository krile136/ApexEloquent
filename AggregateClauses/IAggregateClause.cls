public interface IAggregateClause {
  /**
   * Aggregate句を組み立てる
   * @return 組み立てたAggregate句
   */
  String build();

  /**
    * Aggregate句を組み立てる（子オブジェクトのリレーション名を指定）
    * @param childRelationName 子オブジェクトのリレーション名
    * @return 組み立てたAggregate句
    */
  String buildWithChild(String childRelationName);

  /**
    * aliasを取得する
    *
    * @return alias 
    */
  String getAlias();

  /**
   * フィールド名を取得する
   *
   * @return フィールド名
   */
  String getFieldName();

  /**
   * Metadataを上書きする
   *
   * @param sObjectType 上書きするSObjectType
   * @param fieldMap フィールドマップ
   * @return IAggregateClause
   */
  IAggregateClause overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap);
  }
