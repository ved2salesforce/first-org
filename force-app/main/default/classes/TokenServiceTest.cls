/**
 * @description Test class for TokenService. Targets ≥90 % coverage.
 */
@IsTest
private class TokenServiceTest {
  @TestSetup
  static void setup() {
    Account acc = TestDataFactory.createAccount(true);
    TestDataFactory.createToken(acc.Id, 'Active', 30, true);
    TestDataFactory.createToken(acc.Id, 'Revoked', 30, true);
  }

  // ─── issueToken ───────────────────────────────────────────────────────────

  @IsTest
  static void issueToken_happyPath_createsToken() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    TokenService svc = new TokenService();
    Token__c token = svc.issueToken(
      acc.Id,
      Date.today().addDays(10),
      'read:write'
    );
    Test.stopTest();
    Assert.isNotNull(token.Id, 'Token should have been inserted');
    Assert.areEqual('Active', token.Status__c);
  }

  @IsTest
  static void issueToken_nullAccount_throwsException() {
    Test.startTest();
    TokenService svc = new TokenService();
    try {
      svc.issueToken(null, Date.today().addDays(10), 'read');
      Assert.fail('Expected TokenServiceException');
    } catch (TokenService.TokenServiceException e) {
      Assert.isTrue(
        e.getMessage().contains('Account ID'),
        'Wrong message: ' + e.getMessage()
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void issueToken_expiryTodayOrPast_throwsException() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    TokenService svc = new TokenService();
    try {
      svc.issueToken(acc.Id, Date.today(), 'read');
      Assert.fail('Expected TokenServiceException');
    } catch (TokenService.TokenServiceException e) {
      Assert.isTrue(
        e.getMessage().contains('Expiry'),
        'Wrong message: ' + e.getMessage()
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void issueToken_blankScope_throwsException() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    TokenService svc = new TokenService();
    try {
      svc.issueToken(acc.Id, Date.today().addDays(5), '');
      Assert.fail('Expected TokenServiceException');
    } catch (TokenService.TokenServiceException e) {
      Assert.isTrue(
        e.getMessage().contains('Scope'),
        'Wrong message: ' + e.getMessage()
      );
    }
    Test.stopTest();
  }

  // ─── revokeToken ─────────────────────────────────────────────────────────

  @IsTest
  static void revokeToken_happyPath_setsRevoked() {
    Token__c active = [
      SELECT Id
      FROM Token__c
      WHERE Status__c = 'Active'
      LIMIT 1
    ];
    Test.startTest();
    TokenService svc = new TokenService();
    svc.revokeToken(active.Id);
    Test.stopTest();
    Token__c updated = [SELECT Status__c FROM Token__c WHERE Id = :active.Id];
    Assert.areEqual('Revoked', updated.Status__c);
  }

  @IsTest
  static void revokeToken_alreadyRevoked_throwsException() {
    Token__c revoked = [
      SELECT Id
      FROM Token__c
      WHERE Status__c = 'Revoked'
      LIMIT 1
    ];
    Test.startTest();
    TokenService svc = new TokenService();
    try {
      svc.revokeToken(revoked.Id);
      Assert.fail('Expected TokenServiceException');
    } catch (TokenService.TokenServiceException e) {
      Assert.isTrue(
        e.getMessage().contains('already revoked'),
        'Wrong message: ' + e.getMessage()
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void revokeToken_nullId_throwsException() {
    Test.startTest();
    TokenService svc = new TokenService();
    try {
      svc.revokeToken(null);
      Assert.fail('Expected TokenServiceException');
    } catch (TokenService.TokenServiceException e) {
      Assert.isTrue(
        e.getMessage().contains('Token ID'),
        'Wrong message: ' + e.getMessage()
      );
    }
    Test.stopTest();
  }

  // ─── expireTokens ────────────────────────────────────────────────────────

  @IsTest
  static void expireTokens_bulk_setsExpired() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    List<Token__c> tokens = TestDataFactory.createTokens(
      acc.Id,
      5,
      'Active',
      true
    );
    Test.startTest();
    TokenService svc = new TokenService();
    List<Database.SaveResult> results = svc.expireTokens(tokens);
    Test.stopTest();
    Assert.areEqual(5, results.size(), 'Expected 5 save results');
    for (Database.SaveResult sr : results) {
      Assert.isTrue(
        sr.isSuccess(),
        'Each record should have been updated successfully'
      );
    }
  }

  @IsTest
  static void expireTokens_emptyList_returnsEmpty() {
    Test.startTest();
    TokenService svc = new TokenService();
    List<Database.SaveResult> results = svc.expireTokens(new List<Token__c>());
    Test.stopTest();
    Assert.areEqual(
      0,
      results.size(),
      'Empty input should return empty results'
    );
  }

  @IsTest
  static void expireTokens_nullList_returnsEmpty() {
    Test.startTest();
    TokenService svc = new TokenService();
    List<Database.SaveResult> results = svc.expireTokens(null);
    Test.stopTest();
    Assert.areEqual(
      0,
      results.size(),
      'Null input should return empty results'
    );
  }

  // ─── AuraEnabled wrappers ─────────────────────────────────────────────────

  @IsTest
  static void issueTokenAura_success_returnsToken() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    Token__c token = TokenService.issueTokenAura(
      acc.Id,
      String.valueOf(Date.today().addDays(10)),
      'read'
    );
    Test.stopTest();
    Assert.isNotNull(token.Id, 'Token should have been created');
  }

  @IsTest
  static void issueTokenAura_invalidInput_throwsAuraHandledException() {
    Test.startTest();
    try {
      TokenService.issueTokenAura(
        null,
        String.valueOf(Date.today().addDays(1)),
        'read'
      );
      Assert.fail('Expected AuraHandledException');
    } catch (AuraHandledException e) {
      Assert.isNotNull(e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void revokeTokenAura_success() {
    Token__c active = [
      SELECT Id
      FROM Token__c
      WHERE Status__c = 'Active'
      LIMIT 1
    ];
    Test.startTest();
    TokenService.revokeTokenAura(active.Id);
    Test.stopTest();
    Token__c updated = [SELECT Status__c FROM Token__c WHERE Id = :active.Id];
    Assert.areEqual('Revoked', updated.Status__c);
  }

  @IsTest
  static void revokeTokenAura_alreadyRevoked_throwsAuraHandledException() {
    Token__c revoked = [
      SELECT Id
      FROM Token__c
      WHERE Status__c = 'Revoked'
      LIMIT 1
    ];
    Test.startTest();
    try {
      TokenService.revokeTokenAura(revoked.Id);
      Assert.fail('Expected AuraHandledException');
    } catch (AuraHandledException e) {
      Assert.isNotNull(e.getMessage());
    }
    Test.stopTest();
  }
}
