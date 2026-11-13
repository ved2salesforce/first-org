/**
 * @description Test class for TokenExpiryBatch. Targets ≥90 % coverage.
 */
@IsTest
private class TokenExpiryBatchTest {
  @TestSetup
  static void setup() {
    Account acc = TestDataFactory.createAccount(true);
    // Active tokens that have already expired (negative daysUntilExpiry)
    List<Token__c> expired = new List<Token__c>();
    for (Integer i = 1; i <= 5; i++) {
      expired.add(TestDataFactory.createToken(acc.Id, 'Active', -i, false));
    }
    insert expired;
    // Active token that is NOT expired yet
    TestDataFactory.createToken(acc.Id, 'Active', 30, true);
  }

  // ─── Batch start/execute/finish ───────────────────────────────────────────

  @IsTest
  static void batch_expiresOverdueActiveTokens() {
    Test.startTest();
    Database.executeBatch(new TokenExpiryBatch(), 200);
    Test.stopTest();
    List<Token__c> stillActive = [
      SELECT Id
      FROM Token__c
      WHERE Status__c = 'Active' AND Expiry_Date__c < TODAY
    ];
    Assert.areEqual(
      0,
      stillActive.size(),
      'All overdue active tokens should be expired'
    );
  }

  @IsTest
  static void batch_doesNotExpireFutureTokens() {
    Test.startTest();
    Database.executeBatch(new TokenExpiryBatch(), 200);
    Test.stopTest();
    List<Token__c> futureActive = [
      SELECT Id
      FROM Token__c
      WHERE Status__c = 'Active' AND Expiry_Date__c >= TODAY
    ];
    Assert.areEqual(
      1,
      futureActive.size(),
      'Token with future expiry should remain Active'
    );
  }

  // ─── Schedulable execute ─────────────────────────────────────────────────

  @IsTest
  static void schedulable_executesWithoutError() {
    Test.startTest();
    String jobId = System.schedule(
      'TestTokenExpiryBatch_' + System.currentTimeMillis(),
      '0 0 1 * * ?',
      new TokenExpiryBatch()
    );
    Test.stopTest();
    Assert.isNotNull(jobId, 'Schedule should return a job ID');
  }

  // ─── Static helpers ───────────────────────────────────────────────────────

  @IsTest
  static void scheduleDaily_returnsJobId() {
    Test.startTest();
    String jobId = TokenExpiryBatch.scheduleDaily();
    Test.stopTest();
    Assert.isNotNull(jobId, 'scheduleDaily should return a job ID');
  }

  @IsTest
  static void run_returnsBatchId() {
    Test.startTest();
    Id batchId = TokenExpiryBatch.run();
    Test.stopTest();
    Assert.isNotNull(batchId, 'run() should return a batch job ID');
  }
}
