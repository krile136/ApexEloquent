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
 * @directory ApexEloquent/tests
 */

/**
 * SOQL injection through condition values, ORDER BY fields and aggregate aliases.
 *
 * Scribe renders values into the query text, so every value has to come out as exactly
 * one operand. The payloads below try to close the literal (quoted fields), to append
 * syntax directly (unquoted fields and numeric HAVING operands), or to reach a local
 * variable through a bind reference (`:name`).
 *
 * How far an injected `OR` reaches depends on the rest of the query. SOQL refuses AND and
 * OR on one level without parentheses (measured on API v67.0: `... AND x = 0 OR Id != null`
 * is `unexpected token: 'OR'`), so a bare `OR` widens a query whose other conditions are
 * OR-joined or absent, and a payload that balances parentheses (`0) OR (Id != null`)
 * widens one inside a whereGroup.
 */
@isTest
public class SoqlInjectionTest {
  private static final String QUOTE_BREAKOUT = 'x\' OR Name != \'y';
  private static final String MULTI_BREAKOUT = 'a\') OR Id != null OR MultiSelectField__c INCLUDES (\'b';
  private static final String UNQUOTED_PAYLOAD = '0 OR Id != null';

  private static Map<String, Schema.SObjectField> fieldsOf(Schema.SObjectType sObjectType) {
    return sObjectType.getDescribe().fields.getMap();
  }

  private static void assertRefused(IConditionClause clause) {
    try {
      clause.build();
      Assert.fail('A value that is not a single literal must be refused, but built: ' + clause.build());
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('not a single SOQL literal'), 'Unexpected message: ' + e.getMessage());
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Quoted fields: the literal must not be closable
  // ---------------------------------------------------------------------------------------------

  @isTest
  static void testBuild_WhenStringValueTriesToCloseQuote_ThenQuoteIsEscaped() {
    IConditionClause clause = new EqualConditionClause(
      Account.getSObjectType(),
      fieldsOf(Account.getSObjectType()),
      'Name',
      QUOTE_BREAKOUT
    );

    Assert.areEqual('Name = \'x\\\' OR Name != \\\'y\'', clause.build());
  }

  @isTest
  static void testBuild_WhenStringValueSmugglesBackslashBeforeQuote_ThenBothAreEscaped() {
    // `\'` must not become `\\'` (an escaped backslash followed by a closing quote).
    IConditionClause clause = new EqualConditionClause(
      Account.getSObjectType(),
      fieldsOf(Account.getSObjectType()),
      'Name',
      'a\\\' OR Name != \'b'
    );

    Assert.areEqual('Name = \'a\\\\\\\' OR Name != \\\'b\'', clause.build());
  }

  @isTest
  static void testBuild_WhenInValueTriesToCloseQuote_ThenQuoteIsEscaped() {
    IConditionClause clause = new InConditionClause(
      Account.getSObjectType(),
      fieldsOf(Account.getSObjectType()),
      'Name',
      new List<String>{ 'safe', QUOTE_BREAKOUT }
    );

    Assert.areEqual('Name IN (\'safe\', \'x\\\' OR Name != \\\'y\')', clause.build());
  }

  @isTest
  static void testBuild_WhenIncludesValueTriesToCloseQuote_ThenQuoteIsEscaped() {
    IConditionClause clause = new IncludesConditionClause(
      Account.getSObjectType(),
      fieldsOf(Account.getSObjectType()),
      'MultiSelectField__c',
      new List<String>{ MULTI_BREAKOUT }
    );

    Assert.areEqual(
      'MultiSelectField__c INCLUDES (\'a\\\') OR Id != null OR MultiSelectField__c INCLUDES (\\\'b\')',
      clause.build()
    );
  }

  @isTest
  static void testBuild_WhenExcludesValueTriesToCloseQuote_ThenQuoteIsEscaped() {
    IConditionClause clause = new ExcludeConditionClause(
      Account.getSObjectType(),
      fieldsOf(Account.getSObjectType()),
      'MultiSelectField__c',
      new List<String>{ MULTI_BREAKOUT }
    );

    Assert.areEqual(
      'MultiSelectField__c EXCLUDES (\'a\\\') OR Id != null OR MultiSelectField__c INCLUDES (\\\'b\')',
      clause.build()
    );
  }

  // ---------------------------------------------------------------------------------------------
  // Unquoted fields: there is no quote to escape, so syntax must be refused
  // ---------------------------------------------------------------------------------------------

  @isTest
  static void testBuild_WhenStringSyntaxGoesToNumericField_ThenRefused() {
    Schema.SObjectType opp = Opportunity.getSObjectType();
    assertRefused(new EqualConditionClause(opp, fieldsOf(opp), 'Amount', UNQUOTED_PAYLOAD));
    assertRefused(new NotEqualConditionClause(opp, fieldsOf(opp), 'Amount', UNQUOTED_PAYLOAD));
    assertRefused(new GreaterThanConditionClause(opp, fieldsOf(opp), 'Amount', UNQUOTED_PAYLOAD));
    assertRefused(new GreaterThanOrEqualConditionClause(opp, fieldsOf(opp), 'Amount', UNQUOTED_PAYLOAD));
    assertRefused(new LessThanConditionClause(opp, fieldsOf(opp), 'Amount', UNQUOTED_PAYLOAD));
    assertRefused(new LessThanOrEqualConditionClause(opp, fieldsOf(opp), 'Amount', UNQUOTED_PAYLOAD));
  }

  @isTest
  static void testBuild_WhenStringSyntaxGoesToBooleanOrDateField_ThenRefused() {
    Schema.SObjectType opp = Opportunity.getSObjectType();
    assertRefused(new EqualConditionClause(opp, fieldsOf(opp), 'IsPrivate', 'true OR Id != null'));
    assertRefused(new GreaterThanConditionClause(opp, fieldsOf(opp), 'CloseDate', 'TODAY OR Id != null'));
  }

  @isTest
  static void testBuild_WhenOneInValueCarriesSyntax_ThenRefused() {
    Schema.SObjectType opp = Opportunity.getSObjectType();
    assertRefused(new InConditionClause(opp, fieldsOf(opp), 'Amount', new List<Object>{ 100, '0) OR (Id != null' }));
    assertRefused(new NotInConditionClause(opp, fieldsOf(opp), 'Amount', new List<Object>{ 100, '0) OR (Id != null' }));
  }

  @isTest
  static void testBuild_WhenValueStartsWithColon_ThenRefusedAsBindReference() {
    // `:label` is a bind to a local variable of whichever method runs Database.query.
    Schema.SObjectType account = Account.getSObjectType();
    assertRefused(new EqualConditionClause(account, fieldsOf(account), 'NumberOfEmployees', ':label'));
    assertRefused(new InConditionClause(account, fieldsOf(account), 'NumberOfEmployees', new List<Object>{ ':label' }));
  }

  // ---------------------------------------------------------------------------------------------
  // HAVING: numeric aggregates render their operand as a number, so it must be a single token
  // ---------------------------------------------------------------------------------------------

  private static Scribe countByAccount(Scribe havingScribe) {
    return Scribe.of(Opportunity.class).field('AccountId').count('Id', 'cnt').groupByField('AccountId').havingCondition(havingScribe);
  }

  private static void assertHavingRefused(Scribe havingScribe) {
    try {
      String soql = countByAccount(havingScribe).toSoql();
      Assert.fail('A HAVING operand that is not a single literal must be refused, but built: ' + soql);
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('not a single SOQL literal'), 'Unexpected message: ' + e.getMessage());
    }
  }

  private static void assertEndsWith(String expectedTail, String soql) {
    Assert.isTrue(soql.endsWith(expectedTail), 'Expected the query to end with `' + expectedTail + '`: ' + soql);
  }

  @isTest
  static void testToSoql_WhenHavingCountValueCarriesSyntax_ThenRefused() {
    assertHavingRefused(Scribe.asHaving().whereGreaterThan('cnt', '999999 OR COUNT(Id) > 0'));
  }

  @isTest
  static void testToSoql_WhenHavingInValueHoldsComma_ThenRefusedInsteadOfSplit() {
    // One value must stay one operand: '1, 2' used to come out as `IN (1, 2)`.
    assertHavingRefused(Scribe.asHaving().whereIn('cnt', new List<String>{ '1, 2' }));
  }

  @isTest
  static void testToSoql_WhenHavingValueStartsWithColon_ThenRefusedAsBindReference() {
    assertHavingRefused(Scribe.asHaving().whereEqual('cnt', ':label'));
  }

  @isTest
  static void testToSoql_WhenHavingCountValueIsNumberOrNumericString_ThenUnquoted() {
    assertEndsWith('HAVING COUNT(Id) > 5', countByAccount(Scribe.asHaving().whereGreaterThan('cnt', 5)).toSoql());
    assertEndsWith('HAVING COUNT(Id) > 5', countByAccount(Scribe.asHaving().whereGreaterThan('cnt', '5')).toSoql());
    assertEndsWith(
      'HAVING COUNT(Id) IN (1, 2)',
      countByAccount(Scribe.asHaving().whereIn('cnt', new List<Integer>{ 1, 2 })).toSoql()
    );
    assertEndsWith(
      'HAVING COUNT(Id) NOT IN (1, 2)',
      countByAccount(Scribe.asHaving().whereNotIn('cnt', new List<Integer>{ 1, 2 })).toSoql()
    );
  }

  @isTest
  static void testToSoql_WhenHavingValueIsRefused_ThenMessageNamesTheAggregate() {
    try {
      countByAccount(Scribe.asHaving().whereGreaterThan('cnt', 'x y')).toSoql();
      Assert.fail('The value must be refused');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('HAVING value compared with an aggregate of `Id`'), e.getMessage());
    }
  }

  @isTest
  static void testToSoql_WhenHavingSumNotIn_ThenRendered() {
    // SOQL accepts `HAVING SUM(Amount) NOT IN (1, 2)` (measured on API v67.0).
    String soql = Scribe.of(Opportunity.class)
      .field('StageName')
      .sum('Amount', 'total')
      .groupByField('StageName')
      .havingCondition(Scribe.asHaving().whereNotIn('total', new List<Integer>{ 1, 2 }))
      .toSoql();

    assertEndsWith('HAVING SUM(Amount) NOT IN (1, 2)', soql);
  }

  @isTest
  static void testToSoql_WhenHavingMinOnTextField_ThenStaysQuotedAndEscaped() {
    String soql = Scribe.of(Account.class)
      .field('Industry')
      .min('Name', 'firstName')
      .groupByField('Industry')
      .havingCondition(Scribe.asHaving().whereEqual('firstName', QUOTE_BREAKOUT))
      .toSoql();

    assertEndsWith('HAVING MIN(Name) = \'x\\\' OR Name != \\\'y\'', soql);
  }

  // ---------------------------------------------------------------------------------------------
  // Legitimate unquoted values keep working
  // ---------------------------------------------------------------------------------------------

  @isTest
  static void testBuild_WhenNumberIsPassedAsString_ThenStillRendered() {
    Schema.SObjectType account = Account.getSObjectType();
    IConditionClause clause = new EqualConditionClause(account, fieldsOf(account), 'NumberOfEmployees', '100');

    Assert.areEqual('NumberOfEmployees = 100', clause.build());
  }

  @isTest
  static void testBuild_WhenDateLiteralIsPassedAsString_ThenStillRendered() {
    Schema.SObjectType opp = Opportunity.getSObjectType();
    IConditionClause clause = new GreaterThanOrEqualConditionClause(opp, fieldsOf(opp), 'CloseDate', 'LAST_N_DAYS:30');

    Assert.areEqual('CloseDate >= LAST_N_DAYS:30', clause.build());
  }

  @isTest
  static void testBuild_WhenTypedValuesGoToUnquotedFields_ThenRendered() {
    Schema.SObjectType opp = Opportunity.getSObjectType();

    Assert.areEqual('Amount > -1.5', new GreaterThanConditionClause(opp, fieldsOf(opp), 'Amount', -1.5).build());
    Assert.areEqual('IsPrivate = false', new EqualConditionClause(opp, fieldsOf(opp), 'IsPrivate', false).build());
    Assert.areEqual(
      'CloseDate IN (2026-01-02, 2026-03-04)',
      new InConditionClause(opp, fieldsOf(opp), 'CloseDate', new List<Date>{ Date.newInstance(2026, 1, 2), Date.newInstance(2026, 3, 4) })
        .build()
    );
    Assert.areEqual(
      'CreatedDate > 2026-01-02T03:04:05Z',
      new GreaterThanConditionClause(opp, fieldsOf(opp), 'CreatedDate', Datetime.newInstanceGmt(2026, 1, 2, 3, 4, 5)).build()
    );

    Schema.SObjectType account = Account.getSObjectType();
    Assert.areEqual('NumberOfEmployees = 5', new EqualConditionClause(account, fieldsOf(account), 'NumberOfEmployees', 5L).build());

    Schema.SObjectType hours = Schema.BusinessHours.SObjectType;
    Assert.areEqual(
      'MondayStartTime = 08:00:00.000Z',
      new EqualConditionClause(hours, fieldsOf(hours), 'MondayStartTime', Time.newInstance(8, 0, 0, 0)).build()
    );
  }

  @isTest
  static void testBuild_WhenComboboxField_ThenValueIsQuoted() {
    // COMBOBOX is text; it used to render unquoted, which no query could accept.
    Schema.SObjectType task = Task.getSObjectType();
    Assert.areEqual('Subject = \'Call\'', new EqualConditionClause(task, fieldsOf(task), 'Subject', 'Call').build());
  }

  // ---------------------------------------------------------------------------------------------
  // Identifiers: ORDER BY fields and aggregate aliases are written as is, so only their shape is let in
  // ---------------------------------------------------------------------------------------------

  private static void assertOrderByRefused(String field) {
    try {
      String soql = Scribe.of(Account.class).field('Id').orderBy(field).toSoql();
      Assert.fail('An ORDER BY field that is not a single field path must be refused, but built: ' + soql);
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('not a single field path'), 'Unexpected message: ' + e.getMessage());
    }
  }

  private static void assertAliasRefused(String alias) {
    try {
      String soql = Scribe.of(Opportunity.class).field('AccountId').count('Id', alias).groupByField('AccountId').toSoql();
      Assert.fail('An alias that is not a single identifier must be refused, but built: ' + soql);
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('not a single identifier'), 'Unexpected message: ' + e.getMessage());
    }
  }

  @isTest
  static void testOrderBy_WhenFieldCarriesSyntax_ThenRefused() {
    // A sort column taken straight from an LWC datatable is the typical source.
    assertOrderByRefused('Name, Id');
    assertOrderByRefused('Name DESC NULLS FIRST');
    assertOrderByRefused('Name LIMIT 1');
    assertOrderByRefused('Name\'');
    assertOrderByRefused('COUNT(Id) DESC, Name');
    assertOrderByRefused('Account..Name');
  }

  @isTest
  static void testOrderBy_WhenFieldPathOrAggregate_ThenRendered() {
    assertEndsWith('ORDER BY Name ASC', Scribe.of(Account.class).field('Id').orderBy('Name').toSoql());
    assertEndsWith(
      'ORDER BY Account.Owner.Name DESC NULLS LAST',
      Scribe.of(Opportunity.class).field('Id').orderBy('Account.Owner.Name', 'DESC', 'LAST').toSoql()
    );
    assertEndsWith(
      'ORDER BY COUNT(Id) DESC',
      Scribe.of(Opportunity.class)
        .field('AccountId')
        .count('Id', 'cnt')
        .groupByField('AccountId')
        .orderBy('COUNT(Id)', 'DESC')
        .toSoql()
    );
  }

  @isTest
  static void testOrderBy_WhenKeywordUpperCasesToDirection_ThenTheKeywordIsWrittenInstead() {
    // `\u017F` (long s) and `\u0131` (dotless i) upper-case to ASCII, so they pass the keyword check.
    assertEndsWith(
      'ORDER BY Name ASC NULLS FIRST',
      Scribe.of(Account.class).field('Id').orderBy('Name', 'a\u017Fc', 'f\u0131rst').toSoql()
    );
    assertEndsWith('ORDER BY Name DESC', Scribe.of(Account.class).field('Id').orderBy('Name', 'desc').toSoql());
  }

  @isTest
  static void testOrderBy_WhenFieldHasSurroundingSpaces_ThenTrimmed() {
    assertEndsWith('ORDER BY Name ASC', Scribe.of(Account.class).field('Id').orderBy(' Name ').toSoql());
  }

  @isTest
  static void testOrderBy_WhenFunctionIsNested_ThenRefused() {
    assertOrderByRefused('CALENDAR_YEAR(convertTimezone(CreatedDate))');
  }

  @isTest
  static void testOrderBy_WhenAggregateIsQueried_ThenPlatformAcceptsIt() {
    String soql = Scribe.of(Opportunity.class)
      .field('AccountId')
      .count('Id', 'cnt')
      .groupByField('AccountId')
      .orderBy('COUNT(Id)', 'DESC')
      .toSoql();

    Assert.areEqual(0, Database.query(soql).size(), 'The aggregate form the shape lets in must be valid SOQL');
  }

  @isTest
  static void testAggregate_WhenAliasCarriesSyntax_ThenRefused() {
    assertAliasRefused('cnt, Name');
    assertAliasRefused('cnt FROM Account');
    assertAliasRefused('a.b');
    assertAliasRefused('1cnt');
  }

  @isTest
  static void testAggregate_WhenAliasIsIdentifier_ThenRendered() {
    String soql = Scribe.of(Opportunity.class).field('AccountId').count('Id', 'opp_Count2').groupByField('AccountId').toSoql();

    Assert.isTrue(soql.contains('COUNT(Id) opp_Count2'), soql);
  }

  // ---------------------------------------------------------------------------------------------
  // End to end: the platform runs the query and the payload stays inside the literal
  // ---------------------------------------------------------------------------------------------

  @isTest
  static void testGet_WhenQuoteBreakoutIsQueried_ThenNoRecordMatches() {
    insert new List<Account>{ new Account(Name = 'Alpha'), new Account(Name = 'Beta') };

    List<IEntry> entries = new Eloquent()
      .get(Scribe.of(Account.class).field('Id').whereEqual('Name', QUOTE_BREAKOUT));

    Assert.areEqual(0, entries.size(), 'The payload must be compared as a name, not widen the query to every account');
  }

  @isTest
  static void testGet_WhenUnquotedPayloadIsQueried_ThenRefusedBeforeTheQueryRuns() {
    insert new Account(Name = 'Alpha', NumberOfEmployees = 10);

    try {
      new Eloquent().get(Scribe.of(Account.class).field('Id').whereGreaterThan('NumberOfEmployees', UNQUOTED_PAYLOAD));
      Assert.fail('The payload must be refused');
    } catch (ApexEloquentException e) {
      Assert.isTrue(e.getMessage().contains('not a single SOQL literal'), 'Unexpected message: ' + e.getMessage());
    }
  }
}
