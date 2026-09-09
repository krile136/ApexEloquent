# ApexEloquent

**An Apex ORM Framework for Test-Driven Development (TDD).**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Salesforce Deployable](https://img.shields.io/badge/Salesforce-Deployable-brightgreen)](https://github.com/krile16/ApexEloquent)

📚 **Documentation: [krileworks.com](https://krileworks.com/apex-stem/docs/apex-eloquent-guide)** — guides, API reference, and design deep-dives all live there.
(日本語ドキュメント: [https://krileworks.com/ja/apex-stem/docs/apex-eloquent-guide](https://krileworks.com/ja/apex-stem/docs/apex-eloquent-guide))

ApexEloquent is part of [**Apex Stem**](https://krileworks.com/apex-stem), a set of independent, dependency-free Salesforce Apex frameworks.

## Installation

### A) Unlocked Package (recommended)

```bash
sf package install -p 04tgK000000KJbBQAW -o <your-org> -w 10
```

Or install from the browser:

- Production / Developer Edition: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tgK000000KJbBQAW`
- Sandbox: `https://test.salesforce.com/packaging/installPackage.apexp?p0=04tgK000000KJbBQAW`

Current version: **v3.12.0** (`04tgK000000KJbBQAW`). Install IDs for every release are listed on the [Releases](https://github.com/krile136/ApexEloquent/releases) page.

Why the package: tests inside an installed unlocked package are **excluded from `RunLocalTests`**, and its code is **excluded from your org's coverage calculation** — your deploys stay fast and unaffected by this framework's test suite.

### B) Git Submodule

```bash
git submodule add https://github.com/krile136/ApexEloquent.git force-app/main/default/classes/ApexEloquent
git submodule update --init --recursive
```

`sf project deploy start -d force-app/main/default/classes/ApexEloquent` deploys it like any source folder. A Makefile is also included for direct installs (`make install`).

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

## Field names are checked when the query is built

Both halves of a query are validated against the object's describe:

```apex
Scribe.of(Contact.class).field('LastNam')                     // rejected: SELECT
Scribe.of(Contact.class).field('Id').whereEqual('LastNam', 'x')  // rejected: WHERE
```

The `WHERE` half matters most in a unit test. `MockEloquent` returns the entries a test
attached without executing the SOQL, so before this check an unknown field simply travelled
to production — where the platform rejects it. Worse, an unknown name has no resolvable
type, so its literal was quoted: `whereGreaterThan('Amoun', 1000)` rendered
`Amoun > '1000'`, and the platform's complaint named the type rather than the typo.

**There is no dotted field syntax.** Reach a parent with `Scribe.asParent(...)` — the
nesting is what expresses the hierarchy, and the parent's own describe is what types the
literal:

```apex
// ❌ rejected. It also rendered Account.NumberOfEmployees > '100', which cannot execute
.whereGreaterThan('Account.NumberOfEmployees', 100)

// ✅ renders Account.NumberOfEmployees > 100
.parentCondition(Scribe.asParent('AccountId').whereGreaterThan('NumberOfEmployees', 100))
```

Filtering on a polymorphic parent (`Owner`, `Queue`, `What`, `Who`) is not supported, and
neither are SOQL functions in the field position (`toLabel(Status)`, `convertCurrency(...)`,
`CALENDAR_YEAR(...)`).

⚠️ **Upgrading surfaces mistakes that were never reaching production either.** A condition
whose collection was always empty renders to nothing and disappears, so a wrong field name
in it was invisible — `whereNotIn('StageName', emptySet)` on an Account built and ran
happily. The same goes for a branch a test never took. Those now fail when the query is
built. This framework's own test suite had two such queries, both filtering an object by a
field belonging to a different one; if an upgrade turns a test red here, read the field
name before reaching for the previous version.

Two things are deliberately outside the check. A condition withdrawn by `ignoreWhen(true)`
is not part of the query, so it is not examined. `ORDER BY` still accepts a relationship
path (`orderBy('Account.Name')`): SOQL has no parent-side `ORDER BY`, so that is the only
way to sort by a parent field, and it carries no literal to mistype.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
