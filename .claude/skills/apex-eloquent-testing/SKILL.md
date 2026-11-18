---
name: apex-eloquent-testing
description: Apex unit tests for code that queries and saves through ApexEloquent, using MockEloquent and MockEntry instead of inserted records. Use when writing or fixing @IsTest classes in a project that contains Scribe.cls, including MockEloquent attach / label / upsertedRecordsAt / upsertedEntriesAt / deletedCountAt, scribeAt / scribesAt / lastScribe with assertCondition / assertNoCondition / assertConditionAt / hasCondition / assertOrderBy / assertLimit / assertAllRows, InConditionClause / EqualConditionClause / LikeConditionClause.contains, failOnGet / failOnDoUpdate / failOnFirstOrFail with whenLabel and repeat ("the failure can never fire"), failSave / failSaveWhen / failSaveByExternalId for partial success, building MockEntry rows, errors such as "has no attached entries", "ApexEloquentException is reserved", "Unknown query path" or "Unknown field in expected condition", and writing test descriptions in the project's language. Not for editing ApexEloquent's own tests.
---

# ApexEloquent: Testing with MockEloquent

`MockEloquent` implements `IEloquent` without a database. Reads return the entries a test attached, and DML records what was saved. Inject it through the constructor of the code under test (see `apex-eloquent-dml`). For building rows, see `apex-eloquent-entry`.

## Rules

1. Supply query results with `MockEloquent` and `MockEntry`. Insert real records only for behavior the database produces: triggers, formulas, roll-ups, sharing, validation rules.
2. `MockEloquent` doesn't evaluate WHERE, ORDER BY or LIMIT. For every query a unit runs, at least one test asserts its shape with `scribeAt(label).assertCondition(...)` or `assertNoCondition(...)`.
3. For each value the unit receives (an Id, a `Set<Id>`, a filter), decide whether it must narrow the query, and assert it: `assertCondition` when it must, `assertNoCondition` when it must not.
4. `attach`, `failOn*`, `failSave*`, `whenLabel` and `repeat` return a new `MockEloquent`. Use the return value.
5. Use the label constants of the production class (`OpportunityStageService.LBL_FETCH`). Don't retype label strings.
6. Simulate failures with the type production throws: `QueryException`, `DmlException`, `ListException`. `failOn*(new ApexEloquentException(...))` is refused.
7. Write test descriptions and assert messages in the language the project's tests already use (see "Test descriptions").

## Example

Production code: `OpportunityStageService` from the `apex-eloquent-dml` skill.

```apex
@IsTest
private class OpportunityStageServiceTest {
  @IsTest
  static void closeAsLostUpdatesStage() {
    MockEntry opportunity = MockEntry.of(Opportunity.class).alias('opp').autoId(1).set('StageName', 'Prospecting');
    Set<Id> opportunityIds = new Set<Id>{ opportunity.getAliasId('opp') };
    MockEloquent mock = (new MockEloquent())
      .attach(OpportunityStageService.LBL_FETCH, new List<IEntry>{ opportunity });

    Test.startTest();
    new OpportunityStageService(opportunityIds, mock).closeAsLost();
    Test.stopTest();

    mock.scribeAt(OpportunityStageService.LBL_FETCH)
      .assertCondition(new InConditionClause('Id', opportunityIds));
    List<SObject> saved = mock.upsertedRecordsAt(OpportunityStageService.LBL_SAVE);
    Assert.areEqual(1, saved.size(), 'Normal: one opportunity is updated.');
    Assert.areEqual('Closed Lost', ((Opportunity) saved[0]).StageName, 'Normal: the stage is Closed Lost.');
  }

  @IsTest
  static void closeAsLostWithNoRowsSavesNothing() {
    MockEloquent mock = (new MockEloquent())
      .attach(OpportunityStageService.LBL_FETCH, new List<IEntry>());

    new OpportunityStageService(new Set<Id>(), mock).closeAsLost();

    Assert.isTrue(mock.upsertedRecordsAt(OpportunityStageService.LBL_SAVE).isEmpty(), 'Edge: nothing is saved when no row matches.');
  }
}
```

## Supplying query results

| Setup | Who sees it |
|---|---|
| `new MockEloquent(entry)` / `new MockEloquent(List<IEntry>)` | every read without a label |
| `.attach(label, entry)` / `.attach(label, List<IEntry>)` | reads with that label. A second `attach` to the same label replaces the first |
| `.attach(label, new List<IEntry>())` | the zero-row path of that label |

- A read with a label that has nothing attached throws "has no attached entries" and lists the attached labels. Attach an empty list to test the zero-row path.
- `get` returns every attached entry. `first` and `firstOrFail` return the first. `firstOrFail` throws `ApexEloquentException` when nothing is attached.
- The mock builds the query before returning rows. A misspelled field or a refused query shape fails in the unit test just as in production.
- Returned `MockEntry` rows get the query's SELECT applied. Reading a field the query doesn't select throws "not selected in Scribe".
- `rawSoql` rows skip that check, because a raw string has no `Scribe`.
- Labels are strict in the mock too: once the code calls `label()`, each operation needs its own label (see `apex-eloquent-dml`).

## Checking what was saved

| Spy | Returns |
|---|---|
| `upsertedRecordsAt(label)` | `List<SObject>` inserted, updated or upserted under the label |
| `upsertedEntriesAt(label)` | the same, as `List<IEntry>` |
| `deletedCountAt(label)` | `Integer` |
| `scribeAt(label)` | the `Scribe` run under the label, `null` if none ran, throws if several ran |
| `scribesAt(label)` | every `Scribe` run under the label, in order |
| `lastScribe()` | the last `Scribe` run, whatever its label |

- Without labels, the spies use the label `'default'`: `upsertedRecordsAt('default')`.
- Inserted records get generated Ids. The mock rejects what the platform rejects: insert with an Id or update without an Id (`DmlException`), delete without an Id (`ListException`), a `null` list element (`ApexEloquentException`).
- `userMode()` and `systemMode()` do nothing in the mock. It doesn't simulate field-level security, validation rules, required fields, triggers or limits.
- Use `Assert.isNull(mock.scribeAt(label))` to prove a branch skips a query.

## Asserting the query shape

```apex
Scribe query = mock.scribeAt(OpportunityStageService.LBL_FETCH);
query
  .assertCondition(new InConditionClause('Id', opportunityIds))
  .assertNoCondition(new EqualConditionClause('IsClosed', true))
  .assertOrderBy(new List<String>{ 'CloseDate DESC' })
  .assertLimit(50);
```

| Assertion (on `Scribe`) | Checks |
|---|---|
| `assertCondition(clause)` / `assertNoCondition(clause)` | the queried object's conditions, including `whereGroup`. A clause built with an object class (`new EqualConditionClause(Account.class, 'Type', 'Partner')`) searches that object anywhere: parent condition, child subquery, semi-join |
| `assertConditionAt(path, clause)` / `assertNoConditionAt(path, clause)` | the part of the query at `path` |
| `hasCondition(clause)` / `hasConditionAt(path, clause)` | the same as a `Boolean` |
| `assertOrderBy(List<String>)` / `assertOrderByAt(path, ...)` | the whole ORDER BY in order, items like `'CreatedDate DESC'` or `'Name ASC NULLS LAST'`. An empty list means no ORDER BY |
| `assertLimit(n)` / `assertNoLimit()` (+ `...At(path, ...)`) | the LIMIT |
| `assertAllRows()` / `assertNoAllRows()` | ALL ROWS on the outer query |

Expected conditions use the test-only constructors of the condition classes: `new InConditionClause('Id', ids)`, `new NotInConditionClause(...)`, `new EqualConditionClause(...)`, `new NotEqualConditionClause(...)`, `new GreaterThanOrEqualConditionClause(...)`, `new LessThanOrEqualConditionClause(...)`, `new IsNullConditionClause('Field')`, `new LikeConditionClause(...)`, and so on. For `whereContains` / `whereStartsWith` / `whereEndsWith`, expect `LikeConditionClause.contains(field, value)` / `startsWith` / `endsWith` (`NotLikeConditionClause` for the `Not` forms). A `LikeConditionClause` with the same text does not match them.

- The assertion checks that the condition is present, not that it narrows the result. A condition joined by OR also matches. When an OR could widen the query, also forbid the widening condition with `assertNoCondition`.
- Pass the same container kind as production: a `Set` is compared sorted, a `List` in its written order.
- A misspelled field in the expected clause throws "Unknown field in expected condition". HAVING conditions are not searched.
- `whereEqual(f, null)` / `whereNotEqual(f, null)` are recorded as `IsNullConditionClause` / `IsNotNullConditionClause`. Expect `new IsNullConditionClause('Field')`, not `new EqualConditionClause('Field', null)`.
- A failed assertion is a `System.AssertException`, which Apex cannot catch. Use `hasCondition` only when you need your own message.
- Paths: a parent hop is the lookup field given to `asParent`, a child hop is its `relationName` or the child object name, a semi-join hop is the field given to `whereIn(field, Scribe)`. `whereGroup` is not a hop. Join hops with dots: `'ParentId.ParentId'`.

Read [references/query-shape-patterns.md](references/query-shape-patterns.md) for the pattern list: input Ids, both sides of `ignoreWhen`, negations, parent and child conditions, semi-joins, date ranges, and repeated labels.

## Simulating failures

```apex
MockEloquent mock = (new MockEloquent())
  .attach(OpportunityStageService.LBL_FETCH, new List<IEntry>{ opportunity })
  .failOnDoUpdate(new DmlException('Simulated failure'))
  .whenLabel(OpportunityStageService.LBL_SAVE);
try {
  new OpportunityStageService(opportunityIds, mock).closeAsLost();
  Assert.fail('Error: the failed update is expected to propagate.');
} catch (DmlException e) {
  Assert.areEqual('Simulated failure', e.getMessage(), 'Error: the platform failure reaches the caller.');
}
```

| Call | Effect |
|---|---|
| `failOnGet()`, `failOnFirst()`, `failOnRawSoql()`, `failOnGetAsSObject()`, `failOnFirstAsSObject()` | the next matching read throws `QueryException` |
| `failOnDoInsert()`, `failOnDoUpdate()`, `failOnDoUpsert()`, `failOnDoUpsertByExternalId()`, `failOnDoDelete()` | the next matching DML throws `DmlException` |
| `failOnFirstOrFail()`, `failOnFirstOrFailAsSObject()` | throws `ApexEloquentException`, as when no row is found |
| `failOnXxx(e)` | throws `e` as is. `ApexEloquentException` and `null` are refused |
| `.whenLabel(label)` | scopes the last `failOn*` to calls with that label. Without it, a `failOn*` targets only unlabeled calls; once the code uses `label()`, it throws "the failure can never fire". `'default'` is refused |
| `.repeat()` | the last `failOn*` fires on every call instead of once |

- Each `failOn*` fires once. Two registered for the same method and label fire on its first two matching calls, in order.
- To guard a call that must never happen, pass an exception class defined in the test.
- A `DmlException` built in Apex has no row details. Calling `getNumDml()`, `getDmlType(i)` or `getDmlMessage(i)` on it throws an uncatchable `System.UnexpectedException`. Test code that reads them against real DML.

### Partial success

| Call | Fails the row |
|---|---|
| `failSave(recordId, message)` | with that Id. Pair with `MockEntry.autoId` |
| `failSaveWhen(Contact.LastName, value, message)` | whose field (a `Schema.SObjectField` token) equals the value, compared with `==`. Use it for new rows without an Id |
| `failSaveByExternalId(value, message)` | with that external Id value, in `doUpsertByExternalId` |

- With `allOrNone = false`, the row's result has `isSuccess() == false` and your message, and the row is not recorded by the spies.
- With `allOrNone = true`, or on an overload without `allOrNone`, the whole call throws `DmlException` and nothing is recorded.
- Failed results carry a fixed status code, so code that branches on `getStatusCode()` cannot be tested against the mock.

## Test descriptions

Write test descriptions, comments and assert messages in the language the project's existing tests use. If the project labels test cases, keep its labels and put them first:

| Language | Labels |
|---|---|
| Japanese | `正常系:` / `異常系:` / `エッジケース:` |
| English | `Normal:` / `Error:` / `Edge:` |

Follow the project's own naming for test classes and methods. If the project has no tests yet, ask which language to use.

## Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Test is green although the query ignores its input | The mock returns attached rows whatever the WHERE says | Add `scribeAt(label).assertCondition(new InConditionClause('Id', ids))` |
| "label 'x' has no attached entries" | The test attached nothing for that label | Attach the rows, or `attach(label, new List<IEntry>())` for zero rows |
| Attached data or failure is ignored | `attach` / `failOn*` result was discarded | Chain on `new MockEloquent()` and keep the returned instance |
| "ApexEloquentException is reserved..." | `failOn*(new ApexEloquentException(...))` | Pass `QueryException`, `DmlException` or `ListException` |
| `scribeAt` throws "Ambiguous query lookup" | Several reads ran under one label, or a failed read was retried | Use `scribesAt(label)` |
| `assertCondition` fails although the condition is there | `Set` versus `List`, or a different value type | Use the same container and types as production |
| `whereContains` condition doesn't match `new LikeConditionClause(...)` | They are different kinds | `LikeConditionClause.contains(field, value)` |
| "Unknown query path" | Wrong hop name, or a parent loaded only with `parentField` | Use the hop names listed in the error; `parentField` alone is not a searchable place |
| `ignoreWhen` branch fails only in production | Only the withdrawn side was tested, so its field name was never checked | Test both sides of every `ignoreWhen` |
| "...the failure can never fire" from a `failOn*` | `failOn*` without `whenLabel` while the code uses labels | Add `.whenLabel(ProductionClass.LBL_X)` |
| `failSave` registered but the call succeeds | The row has another Id, or it's a new row without Id | Use the row's Id, or `failSaveWhen` |
| Test expects success but gets `DmlException` from `failSave` | The code calls an overload without `allOrNone` | Expect the exception, or call the `allOrNone = false` overload |
| `System.UnexpectedException` from `getNumDml()` | Row details on a mocked `DmlException` | Read `getMessage()`, or test with real DML |
