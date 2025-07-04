@isTest
public with sharing class FieldStructure_T {
  @isTest
  static void testConstructor_WhenNoArguments_ThenInstanceCreated() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure();

    // Act & Assert
    Assert.isNotNull(fieldStructure, 'FieldStructure instance should be created');
  }

  @isTest
  static void testConstructor_WhenWithFieldsArgument_ThenInstanceCreatedWithFields() {
    // Arrange
    List<String> fields = new List<String>{ 'Id', 'Name' };
    FieldStructure fieldStructure = new FieldStructure(fields);

    // Act & Assert
    Assert.isNotNull(fieldStructure, 'FieldStructure instance should be created');
  }

  @isTest
  static void testConstructor_WhenWithFieldsAndRelations_ThenInstanceCreatedWithFieldsAndRelations() {
    // Arrange
    List<String> fields = new List<String>{ 'Id', 'Name' };
    Map<String, FieldStructure> relations = new Map<String, FieldStructure>{
      'AccountId' => new FieldStructure(new List<String>{ 'Id', 'Name' })
    };
    FieldStructure fieldStructure = new FieldStructure(fields, relations);

    // Act & Assert
    Assert.isNotNull(fieldStructure, 'FieldStructure instance should be created with fields and relations');
  }

  @isTest
  static void testHasField_WhenFieldExists_ThenReturnsTrue() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'Id', 'Name' });

    // Act
    Boolean hasField = fieldStructure.hasField('Id');

    // Assert
    Assert.isTrue(hasField, 'FieldStructure should have field Id');
  }

  @isTest
  static void testHasRelation_WhenHasRelation_ThenReturnsTrue() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'Id', 'Name' }, 
      new Map<String, FieldStructure>{
        'AccountId' => new FieldStructure(new List<String>{ 'Id', 'Name' })
      });

    // Act / Assert
    Assert.isTrue(fieldStructure.hasRelation(), 'FieldStructure should have relation');
    Assert.isTrue(fieldStructure.hasRelation('AccountId'), 'FieldStructure should have relation Account');
  }

  @isTest
  static void testGetFieldCount_WhenFieldsExist_ThenReturnsCorrectCount() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'Id', 'Name', 'CreatedDate' });

    // Act
    Integer fieldCount = fieldStructure.getFieldCount();

    // Assert
    Assert.areEqual(3, fieldCount, 'Field count should be 3');
  }

  @isTest
  static void testGetRelationFieldStructure_WhenRelationExists_ThenReturnsFieldStructure() {
    // Arrange
    FieldStructure fieldStructure = new FieldStructure(new List<String>{ 'Id', 'Name' }, 
      new Map<String, FieldStructure>{
        'AccountId' => new FieldStructure(new List<String>{ 'Id', 'Name' })
      });

    // Act
    FieldStructure relationFieldStructure = fieldStructure.getRelationFieldStructure('AccountId');

    // Assert
    Assert.isNotNull(relationFieldStructure, 'Should return FieldStructure for AccountId relation');
    Assert.isTrue(relationFieldStructure.hasField('Id'), 'Relation should have field Id');
  }
}
