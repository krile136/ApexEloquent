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

    // Check if the fieldName is a child relationship
    List<Schema.ChildRelationship> children = describeResult.getChildRelationships();
    for (Schema.ChildRelationship child : children) {
      if (child.getChildSObject().getDescribe().getName() == fieldName) {
        String relationName = child.getRelationshipName();
        List<SObject> childSObjects = record.getSObjects(relationName);
        if (childSObjects == null) {
          return null;
        }
        return childSObjects;
      }
    }

    // validate the fieldName
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
    if (!fieldMap.containsKey(fieldName)) {
      throw new QueryException(
        'The specified field does not exist in the object\'s fields. object name: ' + describeResult.getName() + ', field name ' + fieldName
      );
    }

    Schema.SObjectField field = fieldMap.get(fieldName);
    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
    if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
      return record.get(fieldName);
    }

    String relationName = fieldDescribe.getRelationshipName();
    return record.getSObject(relationName);
  }

  /**
   * @inheritDoc
   */
  public Object getRelationAsEvaluator(String fieldName) {
    Object fieldValue = get(fieldName);
    if (fieldValue == null) {
      return null;
    }
    if (fieldValue instanceof List<SObject>) {
      List<SObject> childSObjects = (List<SObject>) fieldValue;
      List<EvaluatorInterface> evaluators = new List<EvaluatorInterface>();
      for (SObject childSObject : childSObjects) {
        evaluators.add(new Evaluator(childSObject));
      }
      return evaluators;
    } else if (fieldValue instanceof SObject) {
      return new Evaluator((SObject) fieldValue);
    }
    throw new IllegalArgumentException('Field value is not a parent or a children. field name: ' + fieldName);
  }

  public List<EvaluatorInterface> getChildrenAsEvaluator(String fieldName) {
    List<Schema.ChildRelationship> children = record.getSObjectType().getDescribe().getChildRelationships();
    for (Schema.ChildRelationship child : children) {
      if (child.getChildSObject().getDescribe().getName() == fieldName) {
        String relationName = child.getRelationshipName();
        List<SObject> childSObjects = record.getSObjects(relationName);
        if (childSObjects == null) {
          return null;
        }
        List<EvaluatorInterface> evaluators = new List<EvaluatorInterface>();
        for (SObject childSObject : childSObjects) {
          evaluators.add(new Evaluator(childSObject));
        }
        return evaluators;
      }
    }

    return null;
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
}
