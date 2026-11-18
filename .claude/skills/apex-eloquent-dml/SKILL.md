---
name: apex-eloquent-dml
description: Apex DML and data-access wiring with ApexEloquent's IEloquent (Eloquent in production, MockEloquent in tests). Use when inserting, updating, upserting or deleting records in a project that contains Scribe.cls, including replacing insert / update / upsert / delete statements or Database.insert / Database.update, choosing between doInsert / doUpdate / doUpsert / doDelete / doUpsertByExternalId overloads (SObject, List<SObject>, IEntry, List<IEntry>, allOrNone), reading SaveResult / UpsertResult / DeleteResult, userMode() / systemMode() and sharing, label() and its strict mode ("Strict mode is active", "already consumed"), catching DmlException / ListException / QueryException versus ApexEloquentException, firstOrFail with a business exception, or injecting IEloquent through a constructor. Not for editing ApexEloquent's own source.
---

# ApexEloquent: DML, Access Mode and Injection

`IEloquent` runs every query and every DML. Production code holds an `IEloquent`, creates `new Eloquent()` by default, and lets a test pass a `MockEloquent` instead. This skill covers the DML methods, access mode, labels and the exception rule.

## Rules

1. Don't write `insert`, `update`, `upsert`, `delete` or `Database.insert(...)` in code that holds an `IEloquent`. Call `doInsert`, `doUpdate`, `doUpsert`, `doUpsertByExternalId` or `doDelete`.
2. Depend on `IEloquent`, not on `Eloquent`. Accept it through a constructor and fall back to `new Eloquent()` when it is `null`.
3. Records that came from a query stay `IEntry`. Change them with `put()` and pass the same entries to `doUpdate` / `doUpsert`. Don't rebuild an `SObject` with only the Id.
4. Use the list overloads for more than one record. Never call DML inside a loop.
5. Catch platform failures as their platform types: `DmlException`, `ListException`, `QueryException`. Don't catch `ApexEloquentException` to handle a failed save.
6. Queries and DML run in user mode by default. Call `systemMode()` only where the process must ignore the running user's field and object permissions, and always use its return value.
7. When you use `label()`, give each operation on that instance its own label.

## Injecting IEloquent

```apex
public with sharing class OpportunityStageService {
  @TestVisible
  private static final String LBL_FETCH = 'fetch';
  @TestVisible
  private static final String LBL_SAVE = 'save';

  private final Set<Id> opportunityIds;
  private final IEloquent eloquent;

  public OpportunityStageService(Set<Id> opportunityIds) {
    this(opportunityIds, null);
  }

  @TestVisible
  private OpportunityStageService(Set<Id> opportunityIds, IEloquent eloquent) {
    this.opportunityIds = opportunityIds;
    this.eloquent = eloquent ?? new Eloquent();
  }

  public void closeAsLost() {
    Scribe opportunityQuery = Scribe.of(Opportunity.class)
      .field('Id')
      .field('StageName')
      .whereIn('Id', this.opportunityIds);
    List<IEntry> opportunities = this.eloquent.label(LBL_FETCH).get(opportunityQuery);
    for (IEntry opportunity : opportunities) {
      opportunity.put('StageName', 'Closed Lost');
    }
    this.eloquent.label(LBL_SAVE).doUpdate(opportunities);
  }
}
```

- When this class hands records to another class, pass `this.eloquent` along with them. The collaborator then runs on the same mock in a test, and reading a field the first query did not select fails there instead of in production.
- `MockEloquent` is a test class. Production code that creates one compiles, but fails at run time with `System.TypeException: Cannot call test methods in non-test context`.

## DML overloads

`doInsert`, `doUpdate`, `doUpsert` and `doDelete` each have eight forms:

| Input | No `allOrNone` (throws on failure) | With `allOrNone` |
|---|---|---|
| `SObject` | `doInsert` / `doUpdate` / `doUpsert` return `SObject`; `doDelete` returns nothing | `Database.SaveResult` / `UpsertResult` / `DeleteResult` |
| `List<SObject>` | `List<SObject>` (delete: nothing) | `List<Database.SaveResult>` / ... |
| `IEntry` | `IEntry` (delete: nothing) | `Database.SaveResult` / ... |
| `List<IEntry>` | `List<IEntry>` (delete: nothing) | `List<Database.SaveResult>` / ... |

`doUpsertByExternalId(records, externalIdField, allOrNone)` takes an `SObject`, `List<SObject>`, `IEntry` or `List<IEntry>`, a `Schema.SObjectField` token for the key, and always requires `allOrNone`.

```apex
// New records built in place: SObject is enough
List<Contact> contacts = new List<Contact>{ new Contact(LastName = 'Smith', AccountId = accountId) };
List<Database.SaveResult> results = this.eloquent.label(LBL_INSERT).doInsert(contacts, false);
for (Integer i = 0; i < results.size(); i++) {
  if (!results[i].isSuccess()) {
    // results[i] belongs to contacts[i]
  }
}

// A new record that shared logic handles as IEntry
IEntry draft = new Entry(new Contact(LastName = 'Jones', AccountId = accountId));
IEntry inserted = this.eloquent.label(LBL_INSERT_ONE).doInsert(draft);
Id newId = inserted.getId();   // draft.getId() is still null
```

- Results come back in input order: `results[i]` belongs to `records[i]`.
- The `IEntry` overloads don't write the new Id back into the entry you passed. Read it from the returned entry or result.
- `allOrNone` must not be `null`.
- A `null` element in a list fails the whole call with `ApexEloquentException`, before any row is sent.
- In a list that mixes object types, keep records of the same type together. The platform starts a new chunk at each type switch and fails above 10 chunks. `MockEloquent` does not check this.
- `doUpsertByExternalId` refuses a field that is neither an External Id nor an indexed lookup field (`isExternalId()` / `isIdLookup()`).
- `rawSoql(soql)` runs a SOQL string with the same access level. Use it only when `Scribe` cannot express the query, and never put user input into the string.

## Exceptions

| What happened | Type you catch |
|---|---|
| A row was rejected (validation rule, required field, row lock, insert with an Id, update without an Id) | `DmlException` |
| The whole list was rejected before any row (delete without an Id, even with `allOrNone = false`) | `ListException` |
| A query failed (unknown column, no access) | `QueryException` |
| Usage error: `null` argument, `null` list element, a query Scribe cannot build, an unusable upsert key | `ApexEloquentException` |
| `firstOrFail(scribe)` found no row | `ApexEloquentException` |

`MockEloquent` follows the same split, so a `catch (DmlException e)` exercised by a unit test is the catch production reaches.

To turn "no row" into your own exception, pass it to `firstOrFail`:

```apex
Scribe accountQuery = Scribe.of(Account.class).field('Id').field('Name').whereEqual('Id', accountId);
IEntry account = this.eloquent.label(LBL_ACCOUNT)
  .firstOrFail(accountQuery, new AuraHandledException('The account no longer exists.'));
```

The message of `firstOrFail(scribe)` does not contain the query, so field names and filter values are not shown to users. The query still appears in the debug log.

## Access mode and sharing

| Call | Field and object permissions | Record sharing |
|---|---|---|
| none (default) | enforced (`USER_MODE`) | enforced for the running user, also in a `without sharing` class |
| `.userMode()` | enforced | enforced for the running user, also in a `without sharing` class |
| `.systemMode()` | not enforced (`SYSTEM_MODE`) | from the calling class |

- `Eloquent` is `inherited sharing`. To bypass sharing, call `systemMode()` from a `without sharing` class. `systemMode()` alone does not bypass sharing, and `without sharing` alone does not either, because user mode enforces sharing.
- `userMode()` and `systemMode()` return a copy. The instance you call them on keeps its mode. `this.eloquent.systemMode();` as a statement changes nothing.
- A label set just before the switch carries over: `this.eloquent.label(LBL_SAVE).systemMode().doUpdate(entries)` works.
- In `MockEloquent` both are no-ops that return the same mock, so tests don't depend on the mode.

```apex
public without sharing class AccountRollupJob {
  // ... constructor injection as above ...

  // Must update every record, whoever started the job
  private void save(List<IEntry> entries) {
    this.eloquent.systemMode().label(LBL_SAVE).doUpdate(entries);
  }
}
```

## Labels

`label(name)` tags the next operation. It routes reads and spies in `MockEloquent` (see `apex-eloquent-testing`), and it is checked the same way in production:

- After the first `label()` call, the instance is in strict mode. Every later operation needs a label, or it throws "Strict mode is active".
- A label allows one successful operation per instance. Using it again throws "already consumed". Use a different label for each operation, for example one constant per query and per DML.
- A failed operation releases its label, so a retry can use the same label.
- An instance that never calls `label()` accepts any number of unlabeled operations.
- `label(null)` and `label('')` throw.

## Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| `catch (ApexEloquentException e)` never runs on a failed save | Save failures arrive as `DmlException` / `ListException` | Catch the platform type |
| Update runs with FLS enforced although `systemMode()` was called | `systemMode()` called as a statement, result discarded | Chain on the result: `this.eloquent.systemMode().doUpdate(...)` |
| A `without sharing` class still reads only the records the user can see | User mode (the default) enforces sharing | Also call `systemMode()` |
| Records hidden by sharing still not visible in system mode | `systemMode()` doesn't change sharing | Make the calling class `without sharing` |
| "Strict mode is active on this IEloquent" | An operation without `label()` after another one used a label | Label every operation on that instance |
| "Label 'x' was already consumed" | Same label used twice on one instance, often inside a loop | One label per operation, and no DML or query inside loops |
| Id is `null` on the entry passed to `doInsert(IEntry)` | The input entry is not modified | Read the Id from the returned `IEntry` or `SaveResult` |
| A value written to the `SObject` from `getRecord()` is not saved | `getRecord()` returns a copy | Change values with `put()` on the entry |
| "Invalid field for upsert" from `doUpsertByExternalId` | The field is not an External Id or indexed lookup field | Pass a field that is |
| `System.TypeException: Cannot call test methods in non-test context` | Production code creates `MockEloquent` | Use `new Eloquent()` in production; pass the mock from the test |
| More than 10 chunks error on a mixed-type list | Types alternate in the list | Group records by type before the DML |
