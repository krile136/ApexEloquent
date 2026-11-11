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
 * @description Collects the bind variables of one query while Scribe builds it, so Eloquent can
 * run the query with Database.queryWithBinds instead of pasting values into the SOQL text.
 *
 * Each bound value is recorded with the literal Scribe would have written for it. The
 * expanded query — every placeholder replaced by that literal — is what goes to the debug
 * log and is, character for character, what Scribe.toSoql() returns. Both forms come from
 * one rendering pass, so the logged query cannot drift from the executed one.
 *
 * Why queryWithBinds and not Database.query with `:name`: Database.query resolves `:name`
 * against the local variables of the method that calls it, so a query built in one class and
 * run in another cannot bind (the reason ApexEloquent rendered literals until v4).
 * queryWithBinds takes the values as a map and has no such limit (measured: root WHERE, child
 * subquery, semi-join, HAVING, parent paths, 2000 binds in one IN list).
 *
 * Internal: not part of the supported API. The collector is held in a static for the length
 * of one Scribe.toBoundQuery() call, because condition clauses render through a build()
 * that takes no arguments.
 * @see Scribe
 * @directory ApexEloquent
 */
public with sharing class SoqlBinds {
  /** The collector of the query being built, or null outside Scribe.toBoundQuery(). */
  public static SoqlBinds active;

  private static final String PREFIX = 'aeBind';
  private static final Pattern PLACEHOLDER = Pattern.compile(':' + PREFIX + '(\\d+)');

  private final Map<String, Object> values = new Map<String, Object>();
  private final List<String> literals = new List<String>();

  /**
   * Registers one value and returns the placeholder to write in its place.
   *
   * @param value The value as the query engine compares it (already of the field's type).
   * @param literal The literal Scribe would have written for it, for the expanded query.
   * @return The placeholder, e.g. `:aeBind0`.
   */
  public String add(Object value, String literal) {
    String name = PREFIX + this.literals.size();
    this.values.put(name, value);
    this.literals.add(literal);
    return ':' + name;
  }

  /**
   * The bind map to pass to Database.queryWithBinds.
   *
   * @return Placeholder name (without the colon) to value.
   */
  public Map<String, Object> getValues() {
    return this.values;
  }

  /**
   * Replaces every placeholder with its literal. Field names and SOQL keywords cannot contain
   * `:aeBind<n>` (date literals such as `LAST_N_DAYS:30` have a number right after the colon),
   * so a placeholder is never mistaken for other text.
   *
   * @param boundSoql The query with placeholders.
   * @return The query as Scribe.toSoql() writes it.
   */
  public String expand(String boundSoql) {
    Matcher matcher = PLACEHOLDER.matcher(boundSoql);
    String expanded = '';
    Integer last = 0;
    while (matcher.find()) {
      expanded += boundSoql.substring(last, matcher.start()) + this.literals[Integer.valueOf(matcher.group(1))];
      last = matcher.end();
    }
    return expanded + boundSoql.substring(last);
  }

  /**
   * A built query in both forms.
   */
  public class BoundQuery {
    /** The query with `:aeBind<n>` placeholders, for Database.queryWithBinds. */
    public final String soql;
    /** The values of the placeholders. */
    public final Map<String, Object> binds;
    /** The query with the values written in, as Scribe.toSoql() returns it; for logs. */
    public final String expandedSoql;

    /**
     * @param soql The query with placeholders.
     * @param binds The placeholder values.
     * @param expandedSoql The query with the values written in.
     */
    public BoundQuery(String soql, Map<String, Object> binds, String expandedSoql) {
      this.soql = soql;
      this.binds = binds;
      this.expandedSoql = expandedSoql;
    }
  }
}
