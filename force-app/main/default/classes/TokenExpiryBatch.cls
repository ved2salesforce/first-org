/**
 * @description Batch job that expires Active Token__c records past their expiry date.
 *              Also implements Schedulable so it can be scheduled via cron.
 */
public with sharing class TokenExpiryBatch implements Database.Batchable<SObject>, Schedulable {
  private static final String CRON_DAILY = '0 0 1 * * ?';
  private static final String JOB_NAME = 'TokenExpiryBatch_Daily';

  // ─── Batchable ───────────────────────────────────────────────────────────

  /**
   * @description Queries Active tokens that have passed their expiry date.
   * @param bc BatchableContext provided by the platform.
   * @return Database.QueryLocator for Active expired tokens.
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    Date today = Date.today();
    return Database.getQueryLocatorWithBinds(
      'SELECT Id, Status__c FROM Token__c WHERE Status__c = \'Active\' AND Expiry_Date__c < :today WITH USER_MODE',
      new Map<String, Object>{ 'today' => today },
      AccessLevel.USER_MODE
    );
  }

  /**
   * @description Calls TokenService.expireTokens() for the current batch scope.
   * @param bc BatchableContext provided by the platform.
   * @param scope Current batch of Token__c records.
   */
  public void execute(Database.BatchableContext bc, List<Token__c> scope) {
    TokenService svc = new TokenService();
    svc.expireTokens(scope);
  }

  /**
   * @description Logs a summary message when the batch finishes.
   * @param bc BatchableContext provided by the platform.
   */
  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [
      SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
      FROM AsyncApexJob
      WHERE Id = :bc.getJobId()
      WITH USER_MODE
    ];
    System.debug(
      LoggingLevel.INFO,
      'TokenExpiryBatch finished. Status: ' +
        job.Status +
        ', Processed: ' +
        job.JobItemsProcessed +
        '/' +
        job.TotalJobItems +
        ', Errors: ' +
        job.NumberOfErrors
    );
  }

  // ─── Schedulable ─────────────────────────────────────────────────────────

  /**
   * @description Schedulable execute method — fires the batch job.
   * @param sc SchedulableContext provided by the platform.
   */
  public void execute(SchedulableContext sc) {
    Database.executeBatch(new TokenExpiryBatch());
  }

  // ─── Static helpers ──────────────────────────────────────────────────────

  /**
   * @description Schedules this batch to run daily at 1 AM.
   * @return The scheduled job ID.
   */
  public static String scheduleDaily() {
    return System.schedule(JOB_NAME, CRON_DAILY, new TokenExpiryBatch());
  }

  /**
   * @description Executes the batch immediately with default batch size.
   * @return The batch job ID.
   */
  public static Id run() {
    return Database.executeBatch(new TokenExpiryBatch());
  }
}
