public with sharing class FieldStructure {
  private List<String> fields;
  private Map<String, FieldStructure> relations;

  /**
   * Default constructor initializing empty fields and relations.
   */
  public FieldStructure() {
    this.fields = new List<String>();
    this.relations = new Map<String, FieldStructure>();
  }

  /**
   * Constructor initializing with a list of fields and empty relations.
   *
   * @param fields List of field names.
   */
  public FieldStructure(List<String> fields) {
    this.fields = fields;
    this.relations = new Map<String, FieldStructure>();
  }

  /**
   * Constructor initializing with a list of fields and a map of relations.
   *
   * @param fields List of field names.
   * @param relations Map of relation names to their corresponding FieldStructure.
   */
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
    System.debug('this fields: ' + this.fields);
    return this.fields.contains(fieldName);
  }

  /**
   * Adds a field to the current FieldStructure.
   *
   * @param relationName The name of the relation to add.
   * @param fieldStructure The FieldStructure of the relation.
   */
  public void addField(String fieldName) {
    if (!this.fields.contains(fieldName)) {
      this.fields.add(fieldName);
    }
  }

  /**
   * Removes a field from the current FieldStructure.
   *
   * @param relationName The name of the relation to add.
   * @param fieldStructure The FieldStructure of the relation.
   */
  public void removeField(String fieldName) {
    List<String> filteredFields = new List<String>();
    for (String field : this.fields) {
      if (field != fieldName) {
        filteredFields.add(field);
      }
    }
    this.fields = filteredFields;
  }

  /**
   * Checks if the current FieldStructure is empty (no fields and relations have no fields).
   *
   * @return Boolean - True if empty, false otherwise.
   */
  public Boolean isEmpty() {
    Boolean isFieldsEmpty = this.fields.isEmpty();
    Boolean isRelationEmpty;
    if (this.relations.isEmpty()) {
      isRelationEmpty = true;
    } else {
      isRelationEmpty = true;
      for (FieldStructure relationFieldStructure : this.relations.values()) {
        if (!relationFieldStructure.isEmpty()) {
          isRelationEmpty = false;
          break;
        }
      }
    }
    return isFieldsEmpty && isRelationEmpty;
  }

  /**
   * Gets the list of fields in the current FieldStructure as flatten.
   *
   * @return List<String> - List of field names.
   */
  public List<String> getAllFieldsAsFlatten() {
    List<String> allFields = new List<String>();
    allFields.addAll(this.fields);
    for (FieldStructure fieldStructure : this.relations.values()) {
      allFields.addAll(fieldStructure.getAllFieldsAsFlatten());
    }

    return allFields;
  }

  /**
   * Gets the list of fields in the current FieldStructure as flatten with relation names prefixed.
   *
   * @param relationName The prefix for relation names.
   * @return List<String> - List of field names with relation prefixes.
   */
  public List<String> getFieldsAsFlattenWithRelationName(String relationName) {
    List<String> allFields = new List<String>();
    if (relationName != null) {
      for (String field : this.fields) {
        allFields.add(relationName + '.' + field);
      }
    } else {
      allFields.addAll(this.fields);
    }
    for (String relation : this.relations.keySet()) {
      String chainedRelationName = relationName != null ? relationName + '.' + relation : relation;
      FieldStructure relationFieldStructure = this.relations.get(relation);
      List<String> relationFields = relationFieldStructure.getFieldsAsFlattenWithRelationName(chainedRelationName);
      allFields.addAll(relationFields);
    }

    return allFields;
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
