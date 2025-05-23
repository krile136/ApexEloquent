public with sharing class Evaluator implements EvaluatorInterface {
  private final SObject record;

  /**
   * constructor
   *
   * @param record SObject
   */
  public Evaluator(SObject record) {
    this.record = record;
  }

  /**
   * @inheritDoc
   */
  public Object get(String fieldName) {
    Schema.DescribeSObjectResult describeResult = record.getSObjectType().getDescribe();

    // validate the fieldName
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
    if (!fieldMap.containsKey(fieldName)) {
      throw new QueryException(
        'The specified field does not exist in the object\'s fields. object name: ' + describeResult.getName() + ', field name: ' + fieldName
      );
    }

    return record.get(fieldName);
  }

  public Object getRelation(String relationName) {
    Schema.DescribeSObjectResult describeResult = record.getSObjectType().getDescribe();
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

    // Check if the fieldName is a child relationship
    List<Schema.ChildRelationship> children = describeResult.getChildRelationships();
    for (Schema.ChildRelationship child : children) {
      if (child.getChildSObject().getDescribe().getName() == relationName) {
        String childRelationName = child.getRelationshipName();
        List<SObject> childRecords = new List<SObject>();
        for(SObject childSObject : record.getSObjects(childRelationName)) {
          childRecords.add(childSObject);
        }
        return childRecords;
      }
    }

    String errorMessage =
      'The relationName is not children Object Name or Parent relationId field Name. object name: ' +
      describeResult.getName() +
      ', relation name ' +
      relationName;

    Schema.SObjectField field = fieldMap.get(relationName);
    if (field == null) {
      throw new QueryException(errorMessage);
    }

    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
    if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
      throw new QueryException(errorMessage);
    }

    String parentRelationName = fieldDescribe.getRelationshipName();
    return record.getSObject(parentRelationName);
  }

  /**
   * @inheritDoc
   *
   * This method is very similar to getRelation method, but getSObjects method occur error when children record count is over 200.
   * so, getSobjects method needs to use in loop.
   */
  public Object getRelationAsEvaluator(String relationName) {
    Schema.DescribeSObjectResult describeResult = record.getSObjectType().getDescribe();
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

    // Check if the fieldName is a child relationship
    List<Schema.ChildRelationship> children = describeResult.getChildRelationships();
    for (Schema.ChildRelationship child : children) {
      if (child.getChildSObject().getDescribe().getName() == relationName) {
        String childRelationName = child.getRelationshipName();
        List<EvaluatorInterface> childEvaluators = new List<EvaluatorInterface>();
        for (SObject childSObject : record.getSObjects(childRelationName)) {
          childEvaluators.add(new Evaluator(childSObject));
        }
        return childEvaluators;
      }
    }

    String errorMessage =
      'The relationName is not children Object Name or Parent relationId field Name. object name: ' +
      describeResult.getName() +
      ', relation name ' +
      relationName;

    Schema.SObjectField field = fieldMap.get(relationName);
    if (field == null) {
      throw new QueryException(errorMessage);
    }

    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
    if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
      throw new QueryException(errorMessage);
    }

    String parentRelationName = fieldDescribe.getRelationshipName();
    SObject parentSObject = record.getSObject(parentRelationName);
    if(parentSObject == null) {
      return null;
    }
    return new Evaluator((SObject) parentSObject);
  }

  /**
   * @inheritDoc
   */
  public Id getId() {
    return (Id) record.get('Id');
  }

  /**
   * @inheritDoc
   */
  public String getName() {
    return (String) record.get('Name');
  }

  /**
   * @inheritDoc
   */
  public SObject getRecord() {
    return record;
  }

  public EvaluatorInterface setRecord(SObject record) {
    return new Evaluator(record);
  }
}
