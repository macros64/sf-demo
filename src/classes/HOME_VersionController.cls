public class HOME_VersionController {
    
    public HOME_VersionController() {
        Version = Version__c.getInstance().VersionNumber__c;
    }
    
    public string Version { get; private set; }
}