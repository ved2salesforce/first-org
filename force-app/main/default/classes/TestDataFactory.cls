/**
 * @description Shared test data factory used by all Apex test classes.
 *              All factory methods are centralised here so test classes contain
 *              no inline SObject construction.
 */
@IsTest
public with sharing class TestDataFactory {
  /**
   * @description Creates a single Account record.
   * @param doInsert When true the record is inserted before being returned.
   * @return The Account record.
   */
  public static Account createAccount(Boolean doInsert) {
    Account acc = new Account(
      Name = 'Test Account ' + System.currentTimeMillis()
    );
    if (doInsert) {
      insert acc;
    }
    return acc;
  }

  /**
   * @description Creates a single Token__c record.
   * @param accountId Owner Account ID.
   * @param status    Status picklist value (Active, Expired, Revoked).
   * @param daysUntilExpiry Number of days from today for Expiry_Date__c.
   * @param doInsert  When true the record is inserted before being returned.
   * @return The Token__c record.
   */
  public static Token__c createToken(
    Id accountId,
    String status,
    Integer daysUntilExpiry,
    Boolean doInsert
  ) {
    Token__c token = new Token__c(
      Owner_Account__c = accountId,
      Status__c = status,
      Issued_Date__c = Date.today(),
      Expiry_Date__c = Date.today().addDays(daysUntilExpiry),
      Scope__c = 'read:all'
    );
    if (doInsert) {
      insert token;
    }
    return token;
  }

  /**
   * @description Creates multiple Token__c records with the same status.
   * @param accountId Owner Account ID.
   * @param count     Number of tokens to create.
   * @param status    Status picklist value.
   * @param doInsert  When true the records are inserted before being returned.
   * @return List of Token__c records.
   */
  public static List<Token__c> createTokens(
    Id accountId,
    Integer count,
    String status,
    Boolean doInsert
  ) {
    List<Token__c> tokens = new List<Token__c>();
    for (Integer i = 0; i < count; i++) {
      tokens.add(
        new Token__c(
          Owner_Account__c = accountId,
          Status__c = status,
          Issued_Date__c = Date.today(),
          Expiry_Date__c = Date.today().addDays(i + 1),
          Scope__c = 'scope:' + i
        )
      );
    }
    if (doInsert) {
      insert tokens;
    }
    return tokens;
  }
}
