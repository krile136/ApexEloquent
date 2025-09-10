/**
 * An interface for classes that build a single condition part of a SOQL WHERE or HAVING clause.
 */
public interface IConditionClause {
  /**
   * Builds the condition clause string.
   *
   * @return The constructed condition clause part.
   */
  String build();

  /**
   * Overrides the internal metadata for the clause.
   *
   * @param sObjectType The SObjectType to use for context.
   * @param fieldMap The field map of the relevant SObject for schema validation.
   * @return A new IConditionClause instance with the updated metadata.
   */
  IConditionClause overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap);

  /**
   * Overrides the field name for this condition.
   *
   * @param field The new field name to use.
   * @return A new IConditionClause instance with the updated field name.
   */
  IConditionClause overrideField(String field);

  /**
   * Gets the field name or alias used in this condition.
   *
   * @return The field name or alias.
   */
  String getFieldName();
}
