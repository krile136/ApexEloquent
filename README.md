# What is Apex Eloquent 

Apex Eloquent is a framework that enables database operations in Apex similar to Laravel's Eloquent.
This brings the following advantages:

- **Improved readability**: No need to construct SOQL queries as strings, enhancing readability.

- **Dynamic query generation**: Allows flexible addition of conditions.

- **Better testability**: Adopting the repository pattern reduces database dependency during testing.

- **Improved type safety**: Enables IDE autocomplete for variables.

# Issues with Database Operations in Apex

### Writing Queries in Apex

#### 1. Constructing SOQL as a String and Executing It
```apex
String soql = 'SELECT ID, Name FROM Opportunity WHERE ID = :oppId AND .......';
Opportunity opp = Database.query(soql);
```

#### 2. Directly Writing the Query
```apex
Opportunity opp = [SELECT ID, Name From Opportunity WHERE ID = :oppId AND .......];
```

### Problems with These Query Methods
1. When constructing queries as strings, formatting cannot be applied, making long queries difficult to read.
1. If you want to add conditions dynamically:
    1. When using strings, you need to manipulate the string, making it hard to generalize and cumbersome to modify conditions.
    1. When writing queries directly, this is not possible.
1. Writing queries as strings does not allow IDE autocomplete for variables.
1. In both methods, variables cannot be used in the SELECT clause.
1. Writing test classes always requires database dependencies, meaning test data must be inserted.
    1. As the number of test target classes increases, test execution time becomes longer.

Apex Eloquent solves all these issues.


# Demo

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

# Installation 

Use `git submodule` to add Apex Eloquent to your Salesforce project.

Test classes are written to meet the 75% code coverage requirement using standard fields of standard objects, so deployment should work without modifications. However, if tests fail, please maintain the test classes accordingly.

# Usage

## Existing Implementation

Consider the following class that retrieves and updates an Opportunity record:
```apex
public with sharing class OppUpdater {
  private final Id oppId;

  public OppUpdater(Id oppId) {
    this.oppId = oppId;
  }

  public Opportunity execute(){
    Opportunity opp = [SELECT ID, ....... FROM Opportunity WHERE ID = :this.oppId];

    // Some update processing 

    update opp;
    
    return opp;
  }
}
```

## Converting to the Apex Eloquent Pattern

When converted to the Apex Eloquent Pattern, the implementation looks like this:
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

## Writting Test Class

By Using `RepositoryInterface`, you can verify the logic without interacting with the database.
```apex
@isTest(seeAllData=false)
public with sharing class OppUpdater_T {
  public static testMethod void testUpdate() {
    // Prepare a mock Opportunity and mock repository
    Opportunity mockOpp = new Opportunity();
    MockRepository mockRepo = new MockRepository(mockOpp);

    // By injecting the mock repository into OppUpdater’s constructor,
    // the retrieved Opportunity in the execute method is replaced with mockOpp
    Id dummyId = '006000000000000';
    OppUpdater updater = new OppUpdater(dummyId, MockRepo);
    Opportunity UpdatedOpp = updater.execute();

    // Assert the update processing logic inside OppUpdater
    Assert.areEqual(.......);
    Assert.areEqual(.......);
  }
}
```

# Methods

## Query Class

### **source**

Specify the `FROM` clause in SOQL.
```apex
(new Query()).source(Opportunity.getSObjectType());
```

### pick

Specify the `SELECT` clause in SOQL.
```apex
List<String> fields = new List<String>{Name, CloseDate};
(new Query()).pick('Id').pick(fields);
```

### condition

Specify the `WHERE` clause in SOQL
In the case of orCondition, you can add OR conditions.
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

### join

You can add filtering conditions for another table using subqueries.
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

### orderBy

Specify the `ORDER BY` clause in SOQL

```apex
(new Query())
    .source(Opportunity.getSObjectType())
    .pick('Id')
    .orderBy('CloseDate');
// SELECT Id FROM Opportunity ORDER BY ASC 
```

You can fully configure ORDER BY by passing up to three arguments.
```apex
(new Query())
    .source(Opportunity.getSObjectType())
    .pick('Id')
    .orderBy('CloseDate', 'DESC', 'LAST');
// SELECT Id FROM Opportunity ORDER BY DESC NULLS LAST
```

### restrict

Specify the `LIMIT` clause in SOQL
```apex
(new Query())
    .source(Opportunity.getSObjectType())
    .pick('Id')
    .restrict(20);
// SELECT Id FROM Opportunity LIMIT 20
```

## Repository Class

By passing the Query class, you can retrieve data, and by passing SObject to methods such as doInsert, you can insert data into the database.

### get

Executes SOQL and retrieves the results.
The return value is `List<SObject>`, so cast it to the appropriate object type.
If the number of retrieved records is 0, an empty array is returned.
```apex
List<Opportunity> opps = (List<Opportunity>) (new Repository()).get(query);
```

### getOrFail

Executes SOQL and retrieves the results.
The return value is `List<SObject>`, so cast it to the appropriate object type.
If the number of retrieved records is 0, an error is thrown.
```apex
try {
    List<Opportunity> opps = (List<Opportunity>) (new Repository()).getOrFail(query);
} catch(Exception e){
    // handling error
}
```

### first

Executes SOQL and returns the first record from the results.
If the number of retrieved records is 0, `null` is returned.
```apex
Opportunity opp = (Opportunity) (new Repository()).first(query);
```

### firstOrFail

Executes SOQL and returns the first record from the results.
If the number of retrieved records is 0, an error is thrown.
```apex
try { 
    Opportunity opp = (Opportunity) (new Repository()).first(query);
} catch(Exception e) {
    // handling error 
}
```

### doInsert

Inserts the SObject passed as an argument into the database.
The return value is the record with the ID added after insertion.
```apex
insertOpp = (new Repository()).doInsert(insertOpp);
System.debug(insertOpp.Id)  // show opp id
```
You can also insert arrays in the same way.
```apex
insertOpps = (List<Opportunity>) (new Repository()).doInsert(insertOpps);
```

### doUpdate

Updates the SObject passed as an argument.
```apex
updateOpp = (new Repository()).doUpdate(insertOpp);
```
You can also update arrays in the same way.
```apex
updateOpps = (List<Opportunity>) (new Repository()).doUpdate(updateOpps);
```

## doDelete
Deletes the SObject passed as an argument.
``` apex
(new Repository()).doDelete(deleteOpp);
```
You can also delete arrays in the same way.
```apex
(new Repository()).doDelete(deleteOpps);
```

# Recipes

## Want to do SELECT * 
Use pickAll
```apex
    Query query = (new Query())
      .source(Opportunity.getSObjectType())
      .pickAll()
      .find(oppId)
```

## Want to add a WHERE clause with specific conditions

You can flexibly build queries using methods in the query.
```apex
// Condition to get a list of opportunities owned by an account
Query query = (new Query())
    .source(Opportunity.getSObjectType())
    .pickAll()
    .condition('AccountId', '=', account.Id);

// If the account type is 'Customer - Direct', add a condition for 'New Customer' in the opportunity type
if(Account.Type == 'Customer - Direct') {
    query.condition('Type', '=', 'New Customer');
}

// Retrieve opportunities
List<Opportunity> opps = (List<Opportunity>) (new Repository()).get(query);
```

## Many SELECTs and WHEREs
Using a formatter makes it easier to read by aligning vertically.
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


