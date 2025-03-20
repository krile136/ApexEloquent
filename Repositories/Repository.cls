public with sharing class Repository implements RepositoryInterface {
  private final Integer MAX_DML_CHUNKING = 10;

  /**
   * SOQLを実行し、結果を取得する
   *
   * @param query SOQLクエリ
   * @return 取得結果
   */
  public List<SObject> get(Query query) {
    String soql = query.toSoql();
    return (List<SObject>) Database.query(soql);
  }

  /**
   * SOQLを実行し、結果を取得する
   * 取得結果が0件の場合は例外をスローする
   *
   * @param query SOQLクエリ
   * @return 取得結果
   * @throws QueryException 取得結果が0件の場合
   */
  public List<SObject> getOrFail(Query query) {
    String soql = query.toSoql();
    List<SObject> objects = (List<SObject>) Database.query(soql);
    if (objects.isEmpty()) {
      throw new QueryException('No records found for query: ' + soql);
    }
    return objects;
  }

  /**
   * SOQLを実行し、最初の1件を返す
   * 取得結果が0件の場合はnullを返す
   *
   * @param query SOQLクエリ
   * @return 取得結果
   */
  public SObject first(Query query) {
    List<SObject> records = get(query);
    if (records.isEmpty()) {
      return null;
    }
    return records[0];
  }

  /**
   * SOQLを実行し、最初の1件を返す
   * 取得結果が0件の場合は例外をスローする
   *
   * @param query SOQLクエリ
   * @return 取得結果
   * @throws QueryException 取得結果が0件の場合
   */
  public SObject firstOrFail(Query query) {
    List<SObject> records = get(query);
    if (records.isEmpty()) {
      throw new QueryException('No records found for query: ' + query.toSoql());
    }
    return records[0];
  }

  /**
   * レコードを新規登録する
   *
   * @param record 新規登録するレコード
   * @return 登録したレコード
   */
  public SObject doInsert(SObject record) {
    insert record;
    return record;
  }

  /**
   * レコードを新規登録する
   *
   * @param records 新規登録するレコードのリスト
   * @return 登録したレコードのリスト
   */
  public List<SObject> doInsert(List<SObject> records) {
    sortToPreventChunkingErrors(records);
    insert records;
    return records;
  }

  /**
   * レコードを更新する
   *
   * @param record 更新するレコード
   * @return 更新したレコード
   */
  public SObject doUpdate(SObject record) {
    update record;
    return record;
  }

  /**
   * レコードを更新する
   *
   * @param records 更新するレコードのリスト
   * @return 更新したレコードのリスト
   */
  public List<SObject> doUpdate(List<SObject> records) {
    sortToPreventChunkingErrors(records);
    update records;
    return records;
  }

  /**
   * レコードを削除する
   *
   * @param record 削除するレコード
   */
  public void doDelete(SObject record) {
    delete record;
  }

  /**
   * レコードを削除する
   *
   * @param records 削除するレコードのリスト
   */
  public void doDelete(List<SObject> records) {
    delete records;
  }

  /**
   * チャンキングエラーを防ぐためにソートする
   *
   * @param records ソートするレコードのリスト
   */
  private void sortToPreventChunkingErrors(List<SObject> records) {
    if (records.size() >= MAX_DML_CHUNKING) {
      records.sort();
    }
  }
}
