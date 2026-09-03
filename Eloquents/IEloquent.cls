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
 * @description Defines the contract for the data access layer of the ApexEloquent framework.
 *
 * This interface is responsible for executing queries constructed by the `Scribe` builder
 * and for performing DML operations. Following the Repository Pattern, this interface
 * abstracts the data source. It has two primary implementations: `Eloquent` for live
 * database interactions, and `MockEloquent` for database-independent unit testing.
 * @see Scribe
 * @see Eloquent
 * @see MockEloquent
 * @directory ApexEloquent/Eloquents
 */
public interface IEloquent {
  /**
  * Tags the very next read/DML call with a label. The label is reset to
  * the implicit 'default' label after that call (whether it succeeded or
  * threw). Chainable.
  *
  * Usage:
  *   this.eloquent.label('jobLoad').first(scribe);
  *   this.eloquent.label('finalDml').doUpdate(records);
  *
  * @param label non-blank label string
  * @return this IEloquent for chaining
  * @throws ApexEloquentException if label is null or blank
  */
  IEloquent label(String label);

  /**
   * Returns an IEloquent that runs SOQL/DML in user mode (the default):
   * the running user's field-level security and object permissions are enforced.
   * Note: record-level sharing is governed by the class sharing keyword, not by this setting.
   *
   * Immutable: the receiver keeps its own access mode — always use the return
   * value (`eloquent.userMode().doX(...)`), never call this as a statement.
   *
   * @return a mode-switched IEloquent for chaining; the receiver is unmodified
   */
  IEloquent userMode();

  /**
   * Returns an IEloquent that runs SOQL/DML in system mode: field-level security
   * and object permissions are NOT enforced. Record-level sharing still follows the
   * class sharing keyword (use a `without sharing` caller to also bypass sharing).
   * Opt out of the secure-by-default user mode only where system-context execution is required.
   *
   * Immutable: the receiver keeps its own access mode — always use the return
   * value (`eloquent.systemMode().doX(...)`), never call this as a statement.
   *
   * @return a mode-switched IEloquent for chaining; the receiver is unmodified
   */
  IEloquent systemMode();

  /**
  * Executes SOQL and retrieves the results.
  * If the number of retrieved records is 0, an empty list is returned.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved results as a list of Entry objects
  */
  List<IEntry> get(Scribe scribe);

  /**
  * Executes SOQL and retrieves the results as SObject.
  * If the number of retrieved records is 0, an empty list is returned.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved results as a list of SObjects
  */
  List<SObject> getAsSObject(Scribe scribe);

  /**
  * Executes SOQL and returns the first record.
  * If the number of retrieved records is 0, null is returned.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved result as an Entry object
  */
  IEntry first(Scribe scribe);

  /**
  * Executes SOQL and returns the first record as SObject.
  * If the number of retrieved records is 0, null is returned.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved result as an SObject
  */
  SObject firstAsSObject(Scribe scribe);

  /**
  * Executes SOQL and returns the first record.
  * If the number of retrieved records is 0, an exception is thrown.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved result as an Entry object
  * @throws QueryException If the number of retrieved records is 0
  */
  IEntry firstOrFail(Scribe scribe);

  /**
  * Executes SOQL and returns the first record.
  * If the number of retrieved records is 0, the given exception is thrown as-is —
  * business-specific errors (e.g. UsecaseException with a user-facing message)
  * no longer need the first() + null-check + throw boilerplate.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @param Exception orFail: the exception to throw when zero records are found
  * @return Retrieved result as an Entry object
  */
  IEntry firstOrFail(Scribe scribe, Exception orFail);

  /**
  * Executes SOQL and returns the first record as SObject.
  * If the number of retrieved records is 0, an exception is thrown.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved result as an SObject
  * @throws QueryException If the number of retrieved records is 0
  */
  SObject firstOrFailAsSObject(Scribe scribe) ;

  /**
   * Executes a raw SOQL string and returns the results as IEntry instances.
   *
   * Use this when the Scribe builder cannot express the desired query (e.g.,
   * complex dynamic SOQL, vendor-supplied queries, migration of legacy code).
   *
   * IMPORTANT: When called via MockEloquent during testing, the returned
   * IEntry instances have the "select-forgotten detection" disabled, because
   * raw SOQL bypasses the Scribe FieldStructure pipeline. Field access on
   * those mocks will not validate that the field was part of the original SELECT.
   *
   * @param soql The full SOQL query string (e.g., 'SELECT Id, Name FROM Account WHERE ...').
   * @return The query results wrapped as IEntry instances. Empty list when no records match.
   * @throws ApexEloquentException when soql is null or blank.
   * @throws QueryException when soql is syntactically invalid or refers to inaccessible objects (production only).
   */
  List<IEntry> rawSoql(String soql);

  /**
  * Inserts a record and returns the inserted record.
  *
  * @param record SObject to be inserted
  * @return Inserted SObject
  */
  SObject doInsert(SObject record);

  /**
  * Inserts a list of records and returns the inserted records.
  *
  * The returned list preserves the order of the input list.
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * @param records List of SObjects to be inserted
  * @return List of inserted SObjects, in the same order as the input
  */
  List<SObject> doInsert(List<SObject> records);

  /**
  * Inserts a record and returns the SaveResult.
  *
  * @param record SObject to be inserted
  * @param allOrNone Must not be null. If true, the insert throws when the record fails. If false, the failure is returned as an unsuccessful SaveResult.
  * @return SaveResult
  */
  Database.SaveResult doInsert(SObject record, Boolean allOrNone);

  /**
  * Inserts a record wrapped in an Entry and returns the SaveResult.
  * The caller's entry is not modified; the generated Id is carried by the SaveResult.
  *
  * @param entry Entry containing the SObject to be inserted
  * @param allOrNone Must not be null. If true, the insert throws when the record fails. If false, the failure is returned as an unsuccessful SaveResult.
  * @return SaveResult
  */
  Database.SaveResult doInsert(IEntry entry, Boolean allOrNone);

  /**
  * Inserts a list of records and returns the SaveResults, in the same order as the input.
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * @param records List of SObjects to be inserted
  * @param allOrNone Must not be null. If true, the insert is rolled back if any record fails. If false, successful inserts are committed and errors are returned for failed records.
  * @return List of SaveResults, in the same order as the input
  */
  List<Database.SaveResult> doInsert(List<SObject> records, Boolean allOrNone);

  /**
  * Inserts a list of records wrapped in Entries and returns the SaveResults, in the same order as the input.
  * The caller's entries are not modified; the generated Ids are carried by the SaveResults.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be inserted
  * @param allOrNone Must not be null. If true, the insert is rolled back if any record fails. If false, successful inserts are committed and errors are returned for failed records.
  * @return List of SaveResults, in the same order as the input
  */
  List<Database.SaveResult> doInsert(List<IEntry> entries, Boolean allOrNone);

  /**
  * Inserts a record wrapped in an Entry. ⚠️ The caller's entry does NOT receive
  * the generated Id — read it from the returned Entry. (Holds as long as
  * getRecord() returns a defensive copy, as Entry and MockEntry do.)
  *
  * @param entry Entry containing the SObject to be inserted
  * @return New Entry wrapping the inserted record (Id populated)
  */
  IEntry doInsert(IEntry entry);

  /**
  * Inserts a list of records wrapped in Entries. ⚠️ The caller's entries do NOT
  * receive the generated Ids — read them from the returned Entries. (Holds as long
  * as getRecord() returns a defensive copy, as Entry and MockEntry do.)
  *
  * The returned list preserves the order of the input list.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be inserted
  * @return List of new Entries wrapping the inserted records, in the same order as the input
  */
  List<IEntry> doInsert(List<IEntry> entries);

  /**
  * Updates a record and returns the updated record.
  *
  * @param record SObject to be updated
  * @return Updated SObject
  */
  SObject doUpdate(SObject record);

  /**
  * Updates a record and returns the updated record.
  *
  * @param record SObject to be Updated
  * @param allOrNone Must not be null. If true, the update will be rolled back if any record fails. If false, successful updates will be committed and errors will be returned for failed records.  
  * @return SaveResult 
  */
  Database.SaveResult doUpdate(SObject record, Boolean allOrNone);

  /**
  * Updates a record wrapped in an Entry and returns the updated Entry.
  *
  * @param entry Entry containing the SObject to be updated
  * @return Updated Entry
  */
  IEntry doUpdate(IEntry entry);

  /**
  * Updates a record wrapped in an Entry and returns the updated Entry.
  *
  * @param entry Entry containing the SObject to be updated
  * @param allOrNone Must not be null. If true, the update will be rolled back if any record fails. If false, successful updates will be committed and errors will be returned for failed records.
  * @return SaveResult
  */
  Database.SaveResult doUpdate(IEntry entry, Boolean allOrNone);

  /**
  * Updates a list of records and returns the updated records.
  *
  * The returned list preserves the order of the input list.
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * @param records List of SObjects to be updated
  * @return List of updated SObjects, in the same order as the input
  */
  List<SObject> doUpdate(List<SObject> records);

  /**
  * Updates a list of records and returns the updated records.
  *
  * Results are returned in the same order as the input list: results[i] corresponds
  * to records[i]. When mixing multiple SObject types in one list, group records of
  * the same type together beforehand: Salesforce starts a new chunk at every type
  * switch and a single DML operation fails with more than 10 chunks.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param records List of SObjects to be updated
  * @param allOrNone Must not be null. If true, the update will be rolled back if any record fails. If false, successful updates will be committed and errors will be returned for failed records.
  * @return List of SaveResult, in the same order as the input
  */
  List<Database.SaveResult> doUpdate(List<SObject> records, Boolean allOrNone);

  /**
  * Updates a list of Entries and returns the updated Entries.
  *
  * The returned list preserves the order of the input list.
  * When mixing multiple SObject types in one list, group entries of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be updated
  * @return List of updated Entries, in the same order as the input
  */
  List<IEntry> doUpdate(List<IEntry> entries);

  /**
  * Updates a list of Entries and returns the updated Entries.
  *
  * Results are returned in the same order as the input list: results[i] corresponds
  * to entries[i]. When mixing multiple SObject types in one list, group entries of
  * the same type together beforehand: Salesforce starts a new chunk at every type
  * switch and a single DML operation fails with more than 10 chunks.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be updated
  * @param allOrNone Must not be null. If true, the update will be rolled back if any record fails. If false, successful updates will be committed and errors will be returned for failed records.
  * @return List of SaveResult, in the same order as the input
  */
  List<Database.SaveResult> doUpdate(List<IEntry> entries, Boolean allOrNone);

  /**
  * Inserts or updates a record and returns the upserted record.
  *
  * @param record SObject to be upserted
  * @return Upserted SObject
  */
  SObject doUpsert(SObject record);

  /**
  * Inserts or updates a record and returns the upserted record.
  *
  * @param record SObject to be upserted
  * @return Upserted SObject
  */
  IEntry doUpsert(IEntry entry);

  /**
  * Inserts or updates a list of records and returns the upserted records.
  *
  * The returned list preserves the order of the input list.
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * @param records List of SObjects to be upserted
  * @return List of upserted SObjects, in the same order as the input
  */
  List<SObject> doUpsert(List<SObject> records);

  /**
  * Inserts or updates a list of Entries and returns the upserted Entries.
  *
  * The returned list preserves the order of the input list.
  * When mixing multiple SObject types in one list, group entries of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be upserted
  * @return List of upserted Entries, in the same order as the input
  */
  List<IEntry> doUpsert(List<IEntry> entries);

  /**
  * Upserts a record (by Id) and returns the UpsertResult.
  *
  * @param record SObject to be upserted
  * @param allOrNone Must not be null. If true, the upsert throws when the record fails. If false, the failure is returned as an unsuccessful UpsertResult.
  * @return UpsertResult
  */
  Database.UpsertResult doUpsert(SObject record, Boolean allOrNone);

  /**
  * Upserts a record wrapped in an Entry (by Id) and returns the UpsertResult.
  * The caller's entry is not modified; a generated Id is carried by the UpsertResult.
  *
  * @param entry Entry containing the SObject to be upserted
  * @param allOrNone Must not be null. If true, the upsert throws when the record fails. If false, the failure is returned as an unsuccessful UpsertResult.
  * @return UpsertResult
  */
  Database.UpsertResult doUpsert(IEntry entry, Boolean allOrNone);

  /**
  * Upserts a list of records (by Id) and returns the UpsertResults, in the same order as the input.
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * @param records List of SObjects to be upserted
  * @param allOrNone Must not be null. If true, the upsert is rolled back if any record fails. If false, successful upserts are committed and errors are returned for failed records.
  * @return List of UpsertResults, in the same order as the input
  */
  List<Database.UpsertResult> doUpsert(List<SObject> records, Boolean allOrNone);

  /**
  * Upserts a list of records wrapped in Entries (by Id) and returns the UpsertResults, in the same order as the input.
  * The caller's entries are not modified; generated Ids are carried by the UpsertResults.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be upserted
  * @param allOrNone Must not be null. If true, the upsert is rolled back if any record fails. If false, successful upserts are committed and errors are returned for failed records.
  * @return List of UpsertResults, in the same order as the input
  */
  List<Database.UpsertResult> doUpsert(List<IEntry> entries, Boolean allOrNone);

  /**
  * Inserts or updates a record using the specified external Id field to match existing records.
  *
  * @param record SObject to be upserted
  * @param externalIdField External Id field to use for matching existing records
  * @param allOrNone Must not be null. If true, the upsert will be rolled back if any record fails. If false, successful upserts will be committed and errors will be returned for failed records.
  * @return UpsertResult
  */
  Database.UpsertResult doUpsertByExternalId(SObject record, Schema.SObjectField externalIdField, Boolean allOrNone);

  /**
  * Inserts or updates a record wrapped in an Entry using the specified external Id field to match existing records.
  *
  * @param entry Entry containing the SObject to be upserted
  * @param externalIdField External Id field to use for matching existing records
  * @param allOrNone Must not be null. If true, the upsert will be rolled back if any record fails. If false, successful upserts will be committed and errors will be returned for failed records.
  * @return UpsertResult
  */
  Database.UpsertResult doUpsertByExternalId(IEntry entry, Schema.SObjectField externalIdField, Boolean allOrNone);

  /**
  * Inserts or updates a list of records using the specified external Id field to match existing records.
  *
  * Results are returned in the same order as the input list: results[i] corresponds
  * to records[i]. When mixing multiple SObject types in one list, group records of
  * the same type together beforehand: Salesforce starts a new chunk at every type
  * switch and a single DML operation fails with more than 10 chunks.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param records List of SObjects to be upserted
  * @param externalIdField External Id field to use for matching existing records
  * @param allOrNone Must not be null. If true, the upsert will be rolled back if any record fails. If false, successful upserts will be committed and errors will be returned for failed records.
  * @return List of UpsertResult, in the same order as the input
  */
  List<Database.UpsertResult> doUpsertByExternalId(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone);

  /**
  * Inserts or updates a list of Entries using the specified external Id field to match existing records.
  *
  * Results are returned in the same order as the input list: results[i] corresponds
  * to entries[i]. When mixing multiple SObject types in one list, group entries of
  * the same type together beforehand: Salesforce starts a new chunk at every type
  * switch and a single DML operation fails with more than 10 chunks.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be upserted
  * @param externalIdField External Id field to use for matching existing records
  * @param allOrNone Must not be null. If true, the upsert will be rolled back if any record fails. If false, successful upserts will be committed and errors will be returned for failed records.
  * @return List of UpsertResult, in the same order as the input
  */
  List<Database.UpsertResult> doUpsertByExternalId(List<IEntry> entries, Schema.SObjectField externalIdField, Boolean allOrNone);

  /**
  * Deletes a record.
  *
  * @param record SObject to be deleted
  */
  void doDelete(SObject record);

  /**
  * Deletes a record wrapped in an Entry.
  *
  * @param entry Entry containing the SObject to be deleted
  */
  void doDelete(IEntry entry);

  /**
  * Deletes a list of records.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param records List of SObjects to be deleted
  */
  void doDelete(List<SObject> records);

  /**
  * Deletes a list of Entries.
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be deleted
  */
  void doDelete(List<IEntry> entries);

  /**
  * Deletes a record and returns the DeleteResult.
  *
  * A record without an Id makes the call throw even with allOrNone = false —
  * the platform rejects the input before processing any row (measured on API v67.0).
  *
  * @param record SObject to be deleted
  * @param allOrNone Must not be null. If true, the delete throws when the record fails. If false, the failure is returned as an unsuccessful DeleteResult.
  * @return DeleteResult
  */
  Database.DeleteResult doDelete(SObject record, Boolean allOrNone);

  /**
  * Deletes a record wrapped in an Entry and returns the DeleteResult.
  *
  * A record without an Id makes the call throw even with allOrNone = false —
  * the platform rejects the input before processing any row (measured on API v67.0).
  *
  * @param entry Entry containing the SObject to be deleted
  * @param allOrNone Must not be null. If true, the delete throws when the record fails. If false, the failure is returned as an unsuccessful DeleteResult.
  * @return DeleteResult
  */
  Database.DeleteResult doDelete(IEntry entry, Boolean allOrNone);

  /**
  * Deletes a list of records and returns the DeleteResults, in the same order as the input.
  *
  * Records without an Id make the whole call throw even with allOrNone = false —
  * the platform rejects the list before processing any row (measured on API v67.0).
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param records List of SObjects to be deleted
  * @param allOrNone Must not be null. If true, the delete is rolled back if any record fails. If false, successful deletes are committed and errors are returned for failed records.
  * @return List of DeleteResults, in the same order as the input
  */
  List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone);

  /**
  * Deletes a list of records wrapped in Entries and returns the DeleteResults, in the same order as the input.
  *
  * Records without an Id make the whole call throw even with allOrNone = false —
  * the platform rejects the list before processing any row (measured on API v67.0).
  *
  * A null element in the list makes the whole call throw — the platform
  * rejects the list before processing any row (measured on API v67.0).
  *
  * When mixing multiple SObject types in one list, group records of the same type
  * together beforehand: Salesforce starts a new chunk at every type switch and
  * a single DML operation fails with more than 10 chunks (System.TypeException,
  * measured on API v67.0). MockEloquent does NOT reproduce this limit — grouping
  * by type stays the caller's responsibility and cannot be verified by unit tests.
  *
  * @param entries List of Entries containing the SObjects to be deleted
  * @param allOrNone Must not be null. If true, the delete is rolled back if any record fails. If false, successful deletes are committed and errors are returned for failed records.
  * @return List of DeleteResults, in the same order as the input
  */
  List<Database.DeleteResult> doDelete(List<IEntry> entries, Boolean allOrNone);
}
