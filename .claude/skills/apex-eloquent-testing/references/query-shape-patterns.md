# ApexEloquent: Query Shape Patterns

`MockEloquent` returns what the test attached, whatever the query says. These patterns pin the parts of a query that a mocked test cannot see otherwise. Get the query with `mock.scribeAt(label)` (or `scribesAt(label)` when a label ran several times).

## Contents
- Input Ids
- Both sides of ignoreWhen
- A condition withdrawn in the middle of a chain
- Negations
- Parent conditions
- Two places with the same object
- Child subqueries and semi-joins
- parentField is not a condition
- Date ranges and date literals
- Widening OR conditions
- Order and limit
- Repeated labels

## Input Ids

The first assertion of a query-running unit is almost always this one:

```apex
mock.scribeAt(LBL_FETCH).assertCondition(new InConditionClause('Id', contactIds));
```

When a received value must not filter the query, say so:

```apex
mock.scribeAt(LBL_FETCH).assertNoCondition(new InConditionClause('OwnerId', ownerIds));
```

## Both sides of ignoreWhen

Write one test per side. An empty collection is a valid expectation, because `ignoreWhen` removes the whole condition:

```apex
// Empty input: the condition is gone
mock.scribeAt(LBL_FETCH).assertNoCondition(new InConditionClause('Id', new Set<Id>()));
// Non-empty input: the condition is there
mock.scribeAt(LBL_FETCH).assertCondition(new InConditionClause('Id', accountIds));
```

A withdrawn condition is never built, so a misspelled field in it is only caught by the test that keeps it.

## A condition withdrawn in the middle of a chain

For `where(A).where(B).ignoreWhen(true).where(C)`, check all three in one test:

```apex
// production: .whereEqual('Type', 'Partner').whereIn('OwnerId', ownerIds).ignoreWhen(ownerIds.isEmpty()).whereEqual('Industry', 'Retail')
query
  .assertCondition(new EqualConditionClause('Type', 'Partner'))
  .assertNoCondition(new InConditionClause('OwnerId', new Set<Id>()))
  .assertCondition(new EqualConditionClause('Industry', 'Retail'));
```

## Negations

The kind of condition is part of the match, so a swapped `whereIn` / `whereNotIn` or `whereNull` / `whereNotNull` fails:

```apex
query
  .assertCondition(new NotInConditionClause('Id', excludedIds))
  .assertNoCondition(new InConditionClause('Id', excludedIds));
```

## Parent conditions

Name the parent object, and the assertion finds the parent condition:

```apex
// production: .parentCondition(Scribe.asParent('AccountId').whereEqual('Type', 'Partner'))
query.assertCondition(new EqualConditionClause(Account.class, 'Type', 'Partner'));
```

## Two places with the same object

A self-referencing parent, or two subqueries over one object, makes the object name ambiguous. The assertion throws and lists the paths. Name the path:

```apex
// production: Scribe.of(Account.class).parentCondition(Scribe.asParent('ParentId')...)
query
  .assertConditionAt('ParentId', new EqualConditionClause('Type', 'Partner'))
  .assertConditionAt('ParentId.ParentId', new EqualConditionClause('Type', 'Customer'));
```

## Child subqueries and semi-joins

```apex
// production: .withChildren(Scribe.asChild(Contact.class).field('Id').whereEqual('Title', 'CEO'))
query.assertConditionAt('Contact', new EqualConditionClause('Title', 'CEO'));

// production: .whereIn('AccountId', Scribe.of(Account.class).field('Id').whereEqual('Industry', 'Retail'))
query.assertConditionAt('AccountId', new EqualConditionClause('Industry', 'Retail'));
```

The child hop is the `relationName(...)` when the query sets one, otherwise the child object name. The semi-join hop is the field passed to `whereIn` / `whereNotIn`.

## parentField is not a condition

`parentField` only selects fields. A parent reached only through `parentField` is not a place the assertions search, so `assertConditionAt('AccountId', ...)` throws "Unknown query path". To prove the query does not filter on the parent:

```apex
query.assertNoCondition(new EqualConditionClause(Account.class, 'Type', 'Partner'));
```

## Date ranges and date literals

Pin both ends of a range:

```apex
query
  .assertCondition(new GreaterThanOrEqualConditionClause('CloseDate', rangeStart))
  .assertCondition(new LessThanOrEqualConditionClause('CloseDate', rangeEnd));
```

`whereWithin(f, p)` is an equality on the literal:

```apex
query.assertCondition(new EqualConditionClause('CloseDate', DateLiteral.current().fiscalQuarter()));
```

## Widening OR conditions

The assertions check that a condition is present, not that the result is narrowed. A condition joined by OR can bring every row back. Forbid the widening condition by name:

```apex
query
  .assertCondition(new InConditionClause('Id', opportunityIds))
  .assertNoCondition(new EqualConditionClause('IsClosed', false));
```

## Order and limit

`MockEloquent` neither sorts nor cuts rows:

```apex
// production: .orderBy('CreatedDate', 'DESC').take(50)
query.assertOrderBy(new List<String>{ 'CreatedDate DESC' }).assertLimit(50);
// child subquery order
query.assertOrderByAt('Contact', new List<String>{ 'LastName ASC NULLS LAST' });
// production: .allRows()
query.assertAllRows();
```

## Repeated labels

When the same label runs more than once, or a failed read was retried, `scribeAt` throws. Use `scribesAt`:

```apex
List<Scribe> issued = mock.scribesAt(LBL_MEMBERS);
Assert.areEqual(2, issued.size(), 'Normal: the members are read twice.');
issued[0].assertCondition(new InConditionClause('AccountId', accountIds));
```

`scribesAt` records a query when it is issued. A read that then fails (`firstOrFail` finding nothing) is recorded. A read stopped by `failOnGet` before it is issued is not.
