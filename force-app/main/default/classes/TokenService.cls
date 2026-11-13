/**
 * @description Service class for Token__c business logic. Enforces sharing rules
 *              and rethrows domain exceptions as AuraHandledException for LWC callers.
 */
public with sharing class TokenService {
  /**
   * @description Custom exception for token domain errors.
   */
  public class TokenServiceException extends Exception {
  }

  /**
   * @description Issues a new Token for the given account.
   * @param accountId The Account record ID.
   * @param expiryDate The expiry date; must be after today.
   * @param scope The token scope string.
   * @return The newly created Token__c record.
   */
  public Token__c issueToken(Id accountId, Date expiryDate, String scope) {
    if (accountId == null) {
      throw new TokenServiceException('Account ID is required.');
    }
    if (expiryDate == null || expiryDate <= Date.today()) {
      throw new TokenServiceException('Expiry date must be after today.');
    }
    if (String.isBlank(scope)) {
      throw new TokenServiceException('Scope is required.');
    }

    Token__c token = new Token__c(
      Owner_Account__c = accountId,
      Issued_Date__c = Date.today(),
      Expiry_Date__c = expiryDate,
      Scope__c = scope,
      Status__c = 'Active'
    );
    insert as user token;
    return token;
  }

  /**
   * @description Revokes a single Token__c record.
   * @param tokenId The Token__c record ID.
   */
  public void revokeToken(Id tokenId) {
    if (tokenId == null) {
      throw new TokenServiceException('Token ID is required.');
    }
    List<Token__c> tokens = [
      SELECT Id, Status__c
      FROM Token__c
      WHERE Id = :tokenId
      WITH USER_MODE
      LIMIT 1
    ];
    if (tokens.isEmpty()) {
      throw new TokenServiceException('Token not found.');
    }
    Token__c token = tokens[0];
    if (token.Status__c == 'Revoked') {
      throw new TokenServiceException('Token is already revoked.');
    }
    token.Status__c = 'Revoked';
    update as user token;
  }

  /**
   * @description Bulk-expires a list of tokens using partial-success DML.
   * @param tokens List of Token__c records to expire.
   * @return List of Database.SaveResult containing per-record outcomes.
   */
  public List<Database.SaveResult> expireTokens(List<Token__c> tokens) {
    if (tokens == null || tokens.isEmpty()) {
      return new List<Database.SaveResult>();
    }
    List<Token__c> toUpdate = new List<Token__c>();
    for (Token__c t : tokens) {
      toUpdate.add(new Token__c(Id = t.Id, Status__c = 'Expired'));
    }
    return Database.update(toUpdate, false, AccessLevel.USER_MODE);
  }

  // ─── AuraEnabled entry points ────────────────────────────────────────────

  /**
   * @description AuraEnabled wrapper for issueToken.
   * @param accountId Account record ID.
   * @param expiryDateStr ISO date string (yyyy-MM-dd).
   * @param scope Token scope.
   * @return The created Token__c.
   */
  @AuraEnabled
  public static Token__c issueTokenAura(
    Id accountId,
    String expiryDateStr,
    String scope
  ) {
    try {
      Date expiryDate = Date.valueOf(expiryDateStr);
      TokenService svc = new TokenService();
      return svc.issueToken(accountId, expiryDate, scope);
    } catch (TokenServiceException e) {
      throw new AuraHandledException(e.getMessage());
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'issueTokenAura unexpected error: ' + e.getMessage() + '\n' + e.getStackTraceString());
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description AuraEnabled wrapper for revokeToken.
   * @param tokenId Token__c record ID.
   */
  @AuraEnabled
  public static void revokeTokenAura(Id tokenId) {
    try {
      TokenService svc = new TokenService();
      svc.revokeToken(tokenId);
    } catch (TokenServiceException e) {
      throw new AuraHandledException(e.getMessage());
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'revokeTokenAura unexpected error: ' + e.getMessage() + '\n' + e.getStackTraceString());
      throw new AuraHandledException(e.getMessage());
    }
  }
}
