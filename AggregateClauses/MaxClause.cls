public with sharing class MaxClause extends AbstractAggregateClause {
  private List<DisplayType> supportedTypes = new List<DisplayType>{
    DisplayType.DATE,
    DisplayType.DATETIME,
    DisplayType.DOUBLE,
    DisplayType.INTEGER,
    DisplayType.STRING,
    DisplayType.COMBOBOX,
    DisplayType.CURRENCY,
    DisplayType.DATACATEGORYGROUPREFERENCE,
    DisplayType.EMAIL,
    DisplayType.ID,
    DisplayType.PERCENT,
    DisplayType.PHONE,
    DisplayType.PICKLIST,
    DisplayType.REFERENCE,
    DisplayType.TEXTAREA,
    DisplayType.URL
  };

  /**
   * Constructor
   *
   * @param sObjectType The Schema.SObjectType of the object being queried.
   * @param fieldMap A map of field names to Schema.SObjectField objects for the sObjectType.
   * @param fieldName The name of the field to apply the AVERAGE function on.
   * @param alias An optional alias for the resulting average value.
   */
  public MaxClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String fieldName,
    String alias
  ) {
    super(sObjectType, fieldMap, fieldName, alias);
  }

  /**
   * @inheritdoc
   */
  public override IAggregateClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new MaxClause(sObjectType, fieldMap, fieldName, alias);
  }

  /**
   * @inheritdoc
   */
  public override String build() {
    this.validateFieldName(fieldName);
    Schema.SObjectField field = fieldMap.get(fieldName);
    Schema.DisplayType type = field.getDescribe().getType();
    if (!supportedTypes.contains(type)) {
      String error = String.format(
        'The specified field type is not supported for MAX. object name: {0}, field name: {1}, field type: {2}',
        new List<String>{ sObjectType.getDescribe().getName(), fieldName, type.name() }
      );
      throw new QueryException(error);
    }
    return String.format('MAX({0}) {1}', new List<String>{ this.fieldName, this.alias });
  }
}
