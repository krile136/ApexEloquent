public with sharing class Evaluator extends AbstractEvaluator {
  /**
   * constructor
   *
   * @param record SObject
   */
  public Evaluator(SObject record) {
    super(record);
  }

  /**
   * constructor with picked fields and relation fields
   *
   * @param record SObject
   * @param pickedFields List of field names to be picked
   * @param pickedRelationFields Map of relation names to be picked
   */
  public Evaluator(SObject record, List<String> pickedFields, Map<String, Object> pickedRelationFields) {
    super(record, pickedFields, pickedRelationFields);
  }

  /**
   * @inheritDoc
   */
  public override Object get(String fieldName) {
    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();

    // validate the fieldName
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
    if (!fieldMap.containsKey(fieldName)) {
      throw new QueryException(
        'The specified field does not exist in the object\'s fields. object name: ' +
          describeResult.getName() +
          ', field name: ' +
          fieldName
      );
    }

    return record.get(fieldName);
  }

  /**
   * @inheritDoc
   */
  public override Object getRelation(String relationName) {
    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

    // Check if the fieldName is a child relationship
    List<Schema.ChildRelationship> children = describeResult.getChildRelationships();
    for (Schema.ChildRelationship child : children) {
      if (child.getChildSObject().getDescribe().getName() == relationName) {
        String childRelationName = child.getRelationshipName();
        List<SObject> childRecords = new List<SObject>();
        for (SObject childSObject : this.record.getSObjects(childRelationName)) {
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
    return this.record.getSObject(parentRelationName);
  }

  /**
   * @inheritDoc
   */
  public override Object getRelationAsEvaluator(String relationName) {
    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

    // Check if the fieldName is a child relationship
    List<Schema.ChildRelationship> children = describeResult.getChildRelationships();
    for (Schema.ChildRelationship child : children) {
      if (child.getChildSObject().getDescribe().getName() == relationName) {
        String childRelationName = child.getRelationshipName();
        List<EvaluatorInterface> childEvaluators = new List<EvaluatorInterface>();
        for (SObject childSObject : this.record.getSObjects(childRelationName)) {
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
    SObject parentSObject = this.record.getSObject(parentRelationName);
    if (parentSObject == null) {
      return null;
    }
    return new Evaluator((SObject) parentSObject);
  }

  /**
   * @inheritDoc
   */
  public override Object getParent(String parentFieldName) {
    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

    Schema.SObjectField field = fieldMap.get(parentFieldName);
    if (field == null) {
      throw new QueryException(
        'The specified parentFieldName does not exist in the object\'s fields. object name: ' +
          describeResult.getName() +
          ', field name: ' +
          parentFieldName
      );
    }

    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
    if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
      throw new QueryException(
        'The specified parentFieldName is not a reference type. object name: ' +
          describeResult.getName() +
          ', field name: ' +
          parentFieldName
      );
    }

    String parentRelationName = fieldDescribe.getRelationshipName();
    return this.record.getSObject(parentRelationName);
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface getParentAsEvaluator(String parentFieldName) {
    SObject parentSObject = (SObject) getParent(parentFieldName);
    if (parentSObject == null) {
      return null;
    }
    return new Evaluator(parentSObject);
  }

  /**
   * @inheritDoc
   */
  public override List<Object> getChildren(String childObjectName) {
    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
    List<Schema.ChildRelationship> children = describeResult.getChildRelationships();

    for (Schema.ChildRelationship child : children) {
      if (child.getChildSObject().getDescribe().getName() == childObjectName) {
        String childRelationName = child.getRelationshipName();
        List<SObject> childRecords = new List<SObject>();
        for (SObject childSObject : this.record.getSObjects(childRelationName)) {
          childRecords.add(childSObject);
        }
        return childRecords;
      }
    }

    throw new QueryException(
      'The specified childObjectName does not exist in the object\'s child relationships. object name: ' +
        describeResult.getName() +
        ', child name: ' +
        childObjectName
    );
  }

  /**
   * @inheritDoc
   */
  public override List<EvaluatorInterface> getChildrenAsEvaluators(String childObjectName) {
    Schema.DescribeSObjectResult describeResult = this.record.getSObjectType().getDescribe();
    List<Schema.ChildRelationship> children = describeResult.getChildRelationships();

    for (Schema.ChildRelationship child : children) {
      if (child.getChildSObject().getDescribe().getName() == childObjectName) {
        String childRelationName = child.getRelationshipName();
        List<EvaluatorInterface> childEvaluators = new List<EvaluatorInterface>();
        for (SObject childSObject : this.record.getSObjects(childRelationName)) {
          childEvaluators.add(new Evaluator(childSObject));
        }
        return childEvaluators;
      }
    }

    throw new QueryException(
      'The specified childObjectName does not exist in the object\'s child relationships. object name: ' +
        describeResult.getName() +
        ', child name: ' +
        childObjectName
    );
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface setRecord(SObject record) {
    return new Evaluator(record);
  }

  /**
   * @inheritDoc
   */
  public override EvaluatorInterface setPickedFields(
    List<String> pickedFields,
    Map<String, Object> pickedRelationFields
  ) {
    return new Evaluator(this.record, pickedFields, pickedRelationFields);
  }
}
