public interface EvaluatorInterface {
  Object get(String fieldName);
  Object get(Schema.sObjectField field);
  Id getId();
  String getName();
  SObject getRecord();
}
