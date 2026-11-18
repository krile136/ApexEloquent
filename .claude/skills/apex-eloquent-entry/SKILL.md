---
name: apex-eloquent-entry
description: Reading and writing ApexEloquent records through IEntry, Entry and MockEntry in a project that contains Scribe.cls. Use when handling the List<IEntry> returned by IEloquent.get / first / firstOrFail, calling get / put / getId / getName / getParent / getChildren / getThrough / getRecord, wrapping Trigger.new or new records in new Entry(record), deciding between IEntry and getAsSObject / firstAsSObject, choosing set() or put() on a MockEntry, building test Ids with MockEntry.autoId / alias / getAliasId instead of hand-made Id strings, fetchedBy(scribe) or buildFieldStructure() instead of new FieldStructure(...), or fixing errors such as "The specified field is not selected in Scribe", "is not defined as a relationship in Scribe", "is not set in Scribe", "SObject row was retrieved via SOQL without querying the requested field" or a "field does not exist" error from set(). Not for editing ApexEloquent's own source.
---

# ApexEloquent: IEntry, Entry and MockEntry

`IEntry` wraps one row: an `SObject` or an `AggregateResult`. `Entry` wraps real rows in production. `MockEntry` builds rows in unit tests without DML. Code that only sees `IEntry` runs the same on both, and a read of a field the query did not select fails in the unit test instead of in production.

## Rules

1. Keep query results as `IEntry` from `get` / `first` / `firstOrFail` through to `doUpdate` / `doUpsert`. Type method parameters as `IEntry` or `List<IEntry>`, not `SObject`.
2. Use `getAsSObject`, `firstAsSObject`, `firstOrFailAsSObject` and `getRecord()` only when a platform API requires an `SObject`. A plain `SObject` returns `null` for an unselected field in a unit test, so the missing field reaches production.
3. In production code, write values with `put()`. In tests, build values with `MockEntry.set()`.
4. Never build Ids by hand (`'001' + '0'.repeat(12)`). Use `MockEntry.of(<Object>.class).autoId(n)`.
5. Never build a `FieldStructure` by hand. Use `fetchedBy(scribe)` with the production `Scribe`.
6. `MockEntry` builder methods return a new instance. Chain them or assign the result.

## Reading and writing

| Call | Returns | Notes |
|---|---|---|
| `entry.getId()` | `Id` | |
| `entry.getName()` | `String` | the `Name` field |
| `(String) entry.get('Industry')` | `Object` | cast to the field type |
| `entry.put('Industry', 'Retail')` | nothing | writes to the wrapped record |
| `entry.getParent('AccountId')` | `IEntry` or `null` | pass the lookup field. `null` when there is no parent |
| `entry.getChildren('Contact')` | `List<IEntry>` | pass the child object name or the relationship name (`'Contacts'`). Empty list when there are no children |
| `entry.getThrough('OpportunityLineItem', 'Product2Id')` | `List<IEntry>` | the records reached through a junction loaded with `through(...)` |
| `entry.getRecord()` | `SObject` | a copy. Changes to it don't reach the entry |

```apex
Scribe contactQuery = Scribe.of(Contact.class)
  .field('Id')
  .field('LastName')
  .parentField(Scribe.asParent('AccountId').field('Name'))
  .whereIn('Id', contactIds);
for (IEntry contact : this.eloquent.label(LBL_CONTACTS).get(contactQuery)) {
  IEntry account = contact.getParent('AccountId');
  String accountName = account == null ? null : account.getName();
  contact.put('Description', 'Account: ' + accountName);
}
```

- `get` and `put` check that the field exists on the object. A misspelled name throws `ApexEloquentException`.
- On an aggregate row, `get` reads a selected field or an alias. `put` and `getRecord()` throw.
- On a `MockEntry`, `getChildren` and `setChildren` need the name the query uses: the child object name, or the `relationName(...)` when the query sets one.
- If several child relationships point at the same object, `getChildren` with the object name is ambiguous. Pass the relationship name, the same one given to `relationName(...)` in the query.

## Wrapping records you already have

```apex
// before insert / before update trigger: put() writes into Trigger.new
List<IEntry> rows = new List<IEntry>();
for (Account record : (List<Account>) Trigger.new) {
  rows.add(new Entry(record));
}
new AccountDefaults(rows).apply();
```

`new Entry(record)` keeps a reference to the record, so `put()` changes the trigger record in place. A brand-new record you insert can also be wrapped this way when shared logic takes `IEntry`.

## Unselected fields

| Row source | Reading an unselected field |
|---|---|
| `Entry` from a real query | the platform throws `SObjectException` |
| `MockEntry` returned by `MockEloquent.get` / `first` | `ApexEloquentException`: "The specified field is not selected in Scribe" |
| `MockEntry` with `fetchedBy(scribe)` | same as above |
| `MockEntry` the test built and passed directly, without `fetchedBy` | `ApexEloquentException` for every field except `Id` |
| `SObject` from `getAsSObject` | `null` in unit tests; `SObjectException` in production. The test passes and production fails |

- `Id` is always readable, as in real SOQL.
- On a `MockEntry`, `getParent` on a lookup the query did not load with `parentField` throws "is not defined as a relationship in Scribe". `getChildren` on a child the query did not load throws "is not set in Scribe".
- Fix the production `Scribe`, not the test. The error names the field to add.

## set() and put() on MockEntry

| Method | Who calls it | Adds the field to the selected fields |
|---|---|---|
| `set(field, value)` | the test, while building data | no |
| `put(field, value)` | production code, on an entry it received | yes |

`set()` must not count as selecting a field. If it did, building mock data would hide every missing field in the production query. `put()` does count, so production code can read back what it wrote.

`set()` also writes fields the platform does not let you write: formula, roll-up summary and audit fields such as `CreatedDate`. A field name that does not exist on the object throws at once.

## Building MockEntry rows

```apex
MockEntry account = MockEntry.of(Account.class)
  .autoId(1)
  .set('Name', 'Acme')
  .setChildren('Contact', new List<MockEntry>{
    MockEntry.of(Contact.class).autoId(1).set('LastName', 'Smith'),
    MockEntry.of(Contact.class).autoId(2).set('LastName', 'Jones')
  });

MockEntry opportunity = MockEntry.of(Opportunity.class)
  .autoId(1)
  .set('StageName', 'Prospecting')
  .setParent('AccountId', MockEntry.of(Account.class).autoId(1).set('Industry', 'Retail'));

MockEntry noParent = MockEntry.of(Contact.class).autoId(3).setParent('AccountId', null);
```

| Method | Purpose |
|---|---|
| `MockEntry.of(Account.class)` | start a row |
| `.autoId(1)` / `.autoId('{#}')` | a valid 18-character Id with the object's key prefix |
| `.set(field, value)` / `.template(Map<String, Object>)` | field values |
| `.setParent(lookupField, parentEntry)` | parent row. `null` means "no parent" |
| `.setChildren(childNameOrRelationship, List<MockEntry>)` | child rows. Use the same name the query uses |
| `.alias('acme')` / `.getAliasId('acme')` / `.getByAlias('acme')` | name a row and find it again, also inside parents and children |
| `.times(count[, startAt[, interval]])` | `List<MockEntry>` copies with `{#}`, `{A}`, `{a}` replaced by the sequence |
| `MockEntry.asAggregateResult()` / `asAggregateResult(Map<String, Object>)` | an aggregate row read by alias |
| `.fetchedBy(scribe)` | apply the SELECT of a production `Scribe` (see below) |

Ids:

```apex
Id accountId = MockEntry.of(Account.class).autoId(1).getId();   // just an Id, no row needed
List<MockEntry> contacts = MockEntry.of(Contact.class)
  .autoId('{#}')
  .set('LastName', 'Contact {#}')
  .set('AccountId', '{#}')        // an Account Id with the same number
  .times(3);
```

- In `times()`, only `autoId('{#}')` (or `'{A}'` / `'{a}'`) numbers the row's own Id. `autoId(1).times(3)` is refused, because three rows would share one Id.
- `'{#}'` in a lookup field becomes an Id of the referenced object, so it matches `MockEntry.of(Account.class).autoId(n)`. On a polymorphic lookup (`WhatId`, `WhoId`, `Case.OwnerId`) it is refused.
- A real Id set on a lookup field is copied unchanged to every row.

## Rows injected without a query: fetchedBy

When a test hands entries straight to the code under test, they never pass through `MockEloquent.get`, so nothing applies the SELECT check. Apply it with the production `Scribe`:

```apex
// Production: one Scribe for the batch start() and for the tests
@TestVisible
private static Scribe scopeQuery() {
  return Scribe.of(Account.class).field('Id').field('Name').whereEqual('Type', 'Partner');
}

// Test
MockEntry partner = MockEntry.of(Account.class)
  .autoId(1)
  .set('Name', 'Acme')
  .fetchedBy(AccountSyncBatch.scopeQuery());
```

For a method that takes `IEntry` and has no production query, write a `Scribe` in the test that states the fields the method needs, and pass it to `fetchedBy`.

`withoutFieldValidation()` turns the unselected-field check off and `withoutSObjectFieldValidation()` turns off the field-name check in `set()`. Don't use them to make a failing test pass.

## Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Value set on a `MockEntry` is missing | `entry.set(...)` called as a statement, result discarded | Chain the calls or assign: `entry = entry.set(...)` |
| "The specified field is not selected in Scribe" | Production code reads a field its query doesn't select | Add the field to the production `Scribe` |
| Same error for a `MockEntry` the test built and passed directly | The entry has no SELECT applied | `.fetchedBy(productionScribe)` |
| "is not defined as a relationship in Scribe" from `getParent` | The query has no `parentField` for that lookup | Add `parentField(Scribe.asParent('AccountId')...)` |
| "is not set in Scribe" from `getChildren` | The query has no `withChildren` for that child | Add `withChildren(Scribe.asChild(...))` |
| Unselected field reads as `null` and nothing fails | The code moved to `SObject` with `getAsSObject` or `getRecord()` | Keep `IEntry` |
| Change on `getRecord()` result is lost | `getRecord()` returns a copy | Use `put()` |
| `NullPointerException` after `getParent` | The record has no parent, so `getParent` returned `null` | Check for `null`; test it with `setParent(field, null)` |
| Lookup values don't match any parent row | Ids built by hand, or a fixed Id copied by `times()` | Use `autoId` and `'{#}'` in the lookup |
| "field does not exist" from `set()` | Misspelled field | Fix the name |
