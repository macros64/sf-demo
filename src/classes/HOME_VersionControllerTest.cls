@isTest
public class HOME_VersionControllerTest {
    public static testMethod void test () {
        Version__c ver = new Version__c();
        ver.SetupOwnerId = UserInfo.getOrganizationId();
        ver.VersionNumber__c = 'v234';
        insert ver;
        
        HOME_VersionController ctrl = new HOME_VersionController();
        system.assertEquals('v234', ctrl.Version);
        
        ver = Version__c.getOrgDefaults();
        ver.VersionNumber__c = 'wwww2222';
        update ver;
        
        HOME_VersionController ctrl2 = new HOME_VersionController();
        system.assertEquals('wwww2222', ctrl2.Version);
    }
}