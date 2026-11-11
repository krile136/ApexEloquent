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
 * @description A SOQL date literal (TODAY, LAST_N_DAYS:30, THIS_FISCAL_QUARTER, ...) as a typed
 * value, read as "condition + unit":
 *
 * ```
 * DateLiteral.today()                       // TODAY
 * DateLiteral.last().month()                // LAST_MONTH
 * DateLiteral.current().fiscalQuarter()     // THIS_FISCAL_QUARTER  (`this` is reserved in Apex)
 * DateLiteral.next().year()                 // NEXT_YEAR
 * DateLiteral.last(30).days()               // LAST_N_DAYS:30
 * DateLiteral.next(2).fiscalYears()         // NEXT_N_FISCAL_YEARS:2
 * DateLiteral.ago(4).fiscalQuarters()       // N_FISCAL_QUARTERS_AGO:4
 * ```
 *
 * last() / current() / next() lead to the singular units, last(n) / next(n) / ago(n) to the
 * plural ones, so a mixed-up pair (`last(3).month()`) does not compile. Every literal SOQL has
 * is reachable (all 44 measured on the platform); LAST_90_DAYS / NEXT_90_DAYS are written
 * last(90).days() / next(90).days(), which return the same rows (measured).
 *
 * Read the periods as SOQL does (measured):
 * - LAST_N_DAYS:n includes today, so it spans n + 1 days (`last(1).days()` is yesterday and today).
 * - A range literal changes meaning with the operator: `=` is within the period, `<` before it
 *   starts, `>` after it ends — `CloseDate > LAST_N_DAYS:30` returns future rows only. Use
 *   Scribe.whereWithin / whereBefore / whereAfter / whereSince / whereUntil, which say which.
 * - last().month() (LAST_MONTH), last(1).months() and ago(1).months() return the same rows.
 *
 * Usable only against a Date or Datetime field; anything else is refused when the query is
 * built. The literal is written into the query as it is (it has no bind form), which is safe:
 * the text is fixed by this class and n is an Integer.
 * @see Scribe
 * @directory ApexEloquent
 */
public with sharing class DateLiteral {
  private static final String CLASS_NAME = 'DateLiteral';

  private final String token;

  private DateLiteral(String token) {
    this.token = token;
  }

  /** @return TODAY */
  public static DateLiteral today() {
    return new DateLiteral('TODAY');
  }

  /** @return YESTERDAY */
  public static DateLiteral yesterday() {
    return new DateLiteral('YESTERDAY');
  }

  /** @return TOMORROW */
  public static DateLiteral tomorrow() {
    return new DateLiteral('TOMORROW');
  }

  /**
   * The period just before the current one: last().month() is LAST_MONTH.
   *
   * @return The unit picker.
   */
  public static Period last() {
    return new Period('LAST', 'YESTERDAY');
  }

  /**
   * The current period: current().quarter() is THIS_QUARTER.
   *
   * @return The unit picker.
   */
  public static Period current() {
    return new Period('THIS', 'TODAY');
  }

  /**
   * The period just after the current one: next().week() is NEXT_WEEK.
   *
   * @return The unit picker.
   */
  public static Period next() {
    return new Period('NEXT', 'TOMORROW');
  }

  /**
   * The last n periods up to now: last(30).days() is LAST_N_DAYS:30 (which includes today).
   *
   * @param n The number of periods, 0 or more.
   * @return The unit picker.
   */
  public static Span last(Integer n) {
    return new Span('LAST_N_', '', 'last(Integer n)', n);
  }

  /**
   * The next n periods from now: next(2).weeks() is NEXT_N_WEEKS:2.
   *
   * @param n The number of periods, 0 or more.
   * @return The unit picker.
   */
  public static Span next(Integer n) {
    return new Span('NEXT_N_', '', 'next(Integer n)', n);
  }

  /**
   * The one period n periods ago: ago(3).months() is N_MONTHS_AGO:3.
   *
   * @param n The number of periods back, 0 or more.
   * @return The unit picker.
   */
  public static Span ago(Integer n) {
    return new Span('N_', '_AGO', 'ago(Integer n)', n);
  }

  /**
   * The literal as it is written into SOQL.
   *
   * @return e.g. `LAST_N_DAYS:30`
   */
  public override String toString() {
    return this.token;
  }

  /**
   * Two literals are equal when they write the same SOQL, so Scribe's condition assertions can
   * compare them.
   *
   * @param other The object to compare with.
   * @return true for the same literal.
   */
  public Boolean equals(Object other) {
    return other instanceof DateLiteral && ((DateLiteral) other).token == this.token;
  }

  /**
   * @return A hash consistent with equals.
   */
  public Integer hashCode() {
    return this.token.hashCode();
  }

  /**
   * Picks the unit of a single period: last(), current() or next().
   */
  public class Period {
    private final String direction;
    private final String dayToken;

    private Period(String direction, String dayToken) {
      this.direction = direction;
      this.dayToken = dayToken;
    }

    /** @return YESTERDAY / TODAY / TOMORROW */
    public DateLiteral day() {
      return new DateLiteral(this.dayToken);
    }

    /** @return LAST_WEEK / THIS_WEEK / NEXT_WEEK */
    public DateLiteral week() {
      return this.of('WEEK');
    }

    /** @return LAST_MONTH / THIS_MONTH / NEXT_MONTH */
    public DateLiteral month() {
      return this.of('MONTH');
    }

    /** @return LAST_QUARTER / THIS_QUARTER / NEXT_QUARTER */
    public DateLiteral quarter() {
      return this.of('QUARTER');
    }

    /** @return LAST_YEAR / THIS_YEAR / NEXT_YEAR */
    public DateLiteral year() {
      return this.of('YEAR');
    }

    /** @return LAST_FISCAL_QUARTER / THIS_FISCAL_QUARTER / NEXT_FISCAL_QUARTER */
    public DateLiteral fiscalQuarter() {
      return this.of('FISCAL_QUARTER');
    }

    /** @return LAST_FISCAL_YEAR / THIS_FISCAL_YEAR / NEXT_FISCAL_YEAR */
    public DateLiteral fiscalYear() {
      return this.of('FISCAL_YEAR');
    }

    private DateLiteral of(String unit) {
      return new DateLiteral(this.direction + '_' + unit);
    }
  }

  /**
   * Picks the unit of n periods: last(n), next(n) or ago(n).
   */
  public class Span {
    private final String prefix;
    private final String suffix;
    private final Integer n;

    private Span(String prefix, String suffix, String method, Integer n) {
      if (n == null) {
        ApexEloquentException.required(CLASS_NAME, method, 'n', n).fire();
      }
      if (n < 0) {
        ApexEloquentException.invalidArgument(
            CLASS_NAME,
            method,
            'The number of periods cannot be negative.',
            'Pass 0 or more. To look the other way, use last(n) / next(n) instead.',
            'n',
            n
          )
          .fire();
      }
      this.prefix = prefix;
      this.suffix = suffix;
      this.n = n;
    }

    /** @return LAST_N_DAYS:n / NEXT_N_DAYS:n / N_DAYS_AGO:n */
    public DateLiteral days() {
      return this.of('DAYS');
    }

    /** @return LAST_N_WEEKS:n / NEXT_N_WEEKS:n / N_WEEKS_AGO:n */
    public DateLiteral weeks() {
      return this.of('WEEKS');
    }

    /** @return LAST_N_MONTHS:n / NEXT_N_MONTHS:n / N_MONTHS_AGO:n */
    public DateLiteral months() {
      return this.of('MONTHS');
    }

    /** @return LAST_N_QUARTERS:n / NEXT_N_QUARTERS:n / N_QUARTERS_AGO:n */
    public DateLiteral quarters() {
      return this.of('QUARTERS');
    }

    /** @return LAST_N_YEARS:n / NEXT_N_YEARS:n / N_YEARS_AGO:n */
    public DateLiteral years() {
      return this.of('YEARS');
    }

    /** @return LAST_N_FISCAL_QUARTERS:n / NEXT_N_FISCAL_QUARTERS:n / N_FISCAL_QUARTERS_AGO:n */
    public DateLiteral fiscalQuarters() {
      return this.of('FISCAL_QUARTERS');
    }

    /** @return LAST_N_FISCAL_YEARS:n / NEXT_N_FISCAL_YEARS:n / N_FISCAL_YEARS_AGO:n */
    public DateLiteral fiscalYears() {
      return this.of('FISCAL_YEARS');
    }

    private DateLiteral of(String unit) {
      return new DateLiteral(this.prefix + unit + this.suffix + ':' + this.n);
    }
  }
}
