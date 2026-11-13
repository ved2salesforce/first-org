/**
 * @description Test class for TokenSelector. Targets ≥90 % coverage.
 */
@IsTest
private class TokenSelectorTest {
  @TestSetup
  static void setup() {
    Account acc = TestDataFactory.createAccount(true);
    TestDataFactory.createTokens(acc.Id, 3, 'Active', true);
    TestDataFactory.createToken(acc.Id, 'Expired', -5, true);
    TestDataFactory.createToken(acc.Id, 'Revoked', -10, true);
  }

  // ─── selectByAccount ─────────────────────────────────────────────────────

  @IsTest
  static void selectByAccount_returnsTokensForAccount() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectByAccount(new Set<Id>{ acc.Id });
    Test.stopTest();
    Assert.isTrue(
      tokens.size() >= 5,
      'Expected at least 5 tokens for the account'
    );
  }

  @IsTest
  static void selectByAccount_emptySet_returnsEmpty() {
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectByAccount(new Set<Id>());
    Test.stopTest();
    Assert.areEqual(0, tokens.size(), 'Empty input should return empty list');
  }

  @IsTest
  static void selectByAccount_nullSet_returnsEmpty() {
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectByAccount(null);
    Test.stopTest();
    Assert.areEqual(0, tokens.size(), 'Null input should return empty list');
  }

  // ─── selectByStatus ──────────────────────────────────────────────────────

  @IsTest
  static void selectByStatus_active_returnsActiveTokens() {
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectByStatus(new Set<String>{ 'Active' });
    Test.stopTest();
    Assert.isTrue(tokens.size() >= 3, 'Expected at least 3 active tokens');
    for (Token__c t : tokens) {
      Assert.areEqual('Active', t.Status__c);
    }
  }

  @IsTest
  static void selectByStatus_emptySet_returnsEmpty() {
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectByStatus(new Set<String>());
    Test.stopTest();
    Assert.areEqual(
      0,
      tokens.size(),
      'Empty statuses should return empty list'
    );
  }

  @IsTest
  static void selectByStatus_null_returnsEmpty() {
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectByStatus(null);
    Test.stopTest();
    Assert.areEqual(0, tokens.size(), 'Null statuses should return empty list');
  }

  // ─── selectExpiringWithinDays ─────────────────────────────────────────────

  @IsTest
  static void selectExpiringWithinDays_returnsTokensExpiringSoon() {
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectExpiringWithinDays(10);
    Test.stopTest();
    Assert.isTrue(
      tokens.size() >= 1,
      'Expected tokens expiring within 10 days'
    );
  }

  @IsTest
  static void selectExpiringWithinDays_negativeDays_returnsEmpty() {
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectExpiringWithinDays(-1);
    Test.stopTest();
    Assert.areEqual(0, tokens.size(), 'Negative days should return empty list');
  }

  @IsTest
  static void selectExpiringWithinDays_null_returnsEmpty() {
    Test.startTest();
    TokenSelector sel = new TokenSelector();
    List<Token__c> tokens = sel.selectExpiringWithinDays(null);
    Test.stopTest();
    Assert.areEqual(0, tokens.size(), 'Null days should return empty list');
  }

  // ─── getTokensByAccount (AuraEnabled wrapper) ─────────────────────────────

  @IsTest
  static void getTokensByAccount_returnsTokens() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Test.startTest();
    List<Token__c> tokens = TokenSelector.getTokensByAccount(acc.Id);
    Test.stopTest();
    Assert.isTrue(tokens.size() >= 1, 'Expected tokens for the account');
  }

  @IsTest
  static void getTokensByAccount_nullId_returnsEmpty() {
    Test.startTest();
    List<Token__c> tokens = TokenSelector.getTokensByAccount(null);
    Test.stopTest();
    Assert.areEqual(
      0,
      tokens.size(),
      'Null account ID should return empty list'
    );
  }
}
