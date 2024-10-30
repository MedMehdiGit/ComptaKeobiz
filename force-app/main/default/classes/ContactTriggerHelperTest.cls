@isTest
public with sharing class ContactTriggerHelperTest {
    
    @testSetup
    static void setup() {
        // Creer 200 entreprises
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i, MissionStatus__c = 'active'));
        }
        insert accounts;

        // Creer des contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            contacts.add(new Contact(FirstName = 'Active', LastName = 'Contact ' + i, IsActive__c = true));
            contacts.add(new Contact(FirstName = 'Inactive', LastName = 'Contact ' + i, IsActive__c = false));
        }
        insert contacts;

        // Creer les AccountContactRelation 
        List<AccountContactRelation__c> acrs = new List<AccountContactRelation__c>();
        List<Account> insertedAccounts = [SELECT Id FROM Account];
        List<Contact> insertedContacts = [SELECT Id FROM Contact];
        for (Account acc : insertedAccounts) {
            for (Contact con : insertedContacts) {
                acrs.add(new AccountContactRelation__c(Account__c = acc.Id, ContactId__c = con.Id));
            }
        }
        insert acrs;
    }
    @isTest
    static void testActivateContact() {
        Contact contactToUpdate = [SELECT Id, IsActive__c FROM Contact WHERE IsActive__c = false LIMIT 1];
        contactToUpdate.IsActive__c = true;

        Test.startTest();
        update contactToUpdate;
        Test.stopTest();

        // Verfier si le status de contact est modifié à true
        Contact updatedContact = [SELECT Id, IsActive__c FROM Contact WHERE Id = :contactToUpdate.Id];
        System.assertEquals(true, updatedContact.IsActive__c);

        //verifier si le batch est appelé
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Completed'];
       // System.debug('--- jobs :'+jobs);
        System.assert(jobs.size() > 0);
    }

    @isTest
    static void testDeactivateContact() {
        Contact contactToUpdate = [SELECT Id, IsActive__c FROM Contact WHERE IsActive__c = true LIMIT 1];
        contactToUpdate.IsActive__c = false;

        Test.startTest();
        update contactToUpdate;
        Test.stopTest();

        // Verifier si le status de contact est modifié à false
        Contact updatedContact = [SELECT Id, IsActive__c FROM Contact WHERE Id = :contactToUpdate.Id];
        System.assertEquals(false, updatedContact.IsActive__c);

        // vérifier si le batch est appelé
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Completed'];
       // System.debug('--- jobs :'+jobs);
        System.assert(jobs.size() > 0);
    }

    @isTest
    static void testNoStatusChange() { // tester le cas où on modifie autre chose dans contact à part le status
        Contact contactToUpdate = [SELECT Id, IsActive__c FROM Contact LIMIT 1];
        Boolean originalStatus = contactToUpdate.IsActive__c;
        // ici on ne modifie pas le status , on ne modifie que le nom
        contactToUpdate.FirstName = 'Mehdi Name2';

        Test.startTest();
        update contactToUpdate;
        Test.stopTest();

        Contact updatedContact = [SELECT Id, IsActive__c, FirstName FROM Contact WHERE Id = :contactToUpdate.Id];
        // verifier si le contact n'a pas changé de status
        System.assertEquals(originalStatus, updatedContact.IsActive__c);
        
        // vérifier si le contact a changé de nom
        System.assertEquals('Mehdi Name2', updatedContact.FirstName);

        // verifier si le batch n'est pas appelé
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        //System.debug('--- jobs :'+jobs);
        System.assertEquals(0, jobs.size());
    }
}