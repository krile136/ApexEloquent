---
name: apex-eloquent-query
description: Apex query building with the ApexEloquent Scribe builder, run through IEloquent. Use when writing, changing or reviewing any SOQL in Apex in a project that contains Scribe.cls, including replacing [SELECT ...] or Database.query, Scribe.of / field / fields / allFields, whereEqual / whereIn / whereNotIn / whereLike / whereContains / whereStartsWith / whereEndsWith, optional filters with ignoreWhen, orCondition and whereGroup, DateLiteral with whereWithin / whereBefore / whereAfter / whereSince / whereUntil, parentField / parentCondition / withChildren / through / relationName, semi-joins (whereIn with a Scribe), count / sum / average / min / max / countDistinct / groupByField / havingCondition, orderBy / take / offset / forUpdate / allRows, toBoundQuery for batch start(), toDisplay for logs, get / first / firstOrFail, and errors such as "Condition Field Failed", "Field Selection Failed", "Mixed AND and OR at the same level", "Illegal Logical Transition", "Invalid ignoreWhen() placement" or "SOQL Semi-Join Restriction". Not for editing ApexEloquent's own source.
---

# ApexEloquent: Query Builder

A query is a `Scribe` chain that starts at `Scribe.of(<Object>.class)`. The `Scribe` only describes the query. An `IEloquent` (`Eloquent` in production, `MockEloquent` in tests) runs it and returns `IEntry` rows.

## Rules

1. Don't write `[SELECT ...]` or `Database.query()` where a `Scribe` can express the query.
2. Every `Scribe` method returns a new `Scribe`. When you add conditions in branches, reassign: `query = query.whereEqual(...)`. A call whose result is discarded does nothing.
3. Assign the finished `Scribe` to a local variable and pass the variable to `IEloquent`. Don't build it inline inside `get(...)`.
4. Field names are strings. They are checked against the object's describe when the query is built. There is no dotted field syntax: reach a parent with `Scribe.asParent(...)`.
5. Pass a `Set` or `List` straight to `whereIn` / `whereNotIn`. Don't copy it into another collection first.
6. For an optional filter, chain `.ignoreWhen(<value is empty>)` directly after the `where...()` call. Don't wrap the query in `if` branches.
7. For text a user typed, use `whereContains` / `whereStartsWith` / `whereEndsWith`. Use `whereLike` only for a pattern you wrote yourself.
8. For date literals, use `DateLiteral` with the period methods (`whereWithin`, `whereSince`, ...). Don't put a range literal behind `>` or `<`.
9. Read results as `IEntry` (`get`, `first`, `firstOrFail`). For field access on the rows, use the `apex-eloquent-entry` skill.

```apex
Scribe accountQuery = Scribe.of(Account.class)
  .field('Id')
  .field('Name')
  .whereIn('OwnerId', ownerIds)
  .whereEqual('Industry', industry).ignoreWhen(String.isBlank(industry))
  .whereContains('Name', keyword).ignoreWhen(String.isBlank(keyword))
  .orderBy('Name')
  .take(100);
List<IEntry> accounts = this.eloquent.label(LBL_ACCOUNTS).get(accountQuery);
```

## SELECT

| Need | Call |
|---|---|
| One field | `.field('Name')` |
| Several fields | `.fields(new List<String>{ 'Id', 'Name', 'Industry' })` |
| Every field of the object | `.allFields()` |
| Parent fields | `.parentField(Scribe.asParent('AccountId').field('Name').field('Industry'))` |
| Child subquery | `.withChildren(Scribe.asChild(Contact.class).field('Id').field('LastName'))` |
| Many-to-many through a junction | `.through(Scribe.asThrough(OpportunityLineItem.class, 'Product2Id').field('Name'))` |

- An unknown field fails with `ApexEloquentException` ("Field Selection Failed") when the query is built.
- `asParent(...)` takes the lookup field (`'AccountId'`), not the relationship name (`'Account'`).

## WHERE

| Method | SOQL |
|---|---|
| `whereEqual(f, v)` / `whereNotEqual(f, v)` | `=` / `!=`. A `null` value gives `= null` / `!= null` |
| `whereGreaterThan` / `whereGreaterThanOrEqual` / `whereLessThan` / `whereLessThanOrEqual` | `>` `>=` `<` `<=` |
| `whereNull(f)` / `whereNotNull(f)` | `= null` / `!= null` |
| `whereIn(f, values)` / `whereNotIn(f, values)` | `IN` / `NOT IN`. `values` is any `Set` or `List` of primitives |
| `whereIn(f, scribe)` / `whereNotIn(f, scribe)` | semi-join / anti-join |
| `whereContains` / `whereStartsWith` / `whereEndsWith` (+ `whereNot...`) | `LIKE`, with `%`, `_` and `\` in the value matched as plain characters |
| `whereLike(f, pattern)` / `whereNotLike` | `LIKE`. `%` and `_` in the value are always wildcards |
| `whereIncludes(f, values)` / `whereExcludes(f, values)` | multi-select picklist `INCLUDES` / `EXCLUDES` |

- Values are bound when `Eloquent` runs the query. You don't escape or quote them.
- An empty `whereIn` renders `Id = null` and matches no row. An empty `whereNotIn` renders `Id != null` and matches every row. If "empty" should mean "no filter", add `.ignoreWhen(values.isEmpty())`.
- A `null` value for a method that cannot take one (`whereGreaterThan`, `whereIn`, `whereContains`, ...) fails when the query is built, not when you chain it. A following `.ignoreWhen(true)` can still withdraw it.

### Optional conditions: ignoreWhen

`ignoreWhen(true)` removes the condition added by the call right before it. After `whereGroup(...)` it removes the whole group.

- It must follow a `where...()`, `whereGroup(...)` or `parentCondition(...)` call directly. Anywhere else (first in the chain, after `orderBy`, twice in a row) it throws "Invalid ignoreWhen() placement".
- A withdrawn condition is not built, so its field name is not checked. Test both branches (see `apex-eloquent-testing`).

### AND, OR and groups

```apex
.whereEqual('Type', 'Partner').whereEqual('Industry', 'Retail')      // A AND B (default)
.whereEqual('Type', 'Partner').orCondition().whereEqual('Type', 'Customer')   // A OR B
.whereEqual('Industry', 'Retail')
  .whereGroup(Scribe.asGroup()
    .whereEqual('Type', 'Partner')
    .orCondition()
    .whereEqual('Type', 'Customer'))                                 // A AND (B OR C)
```

- Once a level has an OR, every later condition on that level needs its own `.orCondition()` in front. Otherwise the chain throws "Illegal Logical Transition".
- AND and OR on the same level fail at build time with "Mixed AND and OR at the same level". Put one side in `whereGroup(Scribe.asGroup()...)`.
- `orCondition()` before any condition is a no-op. So `whereIn('A', a).ignoreWhen(a.isEmpty()).orCondition().whereIn('B', b).ignoreWhen(b.isEmpty())` works whichever side is empty.

### Parent conditions

```apex
Scribe contactQuery = Scribe.of(Contact.class)
  .field('Id')
  .parentCondition(Scribe.asParent('AccountId').whereEqual('Industry', 'Retail'));
```

`whereEqual('Account.Industry', ...)` fails with "Condition Field Failed". `asParent` refuses a polymorphic lookup (`WhatId`, `WhoId`, or an `OwnerId` a queue can own), for fields and conditions alike.

### Semi-joins

```apex
Scribe partnerAccounts = Scribe.of(Account.class).field('Id').whereEqual('Type', 'Partner');
Scribe contactQuery = Scribe.of(Contact.class).field('Id').whereIn('AccountId', partnerAccounts);
```

SOQL rejects a semi-join inside `whereGroup`, on a level joined by OR, and inside a parent condition. Scribe refuses these when the query is built. Query the Ids first and pass the `Set<Id>` instead.

## Date literals

```apex
Scribe opportunityQuery = Scribe.of(Opportunity.class)
  .field('Id')
  .whereWithin('CloseDate', DateLiteral.current().fiscalQuarter())   // = THIS_FISCAL_QUARTER
  .whereSince('CreatedDate', DateLiteral.last(30).days());          // >= LAST_N_DAYS:30
```

| Method | SOQL | Rows |
|---|---|---|
| `whereWithin(f, p)` | `=` | inside the period |
| `whereNotWithin(f, p)` | `!=` | outside it, including rows where the field is null |
| `whereBefore(f, p)` | `<` | before the period starts |
| `whereAfter(f, p)` | `>` | after the period ends |
| `whereSince(f, p)` | `>=` | from the start of the period on |
| `whereUntil(f, p)` | `<=` | up to the end of the period |
| `whereWithinAny(f, List<DateLiteral>)` | `IN` | in any of the periods. An empty list matches no row |

- Building a literal: `DateLiteral.today()` / `yesterday()` / `tomorrow()`; `last()`, `current()`, `next()` with a singular unit (`day`, `week`, `month`, `quarter`, `year`, `fiscalQuarter`, `fiscalYear`); `last(n)`, `next(n)`, `ago(n)` with a plural unit (`days`, ..., `fiscalYears`). `last(3).month()` does not compile.
- `LAST_N_DAYS:n` includes today, so `last(1).days()` is yesterday and today.
- Period methods accept only Date and Datetime fields. A `null` period fails when the query is built.

## ORDER BY, LIMIT, OFFSET, locking

| Call | Notes |
|---|---|
| `.orderBy('Name')` / `.orderBy('Name', 'DESC')` / `.orderBy('Name', 'DESC', 'LAST')` | One column per call. The third argument is only `'FIRST'` or `'LAST'` |
| `.orderBy('Account.Name')` | The one place a dotted parent path is allowed |
| `.take(n)` | `LIMIT n`. `take(0)` returns no rows |
| `.offset(n)` | at most 2000 |
| `.forUpdate()` | outer query only. Refused together with `orderBy` or `offset` |
| `.allRows()` | also returns deleted rows and archived activities. Outer query only, not with `forUpdate()`. Add `.whereEqual('IsDeleted', false)` to keep only archived rows |

`orderBy('Name, Id')` is refused. Call `orderBy` once per column. `asParent(...)` refuses `orderBy`, `take`, `offset`, `forUpdate` and `allRows`; order by the parent's path on the outer query instead.

## Aggregates

```apex
Scribe countQuery = Scribe.of(Contact.class)
  .field('AccountId')
  .count('Id', 'contactCount')
  .whereIn('AccountId', accountIds)
  .groupByField('AccountId')
  .havingCondition(Scribe.asHaving().whereGreaterThan('contactCount', 1));
for (IEntry row : this.eloquent.label(LBL_COUNTS).get(countQuery)) {
  Id accountId = (Id) row.get('AccountId');
  Integer contactCount = ((Decimal) row.get('contactCount')).intValue();
}
```

- Functions: `count`, `countDistinct`, `sum`, `average`, `min`, `max`. Each takes `(field, alias)`, and the alias is required.
- Group with `groupByField(f)`, `groupByFields(list)` or `groupByParent(Scribe.asParent('AccountId').groupByField('Name'))`. Select a grouped field with `field(...)` to read it from the row.
- `havingCondition(...)` needs a GROUP BY. Conditions in `Scribe.asHaving()` name aggregate aliases.
- Aggregates and `withChildren` cannot be combined in one query.
- In an aggregate query, `orderBy` accepts a grouped field, an expression such as `COUNT(Id)`, or an alias of this query. Anything else is refused at build time.
- `get`, `first` and `firstOrFail` recognize aggregate queries. Read the values by alias from the `IEntry`.

## Running the query

| Call | 0 rows | Notes |
|---|---|---|
| `get(scribe)` | empty list | `List<IEntry>` |
| `first(scribe)` | `null` | adds no LIMIT. Add `.take(1)` if more rows can match |
| `firstOrFail(scribe)` | `ApexEloquentException` | |
| `firstOrFail(scribe, e)` | throws `e` as is | for your own business exception |
| `rawSoql(soql)` | empty list | only for queries Scribe cannot express. Never concatenate user input into it |

Queries run in user mode by default. For `systemMode()`, labels and injection, use the `apex-eloquent-dml` skill.

## Running a Scribe yourself

`Eloquent` runs every query with bound values. To run a `Scribe` yourself, such as in a batch `start()`, use `toBoundQuery()`:

```apex
public Database.QueryLocator start(Database.BatchableContext context) {
  SoqlBinds.BoundQuery query = scopeQuery().toBoundQuery();
  return Database.getQueryLocatorWithBinds(query.soql, query.binds, AccessLevel.SYSTEM_MODE);
}
```

- Choose the `AccessLevel` on purpose. `USER_MODE` enforces field-level security and sharing, even in a `without sharing` class, so a batch can read fewer rows without any error.
- `toDisplay()` returns the query with the values written in. Use it for logs and messages, never for running: the escapes of `whereContains` and similar methods only work when bound.

## Shapes refused at build time

Read [references/build-time-checks.md](references/build-time-checks.md) for the shapes Scribe refuses, with the error text and the fix for each.

## Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| Condition seems ignored, query unchanged | A `Scribe` method result was discarded | Chain the calls, or reassign: `query = query.whereEqual(...)` |
| "Condition Field Failed" with a dotted name | `whereEqual('Account.Type', ...)` | `parentCondition(Scribe.asParent('AccountId').whereEqual('Type', ...))` |
| "Field Selection Failed" | Misspelled field, or a dotted parent field in `field(...)` | Fix the name, or use `parentField(Scribe.asParent(...))` |
| A search for `100%` also returns `1000` | User input passed to `whereLike` | Use `whereContains` / `whereStartsWith` / `whereEndsWith` |
| `CloseDate > LAST_N_DAYS:30` returns only future rows | A range literal behind `>` | `whereSince('CloseDate', DateLiteral.last(30).days())` |
| Empty input returns no rows, but "all rows" was intended | Empty `whereIn` matches nothing | Add `.ignoreWhen(ids.isEmpty())` |
| "Illegal Logical Transition" | A condition after an OR without `.orCondition()` | Add `.orCondition()`, or group with `whereGroup` |
| "Mixed AND and OR at the same level" | `A AND B OR C` on one level | Put the OR side in `whereGroup(Scribe.asGroup()...)` |
| "Invalid ignoreWhen() placement" | `ignoreWhen` not directly after a condition | Move it right after the `where...()` call |
| `orderBy('Name, Id')` throws | Several columns in one string | Call `orderBy` once per column |
| `orderBy(..., 'NULLS LAST')` throws | The nulls argument takes only `'FIRST'` / `'LAST'` | `orderBy('Name', 'ASC', 'LAST')` |
| `first()` reads many rows | `first()` adds no LIMIT | Add `.take(1)` |
| Batch reads fewer rows after moving to `toBoundQuery()` | `AccessLevel.USER_MODE` applies sharing and FLS | Pass the level the batch needs, for example `SYSTEM_MODE` |
| Aggregate query fails with "Ordered field must be grouped or aggregated" | `orderBy` on a field that is neither grouped nor aggregated | Order by a grouped field, `COUNT(Id)`, or the alias |
