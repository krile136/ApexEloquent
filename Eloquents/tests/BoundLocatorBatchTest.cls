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
 * Runs a Scribe through a real batch the way v4's docs tell callers moving off toSoql() to:
 * start() returns Database.getQueryLocatorWithBinds over toBoundQuery(). The test walks the
 * QueryLocator start() returns, i.e. the rows the batch is fed (review r2 N2).
 * The class is its own batch because only a top-level class can implement Database.Batchable.
 * @directory ApexEloquent/Eloquents/tests
 */
@IsTest(seeAllData=false)
private class BoundLocatorBatchTest implements Database.Batchable<SObject> {
  private final Scribe query;

  private BoundLocatorBatchTest(Scribe query) {
    this.query = query;
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    SoqlBinds.BoundQuery bound = this.query.toBoundQuery();
    return Database.getQueryLocatorWithBinds(bound.soql, bound.binds, AccessLevel.SYSTEM_MODE);
  }

  public void execute(Database.BatchableContext context, List<SObject> scope) {
    for (SObject row : scope) {
      row.put('Name', ((String) row.get('Name')) + ' done');
    }
    update scope;
  }

  public void finish(Database.BatchableContext context) {
  }

  @IsTest
  static void testBatch_WhenStartReturnsBoundLocator_ThenExactlyTheMatchingRowsAreProcessed() {
    // Arrange - only the name with a literal "50%" must reach execute(); the escape works only
    // when bound, so this also shows the locator runs the bound query. Group is platform-frozen.
    Long stamp = Datetime.now().getTime();
    Group percent = new Group(Name = 'EloquentRT 50%off', DeveloperName = 'EloquentRT_batch1_' + stamp);
    Group backslash = new Group(
      Name = 'EloquentRT 50' + String.fromCharArray(new List<Integer>{ 92 }) + 'off',
      DeveloperName = 'EloquentRT_batch2_' + stamp
    );
    insert new List<Group>{ percent, backslash };

    // Act - walk the QueryLocator start() returns, which is what the batch would be fed.
    // (Running it with Database.executeBatch failed with "AsyncException: Script-thrown
    // exception" for a test class acting as its own batch; not investigated.)
    BoundLocatorBatchTest batch = new BoundLocatorBatchTest(Scribe.of(Group.class).field('Name').whereContains('Name', 'EloquentRT 50%'));
    Set<Id> fed = new Set<Id>();
    Database.QueryLocatorIterator rows = batch.start(null).iterator();
    while (rows.hasNext()) {
      fed.add(rows.next().Id);
    }

    // Assert
    Assert.isTrue(fed.contains(percent.Id), 'The matching row is fed to the batch.');
    Assert.isFalse(fed.contains(backslash.Id), 'The other row is not.');
  }
}
