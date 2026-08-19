/**
 * @directory ApexEloquent
 */
public with sharing class ApexEloquentException extends Exception {
  private static final String LINE_1 = '====== APEX ELOQUENT EXCEPTION ======';

  private String className;
  private String methodName;
  private String error;
  private String reason;
  private String action;
  private Map<String, Object> params = new Map<String, Object>();
  private Exception originalException;

  private static String LABEL_LOCATION = 'Location';
  private static String LABEL_ERROR = 'Error';
  private static String LABEL_REASON = 'Reason';
  private static String LABEL_ACTION = 'Action';
  private static String LABEL_PROVIDED = 'Provided';

  private static Integer PAD_SIZE = LABEL_LOCATION.length();

  // -------------- builder --------------

  public static ApexEloquentException at(String className) {
    ApexEloquentException e = new ApexEloquentException();
    e.className = className;
    return e;
  }

  public ApexEloquentException overrideClassName(String className) {
    ApexEloquentException e = this.cloneError();
    e.className = className;
    return e;
  }

  public ApexEloquentException method(String methodName) {
    ApexEloquentException e = this.cloneError();
    e.methodName = methodName;
    return e;
  }

  public ApexEloquentException error(String error) {
    ApexEloquentException e = this.cloneError();
    e.error = error;
    return e;
  }

  public ApexEloquentException reason(String reason) {
    ApexEloquentException e = this.cloneError();
    e.reason = reason;
    return e;
  }

  public ApexEloquentException action(String action) {
    ApexEloquentException e = this.cloneError();
    e.action = action;
    return e;
  }

  public ApexEloquentException param(String paramName, Object provided) {
    ApexEloquentException e = this.cloneError();
    e.params.put(paramName, provided);
    return e;
  }

  public ApexEloquentException causedBy(Exception originalException) {
    ApexEloquentException e = this.cloneError();
    e.originalException = originalException;
    return e;
  }

  public ApexEloquentException build() {
    List<String> lines = new List<String>{};
    lines.add('====== APEX ELOQUENT EXCEPTION ======');
    String location = 'Location'.rightPad(PAD_SIZE) + ': ' + this.className;
    if(this.methodName != null) {
      location += '.' + this.methodName + '()';
    }
    lines.add(location);
    if (this.error != null) {
      lines.add('Error'.rightPad(PAD_SIZE) + ': ' + this.error);
    }
    if (this.reason != null) {
      lines.add('Reason'.rightPad(PAD_SIZE) + ': ' + this.reason);
    }
    if (this.action != null) {
      lines.add('Action'.rightPad(PAD_SIZE) + ': ' + this.action);
    }
    if (!this.params.isEmpty()) {
      lines.add('Provided'.rightPad(PAD_SIZE) + ': ' + this.buildProvidedValueString());
    }

    String errorMessage = mergeLines(lines);

    if (this.originalException != null) {
      return new ApexEloquentException(errorMessage, this.originalException);
    }
    return new ApexEloquentException(errorMessage);
  }

  public void fire() {
    throw this.build();
  }

  private ApexEloquentException cloneError() {
    ApexEloquentException e = new ApexEloquentException();
    e.className = this.className;
    e.methodName = this.methodName;
    e.error = this.error;
    e.reason = this.reason;
    e.action = this.action;
    e.params = this.params.clone();
    e.originalException = this.originalException;
    return e;
  }

  // -------------- message --------------
  public static ApexEloquentException message(String className, String methodName, String err, String action) {
    ApexEloquentException ex = ApexEloquentException.at(className).method(methodName).error(err).action(action);

    return ex;
  }

  public static ApexEloquentException message(
    String className,
    String methodName,
    String err,
    String action,
    Exception e
  ) {
    ApexEloquentException ex = ApexEloquentException.at(className)
      .method(methodName)
      .error(err)
      .action(action)
      .causedBy(e);

    return ex;
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
    String argPhase = createArgPhase(paramToProvided);
    ApexEloquentException invalidArgExceptioin = ApexEloquentException.at(className)
      .method(methodName)
      .error(argPhase)
      .reason(reason)
      .action(action);
    for (String paramName : paramToProvided.keySet()) {
      invalidArgExceptioin = invalidArgExceptioin.param(paramName, paramToProvided.get(paramName));
    }
    return invalidArgExceptioin;
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
    String argPhase = createArgPhase(paramToProvided);
    ApexEloquentException invalidArgExceptioin = ApexEloquentException.at(className)
      .method(methodName)
      .error(argPhase)
      .reason(reason)
      .action(action)
      .causedBy(e);
    for (String paramName : paramToProvided.keySet()) {
      invalidArgExceptioin = invalidArgExceptioin.param(paramName, paramToProvided.get(paramName));
    }
    return invalidArgExceptioin;
  }

  public static ApexEloquentException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    Map<String, Object> paramToProvided
  ) {
    String argPhase = createArgPhase(paramToProvided);
    ApexEloquentException invalidArgExceptioin = ApexEloquentException.at(className)
      .method(methodName)
      .error(argPhase)
      .reason(reason)
      .action(action);
    for (String paramName : paramToProvided.keySet()) {
      invalidArgExceptioin = invalidArgExceptioin.param(paramName, paramToProvided.get(paramName));
    }
    return invalidArgExceptioin;
  }

  public static ApexEloquentException invalidArgument(
    String className,
    String methodName,
    String reason,
    String action,
    Map<String, Object> paramToProvided,
    Exception e
  ) {
    String argPhase = createArgPhase(paramToProvided);
    ApexEloquentException invalidArgExceptioin = ApexEloquentException.at(className)
      .method(methodName)
      .error(argPhase)
      .reason(reason)
      .action(action)
      .causedBy(e);
    for (String paramName : paramToProvided.keySet()) {
      invalidArgExceptioin = invalidArgExceptioin.param(paramName, paramToProvided.get(paramName));
    }
    return invalidArgExceptioin;
  }

  private static String createArgPhase(Map<String, Object> paramToProvided) {
    if (paramToProvided.size() == 1) {
      return 'The `' + new List<String>(paramToProvided.keySet())[0] + '` argument is Invalid.';
    }
    return 'The provided arguments are Invalid.';
  }

  // -------------- invalidOperation --------------

  public static ApexEloquentException invalidOperation(String className, String methodName, String reason) {
    string error = 'Invalid operation';
    ApexEloquentException ex = ApexEloquentException.at(className).method(methodName).error(error).reason(reason);

    return ex;
  }

  public static ApexEloquentException invalidOperation(
    String className,
    String methodName,
    String reason,
    Exception e
  ) {
    string error = 'Invalid operation';
    ApexEloquentException ex = ApexEloquentException.at(className)
      .method(methodName)
      .error(error)
      .reason(reason)
      .causedBy(e);

    return ex;
  }

  // -------------- required --------------

  public static ApexEloquentException required(
    String className,
    String methodName,
    String param,
    Object provided
  ) {
    String error = 'The `' + param + '` argument is required';
    String reason = 'Missing required parameter';
    ApexEloquentException ex = ApexEloquentException.at(className)
      .method(methodName)
      .error(error)
      .reason(reason)
      .param(param, provided);
    return ex;
  }

  public static ApexEloquentException required(
    String className,
    String methodName,
    String param,
    Object provided,
    Exception e
  ) {
    String error = 'The `' + param + '` argument is required';
    String reason = 'Missing required parameter';
    ApexEloquentException ex = ApexEloquentException.at(className)
      .method(methodName)
      .error(error)
      .reason(reason)
      .param(param, provided)
      .causedBy(e);
    return ex;
  }

  // -------------- helper --------------

  private static String mergeLines(List<String> lines) {
    return '\n' + String.join(lines, '\n');
  }

  private String buildProvidedValueString() {
    List<String> providedValueStrings = new List<String>();
    for (String paramName : this.params.keySet()) {
      String providedValueString = '[' + paramName + ' => ';
      Object providedValue = this.params.get(paramName);
      if (providedValue == null) {
        providedValueString += 'null';
      } else if (providedValue instanceof String && String.isBlank((String) providedValue)) {
        providedValueString += 'empty string';
      } else {
        String valueStr = String.valueOf(providedValue);
        if (providedValue instanceof String) {
          valueStr = '\'' + valueStr + '\'';
        }
        providedValueString += valueStr;
      }
      providedValueString += ']';
      providedValueStrings.add(providedValueString);
    }

    return String.join(providedValueStrings, ', ');
  }
}
