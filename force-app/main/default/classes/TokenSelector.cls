/**
 * @description Selector class for Token__c records. All queries execute with
 *              USER_MODE to enforce FLS and CRUD automatically.
 */
public inherited sharing class TokenSelector {
  /**
   * @description Returns tokens belonging to the given account IDs.
   * @param accountIds Set of Account record IDs.
   * @return List of Token__c records.
   */
  public List<Token__c> selectByAccount(Set<Id> accountIds) {
    if (accountIds == null || accountIds.isEmpty()) {
      return new List<Token__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Status__c,
        Issued_Date__c,
        Expiry_Date__c,
        Owner_Account__c,
        Scope__c
      FROM Token__c
      WHERE Owner_Account__c IN :accountIds
      WITH USER_MODE
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * @description Returns tokens whose Status__c is in the provided set.
   * @param statuses Set of status picklist values.
   * @return List of Token__c records.
   */
  public List<Token__c> selectByStatus(Set<String> statuses) {
    if (statuses == null || statuses.isEmpty()) {
      return new List<Token__c>();
    }
    return [
      SELECT
        Id,
        Name,
        Status__c,
        Issued_Date__c,
        Expiry_Date__c,
        Owner_Account__c,
        Scope__c
      FROM Token__c
      WHERE Status__c IN :statuses
      WITH USER_MODE
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * @description Returns Active tokens expiring within the specified number of days.
   * @param days Number of days from today to look ahead.
   * @return List of Token__c records.
   */
  public List<Token__c> selectExpiringWithinDays(Integer days) {
    if (days == null || days < 0) {
      return new List<Token__c>();
    }
    Date cutoff = Date.today().addDays(days);
    return [
      SELECT
        Id,
        Name,
        Status__c,
        Issued_Date__c,
        Expiry_Date__c,
        Owner_Account__c,
        Scope__c
      FROM Token__c
      WHERE Status__c = 'Active' AND Expiry_Date__c <= :cutoff
      WITH USER_MODE
      ORDER BY Expiry_Date__c ASC
    ];
  }

  /**
   * @description AuraEnabled cacheable wrapper to fetch tokens by account ID for LWC wire.
   * @param accountId The Account record ID.
   * @return List of Token__c records.
   */
  @AuraEnabled(cacheable=true)
  public static List<Token__c> getTokensByAccount(Id accountId) {
    if (accountId == null) {
      return new List<Token__c>();
    }
    TokenSelector selector = new TokenSelector();
    return selector.selectByAccount(new Set<Id>{ accountId });
  }
}
