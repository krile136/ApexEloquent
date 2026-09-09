# ApexEloquent
**An Apex ORM Framework for Test-Driven Development (TDD).**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Salesforce Deployable](https://img.shields.io/badge/Salesforce-Deployable-brightgreen)](https://github.com/krile16/ApexEloquent)

Verbose SOQL strings, the complexity of relationship queries, and slow, brittle, database-dependent tests... These are common challenges faced by many Salesforce developers.

`ApexEloquent` was born to solve these challenges. Inspired by Laravel Eloquent, this framework aims to make data access in Apex safer, more intuitive, and above all, **testable**.

## ✨ Core Features

* **Intuitive & Safe Query Construction:**
    Say goodbye to SOQL string concatenation. With the fluent interface of `Scribe`, you can build queries as if you were writing a sentence. Paired with formatters like Prettier, even complex queries become incredibly readable and maintainable.

* **Effortless Relationship Handling:**
    When fetching relationships, you no longer need to specify object names with `__r` or look up relationship API names that differ from the field's API name. You can easily access them using the parent's ID field name or the child's object name. Furthermore, the `through()` method allows you to handle many-to-many relationships elegantly.

* **True, Database-Free Unit Testing:**
    With `MockEloquent` and `MockEntry`, you can write blazing-fast, reliable unit tests without any DML or SOQL dependencies. It supports "select-forgotten" detection and full mocking of non-writable fields, providing powerful support for Test-Driven Development (TDD).

* **Elegant Advanced Aggregate Queries:**
    Simply describe complex analytical queries, including `GROUP BY` and `HAVING` clauses. Features like specifying `HAVING` conditions by alias dramatically improve development productivity.

---
## 🚀 Quick Start

Add `ApexEloquent` to your project using `git submodule`.
```bash
$ cd force-app/main/default/classes
$ git submodule add https://github.com/krile16/ApexEloquent.git ApexEloquent
```
One Command Deployment!
A `Makefile` is provided, so you can deploy all necessary classes to your org with a single command.
```bash
$ make install 
```

## Features & Usage Examples
The basic flow is to build a query with `Scribe` and execute it with `Eloquent`.

### **Basic Conditional Queries**
```apex
// 1. Arrange (Build the query with Scribe)
// Find Opportunities in specific stages with an Amount over 100,000
List<String> targetStages = new List<String>{ 'Prospecting', 'Qualification' };
Scribe scribe = Scribe.source(Opportunity.getSObjectType())
    .fields(new List<String>{'Id', 'Name', 'Amount'})
    .whereIn('StageName', targetStages)
    .whereGreaterThan('Amount', 100000)
    .orderBy('Amount', 'DESC');

// 2. Act (Execute the query with Eloquent)
// The get() method returns a List<IEntry>
List<IEntry> opps = (new Eloquent()).get(scribe);

// 3. Utilize (Access values from the Entry)
for (IEntry opp : opps) {
    Id oppId = opp.getId();
    String oppName = opp.getName();
    Decimal amount = (Decimal)opp.get('Amount');
    System.debug('Name: ' + oppName + ', Amount: ' + amount);
}
```
### Fetching Parent Relationships (`parentField`)
```Apex
// 1. Arrange: Get an Opportunity's Name and its parent Account's Name
Scribe scribe = Scribe.source(Opportunity.getSObjectType())
    .field('Name')
    .parentField(Scribe.asParent('AccountId').field('Name'))
    .whereEqual('Id', someOppId);

// 2. Act: Fetch a single record
IEntry opp = (new Eloquent()).first(scribe);

// 3. Utilize: Access the parent Entry's values
if (opp != null) {
    String oppName = opp.getName();
    IEntry parentAccount = opp.getParent('AccountId');
    String accountName = (parentAccount != null) ? parentAccount.getName() : 'N/A';
    
    System.debug('Opportunity Name: ' + oppName + ', Account Name: ' + accountName);
}
```
### Fetching Child Relationships (`withChildren`)
```Apex
// 1. Arrange: Get an Account and all its related Contacts (Name and Email)
Scribe scribe = Scribe.source(Account.getSObjectType())
    .field('Name')
    .withChildren(
        Scribe.asChild(Contact.getSObjectType())
            .fields(new List<String>{'LastName', 'Email'})
    )
    .whereEqual('Id', someAccountId);

// 2. Act: Fetch a single record
IEntry account = (new Eloquent()).first(scribe);

// 3. Utilize: Access the list of child Entries
if (account != null) {
    System.debug('Account Name: ' + account.getName());
    List<IEntry> contacts = account.getChildren('Contact');
    for (IEntry contact : contacts) {
        String lastName = (String)contact.get('LastName');
        String email = (String)contact.get('Email');
        System.debug('-- Contact: ' + lastName + ', Email: ' + email);
    }
}
```

### Fetching Many-to-Many Relationships (through)
```Apex
// 1. Arrange (Build the many-to-many query with Scribe)
// Get the Name and ProductCode of active Products related to a specific Order
// through the OrderItem junction object.
Scribe scribe = Scribe.source(Order.getSObjectType())
    .field('Id')
    .through(
        Scribe.asThrough(OrderItem.getSObjectType(), 'Product2Id')
            .fields(new List<String>{'Name', 'ProductCode'})
            .whereEqual('IsActive', true)
    )
    .whereEqual('Id', someOrderId);

// 2. Act (Execute the query with Eloquent)
IEntry order = (new Eloquent()).first(scribe);

// 3. Utilize (Access the related list with getThrough)
if (order != null) {
    // The first argument of getThrough is the junction object name,
    // and the second is the related key field name.
    List<IEntry> products = order.getThrough('OrderItem', 'Product2Id');
    for (IEntry product : products) {
        String name = product.getName();
        String code = (String)product.get('ProductCode');
        System.debug('Related Product: ' + name + ', Code: ' + code);
    }
}
```

### Aggregate Queries
```Apex
// 1. Arrange: Calculate the average Amount per Stage, filtered for averages over 50,000
Scribe scribe = Scribe.source(Opportunity.getSObjectType())
    .field('StageName')
    .average('Amount', 'avgAmount')
    .groupByField('StageName')
    .havingCondition(
        Scribe.asHaving().whereGreaterThan('avgAmount', 50000)
    );

// 2. Act: Execute the aggregate query
List<IEntry> results = (new Eloquent()).getAggregate(scribe);

// 3. Utilize: Access values from the aggregate result Entry
for (IEntry result : results) {
    String stage = (String)result.get('StageName');
    Decimal avg = (Decimal)result.get('avgAmount');
    System.debug('Stage: ' + stage + ', Average Amount: ' + avg);
}
```

## 🛡️Liberation from the Database: True Unit Testing
The true power of `ApexEloquent` lies in its testability.

Scenario: Test a service method, `AccountService.updateAccountType`, which updates an Opportunity's parent Account `Type` to 'Customer' if the Opportunity stage is 'Closed Won'.

### 
Before: Traditional Testing
```Apex
// Must prepare and insert test data into the database
Account testAcc = new Account(Name='Test', Type='Prospect');
insert testAcc;
Opportunity testOpp = new Opportunity(
    Name='Test Opp', StageName='Closed Won', CloseDate=Date.today(), AccountId=testAcc.Id
);
insert testOpp;

// Execute the test
Test.startTest();
Account updatedAccount = AccountService.updateAccountType(testOpp.Id);
Test.stopTest();

// Assert the result
Assert.areEqual('Customer', updatedAccount.Type);
```
This test is slow and can be affected by other automation (validation rules, triggers).

### After: ApexEloquent
```Apex
// Set up the expected query result in memory with MockEloquent
IEloquent mockEloquent = new MockEloquent(
    new MockEntry(
        new Opportunity(Id = '...', StageName = 'Closed Won'),
        new Map<String, Object>{
            'AccountId' => new MockEntry(new Account(Id = '...', Type = 'Prospect'))
        }
    )
);

// Test the service class directly, with no database access
AccountService service = new AccountService(mockEloquent);
Account updatedAccount = service.updateAccountType('...');

// Assert the value of the object updated in memory
Assert.areEqual('Customer', updatedAccount.Type);
```
With `MockEloquent`, tests are blazing-fast and achieve true, reliable unit testing by being completely isolated from other automation.

## 📖 Learn More
This is just a glimpse of what `ApexEloquent` can do.

For a complete API reference, advanced use cases, and the design philosophy behind this framework, please visit the official documentation site.
[KrileWorks.com](https://krileworks.com/)

## Asserting the query a Usecase built

`MockEloquent` returns the entries a test attached, so a query that forgot to narrow by its
input still comes back with exactly the right data — and the test goes green while production
touches every matching record in the org. These two APIs close that gap: the mock records the
queries it was handed, and a `Scribe` can be asked whether it carries a condition.

```apex
MockEloquent mock = (new MockEloquent()).attach('fetch', contacts);
new UpdateAccountFromContact(contactIds, mock).invoke();

mock.scribeAt('fetch')
  .assertCondition(new InConditionClause('Id', contactIds))     // narrowed by the given Ids
  .assertCondition(new EqualConditionClause('IsVerified__c', true));
```

The expected condition is an ordinary condition clause, so the field, the operator and the
value are all fixed at once, and both sides are compared as SOQL built from the same metadata —
no string matching against `toSoql()`. Values passed as a `Set` are order-independent.

| Recording (on `MockEloquent`) | |
|---|---|
| `scribeAt(label)` | the query run under that label, or `null`; throws if several ran |
| `scribesAt(label)` | every query under that label, in execution order |
| `lastScribe()` | the most recent query, whatever label it ran under |

| Asserting (on `Scribe`) | |
|---|---|
| `assertCondition(clause)` / `assertNoCondition(clause)` | the queried object's conditions, including those inside `whereGroup` |
| `assertConditionAt(path, clause)` / `assertNoConditionAt(path, clause)` | a named place in the query (see below) |
| `hasCondition(clause)` / `hasConditionAt(path, clause)` | the same checks as a `Boolean`, for custom messages |

A condition clause built with an SObject class targets that object anywhere in the query — a
`parentCondition` or a `withChildren` subquery:

```apex
scribe.assertCondition(new EqualConditionClause(Account.class, 'Type', 'Partner'));
```

When that is not enough to say *which* one — a self-referencing parent, or two subqueries over
the same object — the assertion refuses to guess: it throws and lists the paths to choose from.
A path is the chain of hops from the queried object, written as the query was built (a parent
hop is the field given to `Scribe.asParent(...)`; a child hop is its `relationName(...)` when set,
otherwise the child object's name; a semi-join hop is the field given to
`whereIn(field, Scribe)` / `whereNotIn(field, Scribe)`; `whereGroup` is not a hop):

```apex
scribe.assertConditionAt('ParentId.ParentId', new EqualConditionClause('Type', 'X'));
scribe.assertConditionAt('Contacts', new EqualConditionClause('LastName', 'Y'));
```

What is verified is that the query *carries* the condition, not that the condition narrows it:
a clause joined by `orCondition()` matches too, even though the `OR` may widen the query back
out. When that matters, name the widening condition and forbid it — which also says in the test
what the query is not allowed to do:

```apex
scribe
  .assertCondition(new InConditionClause('Id', contactIds))
  .assertNoCondition(new EqualConditionClause('Archived__c', false));
```

A misspelled field is refused rather than treated as a condition that is simply absent —
otherwise `assertNoCondition` would pass for ever, including after the code under test started
filtering on the field the test meant to guard.

These assertion methods are `@TestVisible`, so they stay out of the production API and out of
autocomplete — this section is where to find them. `HAVING` conditions are never searched: their
field name is an aggregate alias, not a field — passing one as an expectation is refused as a
field the object does not have.

Those three kinds of hop share one namespace, so a path can reach two places at once. Both are
searched, and the expectation is read against whichever of them has the field it names; add the
object to the expected condition when that is not enough to say which one is meant.

## License

ApexEloquent is licensed under the Apache License 2.0. A copy of the license is available in the repository's LICENSE file. 

