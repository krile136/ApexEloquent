# ApexEloquent: Shapes Refused at Build Time

Scribe checks a query when it is built: when `Eloquent` or `MockEloquent` runs it, or when you call `toDisplay()` or `toBoundQuery()`. Every refusal is an `ApexEloquentException`. Because `MockEloquent` builds the query too, a unit test that reaches the query sees the same error.

Some checks run earlier, when you chain the call. They are marked "chain".

## Fields

| Shape | Error | Fix |
|---|---|---|
| `field('Nmae')`, `field('Account.Name')` | Field Selection Failed | Fix the name. Select parent fields with `parentField(Scribe.asParent('AccountId').field('Name'))` |
| `whereEqual('Nmae', ...)` | Condition Field Failed | Fix the name |
| `whereEqual('Account.Type', ...)` | Condition Field Failed | `parentCondition(Scribe.asParent('AccountId').whereEqual('Type', ...))` |
| `asParent('Account')` (relationship name instead of lookup field) | The specified relation ID field does not exist in the object's fields | Pass the lookup field: `asParent('AccountId')` |
| `asParent` on a polymorphic lookup (`WhatId`, `WhoId`, an `OwnerId` a queue can own), for fields or conditions | Polymorphic relation IDs (pointing to multiple SObject types) are not supported yet | Not supported. Query the Ids first and filter on the lookup field |
| `orderBy('Nmae')` on a plain query | Order By Field Failed | Fix the name. A dotted parent path (`Account.Name`) is not checked |
| Period method on a field that is not Date or Datetime | A DateLiteral (...) was compared with `...`, which is not a Date or Datetime field | Use a Date or Datetime field |

A condition withdrawn by `ignoreWhen(true)` is not built, so its field is not checked.

## Conditions

| Shape | Error | Fix |
|---|---|---|
| `null` value for `whereGreaterThan`, `whereIn`, `whereLike`, `whereContains`, a period method, ... | refused at build | Withdraw it with `.ignoreWhen(value == null)`, or pass a value |
| A condition after an OR without `.orCondition()` (chain) | Illegal Logical Transition | Add `.orCondition()` before every condition on an OR level |
| `orCondition()` followed by `withChildren`, `parentField` or `parentCondition` (chain) | Incomplete Logical Expression | Follow `orCondition()` with a `where...()` or `whereGroup(...)` |
| AND and OR on the same level | Mixed AND and OR at the same level | Put one side in `whereGroup(Scribe.asGroup()...)` |
| `ignoreWhen` first, after `orderBy`, or twice in a row (chain) | Invalid ignoreWhen() placement | Chain it directly after the condition |
| Semi-join after `orCondition()` (chain), or on a level joined by OR | SOQL Semi-Join Restriction | Keep the semi-join at the top level with AND, or pass a `Set<Id>` |
| Semi-join inside `whereGroup` | SOQL Semi-Join Restriction | Query the Ids first and pass the `Set<Id>` |
| Semi-join inside `parentCondition` | SOQL Semi-Join Restriction | Put the semi-join on the lookup field of the queried object (`whereIn('AccountId', subQuery)`), or pass a `Set<Id>` |
| `allRows()` on a semi-join subquery (chain) | ALL ROWS in a subquery | Put `allRows()` on the outer query |
| Empty `whereNotIn` in a HAVING group joined by OR | Empty NOT IN under OR | Check the list before building, and leave out that HAVING part when it is empty |

## Relationships

| Shape | Error | Fix |
|---|---|---|
| `parentField` / `parentCondition` with a `Scribe` not made by `asParent` (chain) | Invalid Scribe Context | Use `Scribe.asParent('LookupField')` |
| `withChildren` with a `Scribe` not made by `asChild` (chain) | Invalid Scribe Context | Use `Scribe.asChild(Contact.class)` |
| `orderBy`, `take`, `offset`, `forUpdate` or `allRows` on an `asParent` Scribe (chain) | Not allowed on a parent | Order by the parent's path on the outer query (`orderBy('Account.Name')`). Put `forUpdate()` on the outer query |
| `forUpdate` or `allRows` on an `asThrough` Scribe (chain) | Not allowed on asThrough() | Put them on the outer query |
| `forUpdate` on a child subquery | FOR UPDATE in a subquery | Put it on the outer query |
| `allRows` on a child subquery | ALL ROWS in a subquery | Put it on the outer query |
| Child name that matches several relationships | Ambiguous Relationship | Add `.relationName('ExactRelationshipName')` to the child Scribe, and use the same name in `getChildren` |

`orderBy`, `take` and `offset` on an `asThrough` Scribe apply to the junction subquery.

## Aggregates

| Shape | Error | Fix |
|---|---|---|
| Aggregate function or `groupByField` together with `withChildren` (chain) | SOQL Aggregate Restriction | Run two queries |
| Aggregate function inside `asChild` or `asHaving` (chain) | Contextual Violation: Aggregate Function Forbidden | Add it to the outer Scribe |
| `havingCondition` without a GROUP BY (chain) | Missing Required Clause: GROUP BY | Add `groupByField(...)` first |
| Two aggregates with the same alias | Duplicate Alias Error | Give each one its own alias |
| `orderBy` a field that is neither grouped nor aggregated | Ordered field must be grouped or aggregated | Order by a grouped field, an expression such as `COUNT(Id)`, or an alias |

## Order, limit and locking

| Shape | Error | Fix |
|---|---|---|
| `orderBy('Name, Id')`, `orderBy('Name DESC')` (chain) | The field for orderBy() is not a single field path | One column per call, direction as the second argument |
| Third `orderBy` argument other than `'FIRST'` / `'LAST'` (chain) | Invalid nulls operator for orderBy() | `orderBy('Name', 'ASC', 'LAST')` |
| `forUpdate()` with `orderBy` | Order By Conflict | Remove one of them |
| `forUpdate()` with `offset` | Offset Conflict | Remove one of them |
| `allRows()` with `forUpdate()` | ALL ROWS Conflict | Remove one of them |
| `take(-1)`, `offset(-1)`, `offset(2001)` (chain) | refused | `take(n >= 0)`, `0 <= offset <= 2000` |

## Values that cannot be one SOQL token

A value compared with a number, currency, Boolean, date, datetime or time field is checked in its unquoted SOQL form. It must be a single token (`100`, `'100'`, `'LAST_N_DAYS:30'`). Anything else, such as a String carrying `0 OR Id != null`, or text longer than 1,000 characters, is refused when the query is built. The check stops added syntax, not a different valid value: `'null'` still passes. Convert input to the field's real type (`Integer.valueOf`, `Date.valueOf`) before passing it.
