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
 * @directory ApexEloquent/ConditionClauses/tests
 */

/**
 * SOQL injection through condition values.
 *
 * Scribe renders values into the query text, so every value has to come out as exactly
 * one literal. The payloads below try to close the literal (quoted fields) or to append
 * syntax directly (unquoted fields), and would widen `WHERE <narrowing> AND <this>` to
 * every record through the trailing `OR`, since conditions are joined without parentheses.
 */
@isTest
public class ConditionClauseInjectionTest {
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
