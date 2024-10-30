public with sharing class ContactTriggerHelper {
    
    public static void handleAfterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        Set<Id> contactIdsToSync = new Set<Id>();

        //Identifier les contacts dont le statut IsActive__c a changé
        for (Contact con : newContacts) {
            Boolean newStatus = con.IsActive__c;
            Boolean oldStatus = oldContactsMap.get(con.Id).IsActive__c;
            
            if (newStatus != oldStatus) {
                contactIdsToSync.add(con.Id);
            }
        }

        //lancer le batch de synchronisation
        if (!contactIdsToSync.isEmpty()) {
            System.debug('---- trigger appel au batch');
            System.debug('Lancement de la synchronisation pour les contacts : ' + contactIdsToSync);
            BatchSyncContact syncBatch = new BatchSyncContact(contactIdsToSync);
           Database.executeBatch(syncBatch,10);//(Taille de scope à ajuster)j'ai diminué la taille de scope pour eviter une erreur de limit (too many DML/SOQL) dans le TU car j'utilise 200 entreprise
        }
    }
}