public with sharing class FieldStructure {
  private List<String> fields;
  private Map<String, FieldStructure> relations;

  public FieldStructure() {
    this.fields = new List<String>();
    this.relations = new Map<String, FieldStructure>();
  }

  public FieldStructure(List<String> fields) {
    this.fields = fields;
    this.relations = new Map<String, FieldStructure>();
  }

  public FieldStructure(List<String> fields, Map<String, FieldStructure> relations) {
    this.fields = fields;
    this.relations = relations;
  }

  /**
   * Checks if the current FieldStructure has any relations.
   * @return Boolean - True if relations exist, false otherwise.
   */
  public Boolean hasRelation() {
    return !this.relations.isEmpty();
  }

  /**
   * Checks if the current FieldStructure contains a specific relation by name.
   * @param relationName The name of the relation to check.
   * @return Boolean - True if the relation exists, false otherwise.
   */
  public Boolean hasRelation(String relationName) {
    return this.relations.containsKey(relationName);
  }

  /**
   * Checks if the current FieldStructure contains a specific field by name.
   * @param fieldName The name of the field to check.
   * @return Boolean - True if the field exists, false otherwise.
   */
  public Boolean hasField(String fieldName) {
    return this.fields.contains(fieldName);
  }

  /**
   * Retrieves the number of fields in the current FieldStructure.
   * @return Integer - The count of fields.
   */
  public Integer getFieldCount() {
    return this.fields.size();
  }

  /**
   * Retrieves the FieldStructure associated with a specific relation name.
   * @param relationName The name of the relation to retrieve.
   * @return FieldStructure - The FieldStructure of the relation, or null if not found.
   */
  public FieldStructure getRelationFieldStructure(String relationName) {
    if (this.relations.containsKey(relationName)) {
      return this.relations.get(relationName);
    }
    return new FieldStructure();
  }
}
