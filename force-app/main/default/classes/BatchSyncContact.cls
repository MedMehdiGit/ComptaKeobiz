global class BatchSyncContact implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private Set<Id> contactIds;

    public BatchSyncContact(Set<Id> contactIdsToSync) {
        this.contactIds = contactIdsToSync; // ids récupérés depuis le trigger
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([ SELECT Id, IsActive__c FROM Contact WHERE Id IN :contactIds]);
    }

    // Méthode Execute - Exécutée pour chaque lot de contacts
    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        List<Map<String, Object>> contactsToSync = new List<Map<String, Object>>();

        // Préparation des données pour le callout
        for (Contact con : scope) {
            Map<String, Object> contactData = new Map<String, Object>();
            contactData.put('id', con.Id);
            contactData.put('is_active', con.IsActive__c);
            contactsToSync.add(contactData);
        }

        // Vérifie que la liste n'est pas vide avant d'effectuer le callout
        if (!contactsToSync.isEmpty()) {
            syncWithExternalSystem(JSON.serialize(contactsToSync));
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('La synchronisation des contacts est terminée.');
    }

    //méthode pour envoyer les données au système externe via une requête HTTP PATCH
    private void syncWithExternalSystem(String contactsToSyncJson) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://fxyozmgb2xs5iogcheotxi6hoa0jdhiz.lambda-url.eu-central-1.on.aws');
        request.setMethod('PATCH');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer salesforceAuthToken');

        request.setBody(contactsToSyncJson);

        try {
            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();
            if (statusCode == 200) {
                System.debug('BatchSyncContact - OK' + response.getBody());
            } else if (statusCode == 404) {
                System.debug('BatchSyncContact - Erreur de synchronisation : 404 - Not Found');
            } else if (statusCode == 401) {
                System.debug('BatchSyncContact - Erreur de synchronisation : 401 - Bad authorization');
            } else if (statusCode == 400) {
                System.debug('BatchSyncContact - Erreur de synchronisation : 400 - Errors in parameters');
            } else {
                System.debug('BatchSyncContact - Erreur de synchronisation : ' + statusCode + ' - ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('BatchSyncContact - Exception lors de la synchronisation : ' + e.getMessage());
        }
    }
}
