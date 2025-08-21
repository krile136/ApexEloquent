public interface IConditionClause {
  /**
   * Where句を組み立てる
   * @return 組み立てたWhere句
   */
  String build();

  /**
   * Metadataを上書きする
   *
   * @param sObjectType 上書きするSObjectType
   * @param fieldMap フィールドマップ
   * @return WhereClausesInterface
   */
  IConditionClause overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap);

  /**
   * フィールド名を上書きする
   *
   * @return フィールド名
   */
  IConditionClause overrideField(String field);

  /**
   * フィールド名を取得する
   *
   * @return フィールド名
   */
  String getFieldName();
}
