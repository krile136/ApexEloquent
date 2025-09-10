@isTest
public class NotInSubQueryConditionClauseTest {
  @isTest
  static void testBuild_WhenSubQueryIsValid_ThenReturnsNotInSubQueryClause() {
    // Arrange
    Schema.SObjectType mainSObjectType = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> mainFieldMap = mainSObjectType.getDescribe().fields.getMap();

    // Create the Scribe instance for the subquery
    Scribe subQueryScribe = Scribe.source(Account.getSObjectType())
      .field('Id')
      .whereEqual('Industry', 'Technology');

    IConditionClause clause = new NotInSubQueryConditionClause(
      mainSObjectType,
      mainFieldMap,
      'AccountId',
      subQueryScribe
    );

    // Act
    String result = clause.build();

    // Assert
    String expected = 'AccountId NOT IN (SELECT id FROM Account WHERE Industry = \'Technology\')';
    Assert.areEqual(expected, result, 'The clause should correctly format the NOT IN subquery condition.');
  }

  @isTest
  static void testImmutability_WhenOverrideMetaData_ThenReturnsNewInstance() {
    // Arrange
    Scribe subQueryScribe = Scribe.source(Account.getSObjectType()).field('Id');
    Schema.SObjectType originalSObjectType = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> originalFieldMap = originalSObjectType.getDescribe().fields.getMap();

    IConditionClause originalClause = new NotInSubQueryConditionClause(
      originalSObjectType,
      originalFieldMap,
      'AccountId',
      subQueryScribe
    );

    // Act
    Schema.SObjectType newSObjectType = Contact.getSObjectType();
    Map<String, Schema.SObjectField> newFieldMap = newSObjectType.getDescribe().fields.getMap();
    IConditionClause newClause = originalClause.overrideMetaData(newSObjectType, newFieldMap);

    // Assert
    Assert.areNotEqual(originalClause, newClause, 'A new instance should be returned.');
    Assert.isTrue(
      originalClause.build().startsWith('AccountId NOT IN'),
      'Original instance should not be modified.'
    );
  }

  @isTest
  static void testImmutability_WhenOverrideField_ThenReturnsNewInstanceWithNewField() {
    // Arrange
    Scribe subQueryScribe = Scribe.source(Account.getSObjectType()).field('Id');
    Schema.SObjectType sObjectType = Opportunity.getSObjectType();
    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();

    IConditionClause originalClause = new NotInSubQueryConditionClause(
      sObjectType,
      fieldMap,
      'AccountId',
      subQueryScribe
    );

    // Act
    IConditionClause newClause = originalClause.overrideField('PrimaryPartnerAccountId');

    // Assert
    Assert.areNotEqual(originalClause, newClause, 'A new instance should be returned.');
    Assert.isTrue(
      originalClause.build().startsWith('AccountId NOT IN'),
      'Original instance should not be modified.'
    );
    Assert.isTrue(
      newClause.build().startsWith('PrimaryPartnerAccountId NOT IN'),
      'New instance should reflect the overridden field name.'
    );
  }
}
