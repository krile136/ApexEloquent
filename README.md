# Apex Eloquentとは？

これはApexのデータベース操作を、LaravelのEloquentのように行うことできるようになるフレームワークです。
これにより、以下のようなメリットがあります。
- **可読性の向上**: SOQLを文字列で組み立てる必要がなくなり、可読性が向上
- **クエリの動的生成**: 柔軟に条件を追加できる
- **テスト容易性の向上**: リポジトリパターンを採用することで、テスト時にデータベース依存を減らす
- **型安全性の向上**: 変数の補完が効く

# Apexのデータベース操作の問題

### Apexにおけるクエリの書き方

#### 1. SOQLを文字列で作って実行する
```apex
String soql = 'SELECT ID, Name FROM Opportunity WHERE ID = :oppId AND .......';
Opportunity opp = Database.query(soql);
```

#### 2. 直接クエリ発行を書く
```apex
Opportunity opp = [SELECT ID, Name From Opportunity WHERE ID = :oppId AND .......];
```

### 上記のクエリの記述方法の問題点
1. 文字列でクエリを作る場合、フォーマットを効かせることができないのでクエリが長くなると条件が見づらくなる
1. `SELECT *` が使えないので、オブジェクトをクローンしたい時など全フィールドを取得する必要がある場合は文字列でクエリを作るしかなくなる
1. 途中まで共通のクエリで、ある条件の時だけSOQLに条件を追加したい、というような時は
    1. 文字列でクエリを作る場合、文字列操作をしないといけなくなり一般化しづらく、条件の追加も煩雑になる
    1. 直接書く場合はそもそもできない。
1. 文字列で書く方法だと変数を指定するときにIDEの補完機能が効かない
1. 両方の方法に置いて、SELECT句に変数を指定することができない
1. テストクラスを書く際に必ずデータベースへの依存が発生し、テストデータの投入が必要となる。
    1. テスト対象のクラスが増えるにつれて、テスト実行時間が長くなる

Apex Eloquentはこれらの問題をすべて解決できます。


# デモ

SOQL
```
SELECT Id, Name FROM Opportunity WHERE (Id IN (\'006000000000000\', \'006000000000001\')) AND ((Name = \'Test\' AND CloseDate <= 2024-12-31)) AND (AccountId IN (SELECT Id FROM Account WHERE (Name = \'TestAccount\')))
```

Apex Eloquent
```Apex
Schema.SObjectType oppSource = Opportunity.getSObjectType();
List<String> fields = new List<String>{ 'Id', 'Name' };
List<Id> ids = new List<Id>{ '006000000000000', '006000000000001' };

query = (new Query())
    .pick(fields)
    .source(oppSource)
    .condition('Id', 'IN', ids)
    .condition((new Query())
        .condition('Name', '=', 'Test')
        .condition('CloseDate', '<=', Date.newInstance(2024, 12, 31))
    )
    .join('AccountId', 'IN', (new Query())
        .source(accountSource)
        .pick('Id')
        .condition('Name', '=', 'TestAccount')
    );
```

# インストール方法
git submodule を使い、お使いのSalesforceプロジェクトにApex Eloquentを導入します。

テストクラスは標準オブジェクトの標準項目でコードカバレッジ75%以上を満たすように作成しているのでそのままデプロイ可能だと思いますが、テストに失敗する場合はお手数ですがそれぞれテストクラスのメンテナンスを行なってください。


# 使い方

## 既存の書き方
次のような、商談を取得して値を更新するクラスがあったとします。
```apex
public with sharing class OppUpdater {
  private final Id oppId;

  public OppUpdater(Id oppId) {
    this.oppId = oppId;
  }

  public Opportunity execute(){
    Opportunity opp = [SELECT ID, ....... FROM Opportunity WHERE ID = :this.oppId];

    // 何かしらの更新処理

    update opp;
    
    return opp;
  }
}
```

## Apex Eloquentパターンに変換
Apex Eloquentパターンに変換すると、次のようになります。
```apex
public with sharing class OppUpdater {
  private final Id oppId;
  private final RepositoryInterface oppRepo;

  public OppUpdater(Id oppId, RepositoryInterface oppRepo) {
    this.oppId = oppId;
    this.oppRepo = oppRepo ?? new Repository();
  }

  public Opportunity execute(){
    List<String> selectFields = new List<String>{'ID', .........};
    Schema.SObjectType oppSource = Opportunity.getSObjectType();
    Query query = (new Query())
      .pick(selectFields)
      .source(oppSource)
      .find(this.oppId)
    Opportunity opp = (Opportunity) this.oppRepo.first(query);

    // 何かしらの更新処理

    opp = this.oppRepo.doUpdate(opp);

    return opp;
  }
}
```

## テストクラスを書く
RepositoryInterfaceを仕様することで、データベースを介さずにロジックの検証が可能になります。
```apex
@isTest(seeAllData=false)
public with sharing class OppUpdater_T {
  public static testMethod void testUpdate() {
    // モックする商談とリポジトリを用意
    Opportunity mockOpp = new Opportunity();
    MockRepository mockRepo = new MockRepository(mockOpp);

    // OppUpdaterにコンストラクタインジェクションすることで、executeメソッドないの
    // 商談取得結果がMockOppへ置き換えることができる
    Id dummyId = '006000000000000';
    OppUpdater updater = new OppUpdater(dummyId, MockRepo);
    Opportunity UpdatedOpp = updater.execute();

    // OppUpdaterの中の更新処理の内容をAssertする
    Assert.areEqual(.......);
    Assert.areEqual(.......);
  }
}
```

# メソッド

### Queryクラス

#### source
SOQLにおける`FROM`を指定します。
```apex
(new Query()).source(Opportunity.getSObjectType());
```

#### pick
SOQLにおける`SELECT`を指定します。
```apex
List<String> fields = new List<String>{Name, CloseDate};
(new Query()).pick('Id').pick(fields);
```

#### condition
SOQLにおける`WHERE`を指定します。
orConditionの場合、OR条件を追加できます。
```apex
(new Query()).source(Opportunity.getSObjectType()).pick('Id').condition('Name', '=', 'test');
// SELECT Id FROM Opportunity WHERE Name = 'test'

List<Id> oppIds = new List<Id>{'006000000000000', '006000000000001'};
(new Query()).source(Opportunity.getSObjectType()).pick('Id').condition('Id', 'IN', oppIds);
// SELECT Id FROM Opportunity WHERE Id IN (006000000000000, 006000000000001) 


(new Query())
    .source(Opportunity.getSObjectType())
    .pick('Id')
    .condition('Name', '=', 'test')
    .condition('Id', 'IN', (new Query())
        .condition('CloseDate', '>=', Date.newInstance(2024, 1, 1) 
        .condition('CloseDate', '<=', Date.newInstance(2024, 12, 31) 
    );
// SELECT Id FROM Opportunity WHERE Name = 'test' AND (CloseDate >= 2024-01-01 AND CloseDate <= 2024-12-31)
```

#### join
サブクエリを使用した、別テーブルの条件での絞り込みを追加できます。
```apex
(new Query())
    .source(Opportunity.getSObjectType())
    .pick('Id')
    .condition('Name', '=', 'test')
    .join('AccountId', 'IN', (new Query())
        .source(Account.getSObjectType())
        .pick('Id')
        .condition('Name', '=', 'testAccount')
    );
// SELECT Id FROM Opportunity WHERE Name = 'test' AND AccountId IN (SELECT Id FROM Account WHERE Name = 'testAccount')
```

# レシピ
## SELECT * をしたい 
pickAllを使用します
```apex
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pickAll()
      .find(oppId)
```

## 特定条件でwhere句を追加したい

queryにあるメソッドを使うことで柔軟にクエリを組み立てることができます
```apex
// 取引先が持つ商談一覧を取得する条件
Query query = (new Query())
    .source(Opportunity.getSObjectType())
    .pickAll()
    .condition('AccountId', '=', account.Id);

// もし取引先の種別が顧客直接取引の場合、商談の種別に「新規顧客」の条件を追加
if(Account.Type == 'Customer - Direct') {
    query.condition('Type', '=', 'New Customer');
}

// 商談取得
List<Opportunity> opps = (List<Opportunity>) (new Repository()).get(query);
```

## SELECTやWHEREが多い
フォーマッタを使えば縦に並んでくれるので見やすくなります
```apex
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick('hoge')
      .pick('huga')
      ..
      ..
      ..
      .condition('A', '=', 1)
      .condition('B', '=', 2)
      ..
      ..
      ..
```
SELECTは配列で渡すこともできます
```apex
    List<String> selectFields = new List<String>{'hoge', 'fuga', .......};
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pick(selectFields)
      .condition('A', '=', 1)
      .condition('B', '=', 2)
      ..
      ..
      ..
```


