---
paths: ["**/*.cls", "**/*.trigger"]
---

# ApexEloquent

This project reads and writes Salesforce data through ApexEloquent (`Scribe.cls`, `IEloquent`, `IEntry`).

- Build queries with `Scribe.of(<Object>.class)` and run them through an injected `IEloquent` (`get`, `first`, `firstOrFail`). Write DML with `IEloquent.doInsert / doUpdate / doUpsert / doDelete`. Don't write `[SELECT ...]`, `Database.query()`, or raw `insert` / `update` / `delete` statements in code that ApexEloquent can serve.
- Keep records as `IEntry` (`get`, `put`, `getParent`, `getChildren`). Use `getAsSObject`, `firstAsSObject` and `firstOrFailAsSObject` only when a platform API requires an `SObject`.
- Pass a `Set` or `List` straight to `whereIn` / `whereNotIn`. Don't copy a `Set` into a new `List` first.
- Assign each `Scribe` to a local variable, then pass the variable to `IEloquent`. Don't build the query inline in the `get(...)` call.
- `Scribe` methods, the `MockEntry` and `MockEloquent` builder methods, and `IEloquent.userMode()` / `systemMode()` return new instances. Always use the return value.
- Platform failures arrive as platform types: catch `DmlException`, `ListException` and `QueryException`. `ApexEloquentException` means a usage error, a query that cannot be built, or `firstOrFail(scribe)` finding no row.
- For every query a unit runs through `MockEloquent`, at least one unit test asserts its shape with `scribeAt(label).assertCondition(...)` or `assertNoCondition(...)`.
- Write test descriptions and assert messages in the language the project's tests already use, and keep its case labels (for example `正常系:` / `異常系:` / `エッジケース:`, or `Normal:` / `Error:` / `Edge:`).
- Before writing code, load the matching skill: `apex-eloquent-query` for queries, `apex-eloquent-dml` for DML, access mode and injecting `IEloquent`, `apex-eloquent-entry` for reading and writing `IEntry` values, `apex-eloquent-testing` for unit tests with `MockEloquent` and `MockEntry`.

These rules don't apply to ApexEloquent's own source and tests (`Scribe.cls`, `Eloquents/`, `Entries/`, `ConditionClauses/`, `AggregateClauses/` and their test classes).
