public with sharing class IncludesConditionClause extends AbstractConditionClause {
  private final List<String> values;

  /**
   * Constructor for IncludesConditionClause
   *
   * @param sObjectType The SObject type for the condition.
   * @param fieldMap A map of field names to Schema.SObjectField.
   * @param field The field name to apply the INCLUDE condition on.
   * @param values A list of values to exclude.
   */
  public IncludesConditionClause(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap,
    String field,
    List<String> values
  ) {
    super(sObjectType, fieldMap, field);
    this.values = values;
  }

  /**
   * @inheritdoc
   */
  public override String build() {
    return String.format('{0} INCLUDES ({1})', new List<String>{ this.field, this.checkAndCast() });
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideMetaData(
    Schema.SObjectType sObjectType,
    Map<String, Schema.SObjectField> fieldMap
  ) {
    return new IncludesConditionClause(sObjectType, fieldMap, this.field, this.values);
  }

  /**
   * @inheritdoc
   */
  public override IConditionClause overrideField(String field) {
    return new IncludesConditionClause(this.sObjectType, this.fieldMap, field, this.values);
  }

  /**
   * check the value type and cast it to string for SOQL
   *
   * @return The value formatted as a SOQL-compatible string.
   */
  private String checkAndCast() {
    List<String> castedValues = new List<String>();
    for (Object value : this.values) {
      castedValues.add('\'' + value + '\'');
    }

    return String.join(castedValues, ', ');
  }
}
