public with sharing abstract class AbstractWhereClause implements WhereClauseInterface {
  protected final Schema.SObjectType sObjectType;
  protected final Map<String, Schema.SObjectField> fieldMap;
  protected final String field;
  protected final String operator;

  /**
   * SOQL発行時にシングルクォートが必要な型
   */
  protected final List<Schema.DisplayType> TYPES_REQUIRING_SINGLE_QUOTES = new List<Schema.DisplayType>{
    DisplayType.STRING,
    DisplayType.TEXTAREA,
    DisplayType.PICKLIST,
    DisplayType.MULTIPICKLIST,
    DisplayType.ID,
    DisplayType.REFERENCE,
    DisplayType.URL,
    DisplayType.EMAIL,
    DisplayType.PHONE,
    DisplayType.ENCRYPTEDSTRING,
    DisplayType.ANYTYPE
  };

  /**
   * コンストラクタ
   */
  public AbstractWhereClause(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap, String field, String operator) {
    this.sObjectType = sObjectType;
    this.fieldMap = fieldMap;
    this.field = field;
    this.operator = operator;
  }

  /**
   * 継承先で実装をするメソッド
   */
  public abstract WhereClauseInterface overrideMetaData(Schema.SObjectType sObjectType, Map<String, Schema.SObjectField> fieldMap);
  protected abstract String generate();
  private abstract String checkAndCast();

  /**
   * Where句を組み立てる
   * @return 組み立てたWhere句
   */
  public String build() {
    return this.field + ' ' + this.operator + ' ' + this.generate();
  }

  /**
   * fieldの型を取得する
   * @param field フィールド名
   * @return フィールドの型
   */
  protected Schema.DisplayType getFieldType(String field) {
    if (this.sObjectType == null) {
      throw new QueryException('sourceが設定されていません');
    }
    if (!this.fieldMap.containsKey(field)) {
      // フィールドが存在しない場合は、String型として扱う
      // 例) Queue.Name とかはSObjectTypeがQueueSObjectと認識されフィールドにNameが存在しないがクエリ発行はできる
      return Schema.DisplayType.STRING;
    }
    Schema.DisplayType fieldType = this.fieldMap.get(field).getDescribe().getType();
    return fieldType;
  }

  /**
   * 型に応じて値をフォーマットして文字列にキャストする
   * @param value 値
   * @return フォーマットしてキャストした文字列
   */
  protected String formatAndCastToString(Object value) {
    if (value instanceof Date) {
      Date dateValue = (Date) value;
      return dateValue.year() + '-' + String.valueOf(dateValue.month()).leftPad(2, '0') + '-' + String.valueOf(dateValue.day()).leftPad(2, '0');
    }
    if (value instanceof Datetime) {
      Datetime datetimeValue = (Datetime) value;
      // Get the timezone offset in milliseconds
      Integer offsetMillis = UserInfo.getTimeZone().getOffset(datetimeValue);
      // Convert offset to hours
      Integer offsetHours = offsetMillis / (1000 * 60 * 60);
      // Adjust the datetime by subtracting the offset
      Datetime adjustedDatetime = datetimeValue.addHours(-offsetHours);
      return adjustedDatetime.year() +
          '-' +
          String.valueOf(adjustedDatetime.month()).leftPad(2, '0') +
          '-' +
          String.valueOf(adjustedDatetime.day()).leftPad(2, '0') +
          'T' +
          String.valueOf(adjustedDatetime.hour()).leftPad(2, '0') +
          ':' +
          String.valueOf(adjustedDatetime.minute()).leftPad(2, '0') +
          ':' +
          String.valueOf(adjustedDatetime.second()).leftPad(2, '0') +
          'Z';
    }
    return String.escapeSingleQuotes(String.valueOf(value));
  }

}
