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
 * Pins the SOQL text of every DateLiteral form. The 44 literals themselves were checked against
 * the platform (each one parsed in a real query); this keeps the builder writing them.
 * @directory ApexEloquent/tests
 */
@IsTest(seeAllData=false)
private class DateLiteralTest {
  @IsTest
  static void testDays_WhenBuilt_ThenSoqlNames() {
    Assert.areEqual('TODAY', DateLiteral.today().toString());
    Assert.areEqual('YESTERDAY', DateLiteral.yesterday().toString());
    Assert.areEqual('TOMORROW', DateLiteral.tomorrow().toString());
    Assert.areEqual('YESTERDAY', DateLiteral.last().day().toString());
    Assert.areEqual('TODAY', DateLiteral.current().day().toString());
    Assert.areEqual('TOMORROW', DateLiteral.next().day().toString());
  }

  @IsTest
  static void testPeriods_WhenBuilt_ThenSoqlNames() {
    Map<String, DateLiteral> expected = new Map<String, DateLiteral>{
      'LAST_WEEK' => DateLiteral.last().week(),
      'THIS_WEEK' => DateLiteral.current().week(),
      'NEXT_WEEK' => DateLiteral.next().week(),
      'LAST_MONTH' => DateLiteral.last().month(),
      'THIS_MONTH' => DateLiteral.current().month(),
      'NEXT_MONTH' => DateLiteral.next().month(),
      'LAST_QUARTER' => DateLiteral.last().quarter(),
      'THIS_QUARTER' => DateLiteral.current().quarter(),
      'NEXT_QUARTER' => DateLiteral.next().quarter(),
      'LAST_YEAR' => DateLiteral.last().year(),
      'THIS_YEAR' => DateLiteral.current().year(),
      'NEXT_YEAR' => DateLiteral.next().year(),
      'LAST_FISCAL_QUARTER' => DateLiteral.last().fiscalQuarter(),
      'THIS_FISCAL_QUARTER' => DateLiteral.current().fiscalQuarter(),
      'NEXT_FISCAL_QUARTER' => DateLiteral.next().fiscalQuarter(),
      'LAST_FISCAL_YEAR' => DateLiteral.last().fiscalYear(),
      'THIS_FISCAL_YEAR' => DateLiteral.current().fiscalYear(),
      'NEXT_FISCAL_YEAR' => DateLiteral.next().fiscalYear()
    };
    for (String soql : expected.keySet()) {
      Assert.areEqual(soql, expected.get(soql).toString());
    }
  }

  @IsTest
  static void testSpans_WhenBuilt_ThenSoqlNamesWithN() {
    Map<String, DateLiteral> expected = new Map<String, DateLiteral>{
      'LAST_N_DAYS:30' => DateLiteral.last(30).days(),
      'NEXT_N_DAYS:30' => DateLiteral.next(30).days(),
      'N_DAYS_AGO:30' => DateLiteral.ago(30).days(),
      'LAST_N_WEEKS:2' => DateLiteral.last(2).weeks(),
      'NEXT_N_WEEKS:2' => DateLiteral.next(2).weeks(),
      'N_WEEKS_AGO:2' => DateLiteral.ago(2).weeks(),
      'LAST_N_MONTHS:3' => DateLiteral.last(3).months(),
      'NEXT_N_MONTHS:3' => DateLiteral.next(3).months(),
      'N_MONTHS_AGO:3' => DateLiteral.ago(3).months(),
      'LAST_N_QUARTERS:4' => DateLiteral.last(4).quarters(),
      'NEXT_N_QUARTERS:4' => DateLiteral.next(4).quarters(),
      'N_QUARTERS_AGO:4' => DateLiteral.ago(4).quarters(),
      'LAST_N_YEARS:1' => DateLiteral.last(1).years(),
      'NEXT_N_YEARS:1' => DateLiteral.next(1).years(),
      'N_YEARS_AGO:1' => DateLiteral.ago(1).years(),
      'LAST_N_FISCAL_QUARTERS:4' => DateLiteral.last(4).fiscalQuarters(),
      'NEXT_N_FISCAL_QUARTERS:4' => DateLiteral.next(4).fiscalQuarters(),
      'N_FISCAL_QUARTERS_AGO:4' => DateLiteral.ago(4).fiscalQuarters(),
      'LAST_N_FISCAL_YEARS:2' => DateLiteral.last(2).fiscalYears(),
      'NEXT_N_FISCAL_YEARS:2' => DateLiteral.next(2).fiscalYears(),
      'N_FISCAL_YEARS_AGO:2' => DateLiteral.ago(2).fiscalYears(),
      'LAST_N_DAYS:0' => DateLiteral.last(0).days()
    };
    for (String soql : expected.keySet()) {
      Assert.areEqual(soql, expected.get(soql).toString());
    }
  }

  @IsTest
  static void testSpan_WhenNIsNullOrNegative_ThenThrow() {
    for (Integer n : new List<Integer>{ null, -1 }) {
      try {
        DateLiteral.last(n);
        Assert.fail('Expected ApexEloquentException for n = ' + n);
      } catch (ApexEloquentException e) {
        Assert.isTrue(e.getMessage().contains('last(Integer n)'), 'Got: ' + e.getMessage());
      }
    }
  }

  @IsTest
  static void testEquals_WhenSameLiteral_ThenEqualAndSameHash() {
    Assert.isTrue(DateLiteral.last(30).days().equals(DateLiteral.last(30).days()));
    Assert.areEqual(DateLiteral.last(30).days().hashCode(), DateLiteral.last(30).days().hashCode());
    Assert.isFalse(DateLiteral.last(30).days().equals(DateLiteral.last(31).days()));
    Assert.isFalse(DateLiteral.today().equals('TODAY'), 'A String is not a DateLiteral.');
  }
}
