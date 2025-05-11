public with sharing class MockEvaluator implements EvaluatorInterface {
  private final SObject record;
  private final Map<String, Object> fieldToValue;

  public MockEvaluator(SObject record) {
    this(record, new Map<String, Object>());
  }

  public MockEvaluator(SObject record, Map<String, Object> fieldToValue) {
    this.record = record;
    this.fieldToValue = fieldToValue;
  }

  public Object get(String fieldName) {
    if (fieldToValue.containsKey(fieldName)) {
      return fieldToValue.get(fieldName);
    }
    Evaluator evaluator = new Evaluator(record);
    return evaluator.get(fieldName);
  }

  public Object getRelationAsEvaluator(String fieldName) {
    if(fieldToValue.containsKey(fieldName)) {
      if(fieldToValue.get(fieldName) == null) {
        return null;
      }

      return fieldToValue.get(fieldName);
    }

    Evaluator evaluator = new Evaluator(record);
    return evaluator.getRelationAsEvaluator(fieldName);
  }

  public List<EvaluatorInterface> getChildrenAsEvaluator(String fieldName) {
    if(fieldToValue.containsKey(fieldName)) {
      if(fieldToValue.get(fieldName) == null) {
        return null;
      }
      if(!(fieldToValue.get(fieldName) instanceof List<EvaluatorInterface>)) {
        throw new IllegalArgumentException('Field value is not a list of EvaluatorInterface');
      }
      return (List<EvaluatorInterface>) fieldToValue.get(fieldName);
    }
    
    Evaluator evaluator = new Evaluator(record);
    return evaluator.getChildrenAsEvaluator(fieldName);
  } 

  public Id getId() {
    return (Id) record.get('Id');
  }

  public String getName() {
    return (String) record.get('Name');
  }

  public SObject getRecord() {
    return record;
  }
}
