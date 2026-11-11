/**
 * Copyright 2025 Hiroyuki Matsuoka
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Runs every condition kind in every query context against the real query engine (#121).
 *
 * Most Scribe tests compare toDisplay() with an expected string, which is only as right as the
 * author's understanding of SOQL. Here the platform's parser is the judge: each combination is
 * built and executed through Eloquent.get() (the path production takes), and must either run or
 * be refused by the framework with an ApexEloquentException. A QueryException means Scribe wrote
 * SOQL the platform rejects — a framework bug — and fails the test. Each combination also checks
 * that the bound query Eloquent runs expands to exactly what toDisplay() returns.
 *
 * Which combinations the framework refuses is written down in expectRefused(); every other
 * combination must run. Adding a kind or a context covers it in every pairing automatically.
 *
 * Not covered here: row counts (a valid query that filters on the wrong field still runs; string
 * tests cover that), and whereIncludes / whereExcludes (no standard object has a multi-select
 * picklist in every org). Data is not needed: the parser decides validity on an empty org.
 * Only standard objects and unambiguous relationships are used, so the test runs in any org.
 *
 * One test method per context keeps each under the 100-SOQL limit.
 * @directory ApexEloquent/tests
 */
@IsTest(seeAllData=false)
private class QueryMatrixTest {
  private static final List<String> WHERE_KINDS = new List<String>{
    'equal',
    'notEqual',
    'greaterThan',
    'greaterThanOrEqual',
    'lessThan',
    'lessThanOrEqual',
    'in',
    'notIn',
    'inEmpty',
    'notInEmpty',
    'inNumbers',
    'like',
    'notLike',
    'contains',
    'notStartsWith',
    'null',
    'notNull',
    'semiIn',
    'semiNotIn'
  };

  private static final List<String> HAVING_KINDS = new List<String>{
    'equal',
    'notEqual',
    'greaterThan',
    'greaterThanOrEqual',
    'lessThan',
    'lessThanOrEqual',
    'in',
    'notIn',
    'inEmpty',
    'notInEmpty',
    'null',
    'notNull'
  };

  /** The fields and values one object offers to each condition kind. */
  private class Kit {
    private final String textField;
    private final String orderedField;
    private final Object orderedValue;
    private final List<Object> orderedValues;
    private final String semiField;
    private final Scribe semiSubQuery;

    private Kit(
      String textField,
      String orderedField,
      Object orderedValue,
      List<Object> orderedValues,
      String semiField,
      Scribe semiSubQuery
    ) {
      this.textField = textField;
      this.orderedField = orderedField;
      this.orderedValue = orderedValue;
      this.orderedValues = orderedValues;
      this.semiField = semiField;
      this.semiSubQuery = semiSubQuery;
    }
  }

  private static Kit accountKit() {
    return new Kit(
      'Name',
      'NumberOfEmployees',
      10,
      new List<Object>{ 1, 2 },
      'Id',
      Scribe.of(Contact.class).field('AccountId')
    );
  }

  private static Kit contactKit() {
    return new Kit(
      'LastName',
      'Birthdate',
      Date.newInstance(2000, 1, 1),
      new List<Object>{ Date.newInstance(2000, 1, 1), Date.newInstance(2001, 1, 1) },
      'AccountId',
      Scribe.of(Account.class).field('Id')
    );
  }

  private static Kit userKit() {
    return new Kit(
      'LastName',
      'CreatedDate',
      Datetime.newInstanceGmt(2000, 1, 1),
      new List<Object>{ Datetime.newInstanceGmt(2000, 1, 1) },
      'Id',
      Scribe.of(Account.class).field('OwnerId')
    );
  }

  private static Kit productKit() {
    return new Kit(
      'Name',
      'CreatedDate',
      Datetime.newInstanceGmt(2000, 1, 1),
      new List<Object>{ Datetime.newInstanceGmt(2000, 1, 1) },
      'Id',
      Scribe.of(PricebookEntry.class).field('Product2Id')
    );
  }

  /**
   * Adds one WHERE condition of the given kind to a scribe.
   *
   * @param target The scribe to add to.
   * @param kind A WHERE_KINDS entry.
   * @param kit The object's fields and values.
   * @return The scribe with the condition.
   */
  private static Scribe withWhere(Scribe target, String kind, Kit kit) {
    switch on kind {
      when 'equal' {
        return target.whereEqual(kit.textField, 'matrix');
      }
      when 'notEqual' {
        return target.whereNotEqual(kit.textField, 'matrix');
      }
      when 'greaterThan' {
        return target.whereGreaterThan(kit.orderedField, kit.orderedValue);
      }
      when 'greaterThanOrEqual' {
        return target.whereGreaterThanOrEqual(kit.orderedField, kit.orderedValue);
      }
      when 'lessThan' {
        return target.whereLessThan(kit.orderedField, kit.orderedValue);
      }
      when 'lessThanOrEqual' {
        return target.whereLessThanOrEqual(kit.orderedField, kit.orderedValue);
      }
      when 'in' {
        return target.whereIn(kit.textField, new List<String>{ 'a', 'b' });
      }
      when 'notIn' {
        return target.whereNotIn(kit.textField, new List<String>{ 'a' });
      }
      when 'inEmpty' {
        return target.whereIn(kit.textField, new List<String>());
      }
      when 'notInEmpty' {
        return target.whereNotIn(kit.textField, new List<String>());
      }
      when 'inNumbers' {
        return target.whereIn(kit.orderedField, kit.orderedValues);
      }
      when 'like' {
        return target.whereLike(kit.textField, 'ma%');
      }
      when 'notLike' {
        return target.whereNotLike(kit.textField, 'ma%');
      }
      when 'contains' {
        return target.whereContains(kit.textField, '50%_\\');
      }
      when 'notStartsWith' {
        return target.whereNotStartsWith(kit.textField, 'a_b');
      }
      when 'null' {
        return target.whereNull(kit.textField);
      }
      when 'notNull' {
        return target.whereNotNull(kit.textField);
      }
      when 'semiIn' {
        return target.whereIn(kit.semiField, kit.semiSubQuery);
      }
      when 'semiNotIn' {
        return target.whereNotIn(kit.semiField, kit.semiSubQuery);
      }
    }
    throw new IllegalArgumentException('Unknown WHERE kind: ' + kind);
  }

  /**
   * Adds one HAVING condition of the given kind on the `cnt` alias.
   *
   * @param target The HAVING (or group) scribe to add to.
   * @param kind A HAVING_KINDS entry.
   * @return The scribe with the condition.
   */
  private static Scribe withHaving(Scribe target, String kind) {
    switch on kind {
      when 'equal' {
        return target.whereEqual('cnt', 1);
      }
      when 'notEqual' {
        return target.whereNotEqual('cnt', 1);
      }
      when 'greaterThan' {
        return target.whereGreaterThan('cnt', 1);
      }
      when 'greaterThanOrEqual' {
        return target.whereGreaterThanOrEqual('cnt', 1);
      }
      when 'lessThan' {
        return target.whereLessThan('cnt', 1);
      }
      when 'lessThanOrEqual' {
        return target.whereLessThanOrEqual('cnt', 1);
      }
      when 'in' {
        return target.whereIn('cnt', new List<Integer>{ 1, 2 });
      }
      when 'notIn' {
        return target.whereNotIn('cnt', new List<Integer>{ 1 });
      }
      when 'inEmpty' {
        return target.whereIn('cnt', new List<Integer>());
      }
      when 'notInEmpty' {
        return target.whereNotIn('cnt', new List<Integer>());
      }
      when 'null' {
        return target.whereNull('cnt');
      }
      when 'notNull' {
        return target.whereNotNull('cnt');
      }
    }
    throw new IllegalArgumentException('Unknown HAVING kind: ' + kind);
  }

  /**
   * Builds the query for one context and one condition kind. Building happens here, inside the
   * caller's try, because the framework refuses some shapes as soon as they are chained.
   *
   * @param context The context name.
   * @param kind The condition kind.
   * @return The scribe to execute.
   */
  private static Scribe build(String context, String kind) {
    switch on context {
      when 'root' {
        return withWhere(Scribe.of(Account.class).field('Id'), kind, accountKit());
      }
      when 'rootAfterOr' {
        return withWhere(
          Scribe.of(Account.class).field('Id').whereEqual('Name', 'x').orCondition(),
          kind,
          accountKit()
        );
      }
      when 'rootBeforeOr' {
        return withWhere(Scribe.of(Account.class).field('Id'), kind, accountKit())
          .orCondition()
          .whereEqual('Name', 'x');
      }
      when 'parent' {
        return Scribe.of(Contact.class)
          .field('Id')
          .parentCondition(withWhere(Scribe.asParent('AccountId'), kind, accountKit()));
      }
      when 'parentAfterOr' {
        return Scribe.of(Contact.class)
          .field('Id')
          .whereEqual('LastName', 'x')
          .parentCondition(withWhere(Scribe.asParent('AccountId').orCondition(), kind, accountKit()));
      }
      when 'nestedParent' {
        return Scribe.of(Contact.class)
          .field('Id')
          .parentCondition(
            Scribe.asParent('AccountId').parentCondition(withWhere(Scribe.asParent('OwnerId'), kind, userKit()))
          );
      }
      when 'child' {
        return Scribe.of(Account.class)
          .field('Id')
          .withChildren(withWhere(Scribe.asChild(Contact.class).field('Id'), kind, contactKit()));
      }
      when 'groupUnderAnd' {
        return Scribe.of(Account.class)
          .field('Id')
          .whereEqual('Name', 'x')
          .whereGroup(withWhere(Scribe.asGroup(), kind, accountKit()).whereNotEqual('Name', 'y'));
      }
      when 'groupUnderOr' {
        return Scribe.of(Account.class)
          .field('Id')
          .whereEqual('Name', 'x')
          .orCondition()
          .whereGroup(withWhere(Scribe.asGroup(), kind, accountKit()).whereNotEqual('Name', 'y'));
      }
      when 'groupInParent' {
        return Scribe.of(Contact.class)
          .field('Id')
          .parentCondition(
            Scribe.asParent('AccountId')
              .whereGroup(withWhere(Scribe.asGroup(), kind, accountKit()).orCondition().whereEqual('Name', 'y'))
          );
      }
      when 'through' {
        return Scribe.of(Order.class)
          .field('Id')
          .through(withWhere(Scribe.asThrough(OrderItem.class, 'Product2Id').field('Name'), kind, productKit()));
      }
      when 'having' {
        return aggregate().havingCondition(withHaving(Scribe.asHaving(), kind));
      }
      when 'havingAfterOr' {
        return aggregate().havingCondition(withHaving(Scribe.asHaving().whereGreaterThan('cnt', 0).orCondition(), kind));
      }
      when 'havingGroupUnderOr' {
        return aggregate()
          .havingCondition(
            Scribe.asHaving().whereGreaterThan('cnt', 0).orCondition().whereGroup(withHaving(Scribe.asGroup(), kind))
          );
      }
    }
    throw new IllegalArgumentException('Unknown context: ' + context);
  }

  private static Scribe aggregate() {
    return Scribe.of(Account.class).field('Industry').count('Id', 'cnt').groupByField('Industry');
  }

  /**
   * The combinations the framework refuses on purpose, each for a reason SOQL gives. Every
   * other combination must run.
   *
   * @param context The context name.
   * @param kind The condition kind.
   * @return true when the framework must refuse it with an ApexEloquentException.
   */
  private static Boolean expectRefused(String context, String kind) {
    Boolean isSemiJoin = kind == 'semiIn' || kind == 'semiNotIn';
    if (isSemiJoin) {
      // SOQL accepts a semi-join only at the top level of WHERE, joined by AND, on the queried
      // object (measured). It runs in a child subquery, whose WHERE is its own top level.
      return SEMI_JOIN_REFUSED_CONTEXTS.contains(context);
    }
    // HAVING has no always-true expression for an empty NOT IN, so under OR it is refused
    // rather than dropped (dropping it would narrow the result). WHERE writes `Id != null`.
    return kind == 'notInEmpty' && (context == 'havingAfterOr' || context == 'havingGroupUnderOr');
  }

  private static final Set<String> SEMI_JOIN_REFUSED_CONTEXTS = new Set<String>{
    'rootAfterOr', // OR before the semi-join
    'rootBeforeOr', // OR after the semi-join
    'parent', // left side would be a relationship path
    'parentAfterOr',
    'nestedParent',
    'groupInParent',
    'through', // through() puts the target's conditions on a parent
    'groupUnderAnd', // nested WHERE expression
    'groupUnderOr'
  };

  /**
   * Runs every kind in one context and fails with the full list of combinations whose outcome
   * differs from the expectation.
   *
   * @param context The context name.
   * @param kinds The kinds to pair with it.
   */
  private static void runContext(String context, List<String> kinds) {
    List<String> mismatches = new List<String>();
    for (String kind : kinds) {
      String outcome;
      try {
        Scribe query = build(context, kind);
        // The executed (bound) query and the logged / asserted one must be the same query:
        // expanding the placeholders has to give toDisplay() exactly (case-sensitive).
        String expanded = query.toBoundQuery().expandedSoql;
        String literal = query.toDisplay();
        if (!expanded.equals(literal)) {
          mismatches.add(context + ' × ' + kind + ': expanded bound query differs from toDisplay()\n  bound: ' + expanded + '\n  toDisplay: ' + literal);
        }
        (new Eloquent()).get(query);
        outcome = 'ran';
      } catch (ApexEloquentException e) {
        outcome = 'refused';
      } catch (QueryException e) {
        outcome = 'INVALID SOQL: ' + e.getMessage();
      }
      String expected = expectRefused(context, kind) ? 'refused' : 'ran';
      if (outcome != expected) {
        mismatches.add(context + ' × ' + kind + ': expected ' + expected + ', got ' + outcome);
      }
    }
    Assert.isTrue(mismatches.isEmpty(), mismatches.size() + ' combination(s) differ:\n' + String.join(mismatches, '\n'));
  }

  @IsTest
  static void testRoot() {
    runContext('root', WHERE_KINDS);
  }

  @IsTest
  static void testRootAfterOr() {
    runContext('rootAfterOr', WHERE_KINDS);
  }

  @IsTest
  static void testRootBeforeOr() {
    runContext('rootBeforeOr', WHERE_KINDS);
  }

  @IsTest
  static void testParent() {
    runContext('parent', WHERE_KINDS);
  }

  @IsTest
  static void testParentAfterOr() {
    runContext('parentAfterOr', WHERE_KINDS);
  }

  @IsTest
  static void testNestedParent() {
    runContext('nestedParent', WHERE_KINDS);
  }

  @IsTest
  static void testChild() {
    runContext('child', WHERE_KINDS);
  }

  @IsTest
  static void testGroupUnderAnd() {
    runContext('groupUnderAnd', WHERE_KINDS);
  }

  @IsTest
  static void testGroupUnderOr() {
    runContext('groupUnderOr', WHERE_KINDS);
  }

  @IsTest
  static void testGroupInParent() {
    runContext('groupInParent', WHERE_KINDS);
  }

  @IsTest
  static void testThrough() {
    runContext('through', WHERE_KINDS);
  }

  @IsTest
  static void testHaving() {
    runContext('having', HAVING_KINDS);
  }

  @IsTest
  static void testHavingAfterOr() {
    runContext('havingAfterOr', HAVING_KINDS);
  }

  @IsTest
  static void testHavingGroupUnderOr() {
    runContext('havingGroupUnderOr', HAVING_KINDS);
  }
}
