public with sharing abstract class AbstractAggregateClause implements IAggregateClause {
  protected final Schema.SObjectType sObjectType;
  protected final Map<String, Schema.SObjectField> fieldMap;
  protected final String fieldName;
  protected final String alias;


  public AbstractAggregateClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String fieldName,
    String alias
  ) {
    if (String.isBlank(fieldName)) {
      throw new IllegalArgumentException('fieldName must not be blank');
    }
    if (String.isBlank(alias)) {
      throw new IllegalArgumentException('alias must not be blank');
    }
    this.sObjectType = sObjectType;
    this.fieldMap = fieldMap;
    this.fieldName = fieldName;
    this.alias = alias;
  }

  public String getAlias() {
    return alias;
  }

  public String getFieldName() {
    return fieldName;
  }

  public abstract String build();
  public abstract IAggregateClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  );

  public String buildWithChild(String childRelationName){
    String buildResult = this.build();
    System.debug('buildResult: ' + buildResult);
    // SUM(Ammount) totalAmount  のような形式になるので、`(` で分割した二つ目の要素が
    // フィールド名になる。これに子オブジェクトのリレーション名を付けて
    // SUM(ChildRelationName.Ammount) totalAmount のようにする。
    List<String> buildResultParts = buildResult.split('\\(');
    if(childRelationName != null) {
      buildResultParts[1] = childRelationName + '.' + buildResultParts[1];
    }
    System.debug('buildResultParts: ' + buildResultParts);
    return String.join(buildResultParts, '(');
  }


  protected void validateFieldName(String fieldName) {
    if (!fieldMap.containsKey(fieldName)) {
      String error = String.format(
        'The specified field does not exist in the object\'s fields. object name: {0}, field name: {1}',
        new List<String>{ sObjectType.getDescribe().getName(), fieldName }
      );
      throw new QueryException(error);
    }
  }
}
