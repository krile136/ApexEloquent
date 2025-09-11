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
 */
public interface IEloquent {
  /**
  * Executes SOQL and retrieves the results.
  * If the number of retrieved records is 0, an empty list is returned.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved results as a list of Entry objects
  */
  List<IEntry> get(Scribe scribe);

  /**
  * Executes SOQL and retrieves the aggregate results.
  * If the number of retrieved records is 0, an empty list is returned.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved aggregate results as a list of Entry objects
  */
  List<IEntry> getAggregate(Scribe scribe);

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
  * Executes SOQL and returns the first record as SObject.
  * If the number of retrieved records is 0, an exception is thrown.
  *
  * @param Scribe scribe: Scribe instance containing the SOQL query
  * @return Retrieved result as an SObject
  * @throws QueryException If the number of retrieved records is 0
  */
  SObject firstOrFailAsSObject(Scribe scribe) ;

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
  * @param records List of SObjects to be inserted
  * @return List of inserted SObjects
  */
  List<SObject> doInsert(List<SObject> records);

  /**
  * Updates a record and returns the updated record.
  *
  * @param record SObject to be updated
  * @return Updated SObject
  */
  SObject doUpdate(SObject record);

  /**
  * Updates a list of records and returns the updated records.
  *
  * @param records List of SObjects to be updated
  * @return List of updated SObjects
  */
  List<SObject> doUpdate(List<SObject> records);

  /**
  * Deletes a record.
  *
  * @param record SObject to be deleted
  */
  void doDelete(SObject record);

  /**
  * Deletes a list of records.
  *
  * @param records List of SObjects to be deleted
  */
  void doDelete(List<SObject> records);
}
