/**
 * @description Tests that the Token_Manager permission set does NOT contain an
 *              explicit field-level security (FLS) entry for
 *              Token__c.Expiry_Date__c.
 *
 *              Salesforce prevents deploying a permission set that explicitly
 *              grants permissions on a required field. The fieldPermissions block
 *              for Token__c.Expiry_Date__c must therefore be absent from
 *              Token_Manager.permissionset-meta.xml.
 *
 *              This test queries the FieldPermissions sObject at runtime to
 *              confirm the entry is not present, providing a continuous
 *              regression guard.
 */
@IsTest
private class TokenManagerPermSetTest {
  /**
   * @description Verifies that there is no explicit FLS entry for
   *              Token__c.Expiry_Date__c on the Token_Manager permission set.
   *              Required fields are inherently accessible to all users who have
   *              object-level read/edit access; an explicit grant causes a
   *              deployment error.
   */
  @IsTest
  static void tokenManager_noExplicitFlsForExpiryDate() {
    // Query the Token_Manager permission set
    List<PermissionSet> permSets = [
      SELECT Id, Name
      FROM PermissionSet
      WHERE Name = 'Token_Manager'
      LIMIT 1
    ];

    if (permSets.isEmpty()) {
      Assert.fail(
        'Token_Manager permission set not found in this org. Cannot validate FLS entries.'
      );
    }

    Id permSetId = permSets[0].Id;

    // Query FieldPermissions for the Expiry_Date__c field on this permission set
    List<FieldPermissions> flsEntries = [
      SELECT Id, Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE
        SobjectType = 'Token__c'
        AND Field = 'Token__c.Expiry_Date__c'
        AND ParentId = :permSetId
    ];

    Assert.areEqual(
      0,
      flsEntries.size(),
      'Token_Manager permission set must not contain an explicit FLS entry for '
        + 'Token__c.Expiry_Date__c. Required fields do not need explicit grants '
        + 'and Salesforce blocks deployment when they are present.'
    );
  }

  /**
   * @description Verifies that the Token_Manager permission set retains FLS
   *              entries for the other custom fields that do require explicit
   *              grants (Status__c, Issued_Date__c, Scope__c).
   */
  @IsTest
  static void tokenManager_retainsFLSForOtherFields() {
    List<PermissionSet> permSets = [
      SELECT Id, Name
      FROM PermissionSet
      WHERE Name = 'Token_Manager'
      LIMIT 1
    ];

    if (permSets.isEmpty()) {
      Assert.fail(
        'Token_Manager permission set not found in this org. Cannot validate FLS entries.'
      );
    }

    Id permSetId = permSets[0].Id;

    Set<String> expectedFields = new Set<String>{
      'Token__c.Status__c',
      'Token__c.Issued_Date__c',
      'Token__c.Scope__c'
    };

    List<FieldPermissions> flsEntries = [
      SELECT Id, Field
      FROM FieldPermissions
      WHERE
        SobjectType = 'Token__c'
        AND Field IN :expectedFields
        AND ParentId = :permSetId
    ];

    Set<String> actualFields = new Set<String>();
    for (FieldPermissions fp : flsEntries) {
      actualFields.add(fp.Field);
    }
    Set<String> missingFields = expectedFields.clone();
    missingFields.removeAll(actualFields);

    Assert.areEqual(
      expectedFields.size(),
      flsEntries.size(),
      'Token_Manager is missing FLS entries for: ' + missingFields
    );
  }
}
