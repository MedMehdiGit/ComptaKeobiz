@isTest
public with sharing class BatchSyncContactTest {
    // Variables statiques pour capturer le statut de la réponse
    public static Integer lastStatusCode;
    public static String lastStatus;

    @testSetup
    static void setup() {
        // Creer les contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 100; i++) {
            contacts.add(new Contact(FirstName = 'Active', LastName = 'Contact ' + i, IsActive__c = true));
            contacts.add(new Contact(FirstName = 'Inactive', LastName = 'Contact ' + i, IsActive__c = false));
        }
        insert contacts;
    }

    @isTest
    static void testBatchStart() {
        Set<Id> contactIds = getTestContactIds(); // retourne 10 contacts
    
        BatchSyncContact batch = new BatchSyncContact(contactIds);
    
        Test.startTest();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
    
        // Vérifier que le QueryLocator n'est pas nul
        System.assertNotEquals(null, ql);
    }

    @isTest
    static void testBatchExecuteSuccess() {
        Set<Id> contactIds = getTestContactIds(); 

        BatchSyncContact batch = new BatchSyncContact(contactIds);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK'));

        // Exécuter le batch
        Test.startTest();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        // Vérifier le code de statut et le message
        System.assertEquals(200, BatchSyncContactTest.lastStatusCode);
        System.assertEquals('OK', BatchSyncContactTest.lastStatus);
    }

    @isTest
    static void testBatchExecute404Error() {
        Set<Id> contactIds = getTestContactIds();

        BatchSyncContact batch = new BatchSyncContact(contactIds);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(404, 'Not Found'));

        // Exécuter le batch
        Test.startTest();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        // Vérifier le code de statut et le message
        System.assertEquals(404, BatchSyncContactTest.lastStatusCode);
        System.assertEquals('Not Found', BatchSyncContactTest.lastStatus);
    }

    @isTest
    static void testBatchExecute401Error() {
        Set<Id> contactIds = getTestContactIds();
 
         BatchSyncContact batch = new BatchSyncContact(contactIds);
         Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(401, 'Bad authorization'));
 
         // Exécuter le batch
         Test.startTest();
         Database.executeBatch(batch, 10);
         Test.stopTest();
 
         // Vérifier le code de statut et le message
         System.assertEquals(401, BatchSyncContactTest.lastStatusCode);
         System.assertEquals('Bad authorization', BatchSyncContactTest.lastStatus);
    }

    @isTest
    static void testBatchExecute400Error() {
      Set<Id> contactIds = getTestContactIds();
       
       BatchSyncContact batch = new BatchSyncContact(contactIds);
       Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, 'Errors in parameters: must be an array of objects with two properties id:string and is_active:boolean'));

       // Exécuter le batch
       Test.startTest();
       Database.executeBatch(batch, 10);
       Test.stopTest();

       // Vérifier le code de statut et le message
       System.assertEquals(400, BatchSyncContactTest.lastStatusCode);
       System.assertEquals('Errors in parameters: must be an array of objects with two properties id:string and is_active:boolean', BatchSyncContactTest.lastStatus);
    }

    // Mock HTTP Response Generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String status;

        public MockHttpResponseGenerator(Integer statusCode, String status) {
            this.statusCode = statusCode;
            this.status = status;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setStatus(status);

            // Stocke le code de statut et le statut dans les variables statiques de la classe principale
            BatchSyncContactTest.lastStatusCode = res.getStatusCode();
            BatchSyncContactTest.lastStatus = res.getStatus();

            return res;
        }
    }
    // Préparer les données de test et configurer le mock comme précédemment
    public static Set<Id> getTestContactIds() {
        Set<Id> ids = new Set<Id>();
        for (Contact c : [SELECT Id FROM Contact LIMIT 10]) {
            ids.add(c.Id);
        }
        return ids;
    }

}