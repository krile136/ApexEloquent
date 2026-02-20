public with sharing class ApexEloquentException extends Exception {
  private static final String LINE_1 = '====== APEX ELOQUENT EXCEPTION ======';

  // -------------- message --------------
  public static ApexEloquentException message(String className, String methodName, String reason, String action) {
    String errorMessage = createMessage(className, methodName, reason, action);
    return new ApexEloquentException(errorMessage);
  }

  public static ApexEloquentException message(
    String className,
    String methodName,
    String reason,
    String action,
    Exception e
  ) {
    String errorMessage = createMessage(className, methodName, reason, action);
    return new ApexEloquentException(errorMessage, e);
  }

  private static String createMessage(String className, String methodName, String reason, String action) {
    String labelClassMethod = 'Location';
    String labelError = 'Error';
    String labelReason = 'Reason';
    String labelAction = 'Action';

    Integer padSize = labelClassMethod.length();

    String line2 = labelClassMethod.rightPad(padSize) + ': ' + className + '.' + methodName;
    String line3 = labelError.rightPad(padSize) + ': ' + reason;
    String line4 = labelAction.rightPad(padSize) + ': ' + action;

    return mergeLines(new List<String>{ LINE_1, line2, line3, line4 });
  }

  // -------------- invalidArgument --------------

  public static ApexEloquentException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    String param,
    Object provided
  ) {
    Map<String, Object> paramToProvided = new Map<String, Object>{ param => provided };
    String errorMessage = createInValidArgumentMessage(className, methodName, reason, action, paramToProvided);
    return new ApexEloquentException(errorMessage);
  }


  public static ApexEloquentException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    String param,
    Object provided,
    Exception e
  ) {
    Map<String, Object> paramToProvided = new Map<String, Object>{ param => provided };
    String errorMessage = createInValidArgumentMessage(className, methodName, reason, action, paramToProvided);
    return new ApexEloquentException(errorMessage, e);
  }
  
  public static ApexEloquentException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    Map<String, Object> paramToProvided
  ) {
    String errorMessage = createInValidArgumentMessage(className, methodName, reason, action, paramToProvided);
    return new ApexEloquentException(errorMessage); 
  }

  public static ApexEloquentException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    Map<String, Object> paramToProvided,
    Exception e
  ) {
    String errorMessage = createInValidArgumentMessage(className, methodName, reason, action, paramToProvided);
    return new ApexEloquentException(errorMessage, e); 
  }

  private static String createInValidArgumentMessage(
    String className,
    String methodName,
    String reason,
    String action,
    Map<String, Object> paramToProvided
  ) {
    String labelClassMethod = 'Location';
    String labelError = 'Error';
    String labelReason = 'Reason';
    String labelAction = 'Action';
    String labelProvided = 'Provided';

    Integer padSize = labelClassMethod.length();

    String line2 = labelClassMethod.rightPad(padSize) + ': ' + className + '.' + methodName;
    String argPhrase = paramToProvided.size() == 1 
    ? 'The `' + new List<String>(paramToProvided.keySet())[0] + '` argument is Invalid.'
    : 'The provided arguments are Invalid.';
    String line3 = labelError.rightPad(padSize) + ': ' + argPhrase;
    String line4 = labelReason.rightPad(padSize) + ': ' + reason;
    String line5 = labelAction.rightPad(padSize) + ': ' + action;
    List<String> providedValueStrings = new List<String>();
    for(String paramName : paramToProvided.keySet()) {
      String providedValueString = '[' + paramName + ' => ';
      Object providedValue = paramToProvided.get(paramName);
      if (providedValue == null) {
        providedValueString += 'null';
      } else if (providedValue instanceof String && String.isBlank((String) providedValue)) {
        providedValueString += 'empty string';
      } else {
        String valueStr = String.valueOf(providedValue);
        if(providedValue instanceof String) {
          valueStr = '\'' + valueStr + '\'';
        }
        providedValueString += valueStr;
      }
      providedValueString += ']';
      providedValueStrings.add(providedValueString);
    }
    String line6 = labelProvided.rightPad(padSize) + ': ' + String.join(providedValueStrings, ', ');

    return mergeLines(new List<String>{ LINE_1, line2, line3, line4, line5, line6 });
  }

  // -------------- invalidOperation --------------

  public static ApexEloquentException invalidOperation(
    String className,
    String methodName,
    String reason
  ) {
    String errorMessage = createInvalidOperationMessage(className, methodName, reason);
    return new ApexEloquentException(errorMessage);
  }

  public static ApexEloquentException invalidOperation(
    String className,
    String methodName,
    String reason,
    Exception e
  ) {
    String errorMessage = createInvalidOperationMessage(className, methodName, reason);
    return new ApexEloquentException(errorMessage, e);
  }

  private static String createInvalidOperationMessage(String className, String methodName, String reason) {
    String labelClassMethod = 'Location';
    String labelError = 'Error';
    String labelReason = 'Reason';

    Integer padSize = labelClassMethod.length();

    String line2 = labelClassMethod.rightPad(padSize) + ': ' + className + '.' + methodName;
    String line3 = labelError.rightPad(padSize) + ': Invalid operation.';
    String line4 = labelReason.rightPad(padSize) + ': ' + reason;

    return mergeLines(new List<String>{ LINE_1, line2, line3, line4 });
  }

  // -------------- required --------------

  public static ApexEloquentException required(
    String className,
    String methodName,
    String param,
    Object provided
  ) {
    String errorMessage = createRequiredMessage(className, methodName, param, provided); 
    return new ApexEloquentException(errorMessage);
  }

  public static ApexEloquentException required(
    String className,
    String methodName,
    String param,
    Object provided,
    Exception e
  ) {
    String errorMessage = createRequiredMessage(className, methodName, param, provided); 
    return new ApexEloquentException(errorMessage, e);
  }

  private static String createRequiredMessage(String className, String methodName, String param, Object provided) {
    String labelClassMethod = 'Location';
    String labelError = 'Error';
    String labelReason = 'Reason';
    String labelProvided = 'Provided';

    Integer padSize = labelClassMethod.length();

    String line1 = labelClassMethod.rightPad(padSize) + ': ' + className + '.' + methodName;
    String line2 = labelError.rightPad(padSize) + ': The `' + param + '` argument is required.';
    String line3 = labelReason.rightPad(padSize) + ': Missing required parameter.';
    String providedValueString;
    if (provided == null) {
      providedValueString = 'null';
    } else if (provided instanceof String && String.isBlank((String) provided)) {
      providedValueString = 'empty string';
    } else {
      providedValueString = String.valueOf(provided);
    }
    String line4 = labelProvided.rightPad(padSize) + ': ' + providedValueString;

    return mergeLines(new List<String>{ LINE_1, line1, line2, line3, line4 });
  }

  // -------------- helper --------------

  private static String mergeLines(List<String> lines) {
    return '\n' + String.join(lines, '\n');
  }
}
