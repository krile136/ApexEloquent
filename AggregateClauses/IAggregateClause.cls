/**
 * An interface for classes that build a single aggregate function clause in a SOQL query.
 */
public interface IAggregateClause {
  /**
   * Builds the aggregate clause string.
   *
   * @return The constructed aggregate clause.
   */
  String build();

  /**
   * Builds the aggregate clause with a relationship name prefix for parent relationship queries.
   *
   * @param parentRelationName The relationship name of the parent object.
   * @return The constructed aggregate clause with the relationship prefix.
   */
  String buildWithChild(String parentRelationName);

  /**
   * Gets the alias defined for this aggregate clause.
   *
   * @return The alias.
   */
  String getAlias();

  /**
   * Gets the API name of the field being aggregated.
   *
   * @return The field's API name.
   */
  String getFieldName();

  /**
   * Overrides the internal metadata for the clause.
   *
   * @param sObjectType The SObjectType to use for context.
   * @param fieldMap The field map of the relevant SObject.
   * @return A new IAggregateClause instance with the updated metadata.
   */
  IAggregateClause overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap);
}
