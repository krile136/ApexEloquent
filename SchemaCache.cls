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
 * @description Transaction-scoped cache of the describe information the framework reads
 * on nearly every operation.
 *
 * `Schema.DescribeSObjectResult.fields.getMap()` builds a new map on every call — measured
 * at roughly 88μs per call on API v64.0 (500 calls in 44ms), against 0ms for reusing a
 * reference. `Scribe` alone reads it from ten places while assembling one query, once more
 * for every parent, child and semi-join, and `IEntry` reads it on every field access. The
 * map is immutable for the life of a transaction, so it is built once per object and shared.
 *
 * Both `Scribe` and `AbstractEntry` read through here. The knowledge being shared is a
 * single fact — "describe is expensive and the field map cannot change inside a
 * transaction" — so it lives in one place rather than being reproduced in each.
 *
 * A static map is never serialized, so unlike `Schema.DescribeSObjectResult` itself (see
 * `AbstractEntry.describeResult`, made transient in v3.4.1) this cannot break
 * `Database.Stateful` batch state.
 *
 * @see Scribe
 * @see AbstractEntry
 * @directory ApexEloquent
 */
public with sharing class SchemaCache {
  private static final String CLASS_NAME = 'SchemaCache';

  /**
   * Field maps already built, keyed by the object they describe.
   */
  private static final Map<Schema.SObjectType, Map<String, Schema.SObjectField>> FIELD_MAPS = new Map<Schema.SObjectType, Map<String, Schema.SObjectField>>();

  /**
   * The field map of the given object, built once per transaction.
   *
   * ⚠️ The returned map is shared. It is the same instance every caller receives, so it
   * must never be mutated. Apex gives no read-only map, so this is a contract rather than
   * something the compiler enforces; every current caller only reads.
   *
   * The keys are lower-case, but `containsKey` on an Apex `Map<String, ...>` ignores case
   * (measured on API v64.0: `OwnerId`, `ownerid` and `OWNERID` all return true), so callers
   * may look up whichever casing they have.
   *
   * @param sObjectType The object to describe.
   * @return Its field map.
   * @throws ApexEloquentException when sObjectType is null.
   */
  public static Map<String, Schema.SObjectField> fieldMapOf(Schema.SObjectType sObjectType) {
    if (sObjectType == null) {
      ApexEloquentException.required(CLASS_NAME, 'fieldMapOf(Schema.SObjectType sObjectType)', 'sObjectType', null)
        .fire();
    }
    Map<String, Schema.SObjectField> fieldMap = FIELD_MAPS.get(sObjectType);
    if (fieldMap == null) {
      fieldMap = sObjectType.getDescribe().fields.getMap();
      FIELD_MAPS.put(sObjectType, fieldMap);
    }
    return fieldMap;
  }

  /**
   * Whether the given object has a field by that name.
   *
   * Dotted names are answered `false`: `Scribe` does not support them as field names, and
   * the caller reports that separately with an explanation rather than as "no such field".
   *
   * @param sObjectType The object to check.
   * @param fieldName The API name to look for.
   * @return True when the object has that field.
   */
  public static Boolean hasField(Schema.SObjectType sObjectType, String fieldName) {
    if (String.isBlank(fieldName)) {
      return false;
    }
    return fieldMapOf(sObjectType).containsKey(fieldName);
  }

  /**
   * Empties the cache. Exists for the framework's own tests, which need to prove the cache
   * is populated on demand rather than by some earlier test in the same transaction.
   */
  @TestVisible
  private static void clear() {
    FIELD_MAPS.clear();
  }
}
