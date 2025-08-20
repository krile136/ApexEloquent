public interface IAggregateClause {
  /**
   * Aggregate句を組み立てる
   * @return 組み立てたAggregate句
   */
  String build();

  /**
   * Metadataを上書きする
   *
   * @param sObjectType 上書きするSObjectType
   * @param fieldMap フィールドマップ
   * @return IAggregateClause
   */
  IAggregateClause overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap);
}
