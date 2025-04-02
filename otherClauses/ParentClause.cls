public with sharing class ParentClause {
  private String relationFieldName;
  private List<String> parentFields;

  public ParentClause(String relationFieldName, String parentFieldName) {
    this.relationFieldName = relationFieldName;
    this.parentFields = new List<String>{parentFieldName};
  }

  public ParentClause(String relationFieldName, List<String> parentFields) {
    this.relationFieldName = relationFieldName;
    this.parentFields = parentFields;
  }


  /**
  * Constructs the relationship names of parent fields using the specified field map.
  *
  * @param fieldMap A mapping of object field names to Schema.SObjectField
  * @return A comma-separated string of parent field relationship names
  * @throws QueryException If the parent field list is empty
  * @throws QueryException If the specified relationship ID field does not exist in the field map
  * @throws QueryException If the specified relationship ID field is not of a reference type
  * @throws QueryException If the specified relationship ID field does not have a relationship name
  */
  public String build(Map<String, Schema.SObjectField> fieldMap) {
    if(this.parentFields.isEmpty()) {
      throw new QueryException('The parent fields list is empty');
    }

    if(!fieldMap.containsKey(this.relationFieldName)) {
      throw new QueryException('The specified relation ID field does not exist in the object\'s fields');
    }

    Schema.SObjectField relationField = fieldMap.get(this.relationFieldName);
    Schema.DescribeFieldResult relationFieldDescribe = relationField.getDescribe();

    if(relationFieldDescribe.getType() != Schema.DisplayType.REFERENCE){
      throw new QueryException('The specified relation ID field is not of reference type');
    }

    String relationName = relationFieldDescribe.getRelationshipName();
    if(relationName == null){
      throw new QueryException('The specified relation ID field does not have a relationship name');
    }

    List<String> parentFieldNames = new List<String>();
    for(String parentFieldName : this.parentFields) {
      String parentRelationName = relationName + '.' + parentFieldName;
      parentFieldNames.add(parentRelationName);
    }
    return String.join(parentFieldNames, ', ');
  }
}
