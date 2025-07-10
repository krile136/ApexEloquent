@isTest(seeAllData=false)
public with sharing class OrderByClause_T {
  @isTest
  static void testBuild_WhenSingleFieldAscending_ThenCorrectOrderByClause() {
    // Arrange
    OrderByClause clause = new OrderByClause('Name');

    // Act
    String result = clause.build();

    // Assert
    String expected = 'ORDER BY Name ASC';
    Assert.areEqual(expected, result);
  }

  @isTest
  static void testBuild_WhenSingleFieldDescending_ThenCorrectOrderByClause() {
    // Arrange
    OrderByClause clause = new OrderByClause('Name', 'DESC');

    // Act
    String result = clause.build();

    // Assert
    String expected = 'ORDER BY Name DESC';
    Assert.areEqual(expected, result);
  }

  @isTest
  static void testBuild_WhenSingleFieldNullsFirst_ThenCorrectOrderByClause() {
    // Arrange
    OrderByClause clause = new OrderByClause('Name', 'ASC', 'FIRST');

    // Act
    String result = clause.build();

    // Assert
    String expected = 'ORDER BY Name ASC NULLS FIRST';
    Assert.areEqual(expected, result);
  }

  @isTest
  static void testBuild_WhenMultipleFieldsAscending_ThenCorrectOrderByClause() {
    // Arrange
    OrderByClause clause = new OrderByClause(new List<String>{ 'Name', 'Id' });

    // Act
    String result = clause.build();

    // Assert
    String expected = 'ORDER BY Name, Id ASC';
    Assert.areEqual(expected, result);
  }

  @isTest
  static void testBuild_WhenMultipleFieldsDescending_ThenCorrectOrderByClause() {
    // Arrange
    OrderByClause clause = new OrderByClause(new List<String>{ 'Name', 'Id' }, 'DESC');

    // Act
    String result = clause.build();

    // Assert
    String expected = 'ORDER BY Name, Id DESC';
    Assert.areEqual(expected, result);
  }

  @isTest
  static void testBuild_WhenMultipleFieldsNullsLast_ThenCorrectOrderByClause() {
    // Arrange
    OrderByClause clause = new OrderByClause(new List<String>{ 'Name', 'Id' }, 'ASC', 'LAST');

    // Act
    String result = clause.build();

    // Assert
    String expected = 'ORDER BY Name, Id ASC NULLS LAST';
    Assert.areEqual(expected, result);
  }
}
