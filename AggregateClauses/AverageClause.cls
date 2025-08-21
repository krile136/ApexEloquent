public with sharing class AverageClause extends AbstractAggregateClause {
  private List<DisplayType> supportedTypes = new List<DisplayType>{
    DisplayType.DOUBLE,
    DisplayType.INTEGER,
    DisplayType.CURRENCY,
    DisplayType.PERCENT
  };

  public AverageClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String fieldName,
    String alias
  ) {
    super(sObjectType, fieldMap, fieldName, alias);
  }

  public override IAggregateClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new AverageClause(sObjectType, fieldMap, fieldName, alias);
  }
  
  public override String build() {
    this.validateFieldName(fieldName);
    Schema.SObjectField field = fieldMap.get(fieldName);
    Schema.DisplayType type = field.getDescribe().getType();
    if (!supportedTypes.contains(type)) {
      String error = String.format(
        'The specified field type is not supported for AVERAGE. object name: {0}, field name: {1}, field type: {2}',
        new List<String>{ sObjectType.getDescribe().getName(), fieldName, type.name() }
      );
      throw new QueryException(error);
    }

    return String.format('AVG({0}) {1}', new List<String>{ fieldName, alias });
  }
}
