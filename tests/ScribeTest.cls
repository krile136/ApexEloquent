@isTest(seeAllData=false)
public with sharing class ScribeTest {
  @isTest
  public static void testScribeIsImmutableTest() {
    // Arrange
    Scribe scribeOriginal = Scribe.source(Account.getSObjectType());

    // Act
    Scribe scribeAfterAddingId = scribeOriginal.field('Id');

    // Assert
    Assert.areEqual(0, scribeOriginal.selectFields.size());
    Assert.areEqual(1, scribeAfterAddingId.selectFields.size());

    // Additional Act
    Scribe scribeAfterAddingName = scribeAfterAddingId.field('Name');
    scribeOriginal = scribeOriginal.fields(new List<String>{'Name', 'StageName', 'CloseDate'});

    // Additional Assert
    Assert.areEqual(3, scribeOriginal.selectFields.size());
    Assert.areEqual(1, scribeAfterAddingId.selectFields.size());
    Assert.areEqual(2, scribeAfterAddingName.selectFields.size());
  }
}
