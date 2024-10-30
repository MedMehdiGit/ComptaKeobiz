@isTest
private class AccountTriggerHelperTest {
    @TestSetup
    static void makeData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                MissionStatus__c = 'active'
            );
            accounts.add(acc);
        }
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            Contact con = new Contact(
                LastName = 'Test Contact ' + i
            );
            contacts.add(con);
        }
        insert contacts;

        List<AccountContactRelation__c> acrs = new List<AccountContactRelation__c>();
        for (Integer i = 0; i < 200; i++) {
            AccountContactRelation__c acr = new AccountContactRelation__c(
                Account__c = accounts[i].Id,
                ContactId__c = contacts[i].Id
            );
            acrs.add(acr);
        }
        insert acrs;
    }

    @isTest
    static void testHandleAfterUpdate() {
        List<Account> accounts = [SELECT Id, MissionStatus__c FROM Account LIMIT 200];

        for (Account acc : accounts) {
            acc.MissionStatus__c = 'canceled';
        }
        Test.startTest();
        update accounts;
        Test.stopTest();

        Date today = Date.today();
        List<Account> updatedAccounts = [SELECT Id, MissionCanceledDate__c FROM Account WHERE MissionStatus__c = 'canceled'];
        for (Account acc : updatedAccounts) {
            System.assertEquals(today, acc.MissionCanceledDate__c);
        }

        // Verifier si les contact liés aux comptes annulés sont bien désactivés
        List<Contact> updatedContacts = [SELECT Id, IsActive__c FROM Contact WHERE Id IN (SELECT ContactId__c FROM AccountContactRelation__c WHERE Account__r.MissionStatus__c = 'canceled')];
        for (Contact con : updatedContacts) {
            System.assertEquals(false, con.IsActive__c);
        }
    }
}