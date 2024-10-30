public with sharing class AccountTriggerHelper {
    public static Boolean isTriggerExecuted = false;

    public static void handleBeforeUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        System.debug('---trigger Before');
        for (Account acc : newAccounts) {
            //Mise à jour de la date si le statut est annulé
            // Autre solution on peut mettre la date d'annulation comme champ formule si on veut utiliser le no-code
            if (acc.MissionStatus__c == 'canceled' && acc.MissionStatus__c != oldAccountsMap.get(acc.Id).MissionStatus__c) {
                acc.MissionCanceledDate__c = Date.today();
            }

            //Rénitialiser la date d'annulation si le statut est actif
            if (acc.MissionStatus__c == 'active' && acc.MissionStatus__c != oldAccountsMap.get(acc.Id).MissionStatus__c) {
                acc.MissionCanceledDate__c = null;
            }
        }
    }

    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        if (isTriggerExecuted) return;
       isTriggerExecuted = true;
    
        Set<Id> idAccountChanged = new Set<Id>();
        Set<Id> IdContactsWithAccountUpdated = new Set<Id>();

        System.debug('---trigger after');
    
        //Identifier les Account qui changé de status
        for (Account acc : newAccounts) {
            if (/*acc.MissionStatus__c == 'canceled' && */acc.MissionStatus__c != oldAccountsMap.get(acc.Id).MissionStatus__c) {
                idAccountChanged.add(acc.Id);
            }
        }

        //Récupérer tous les AccountContactRelation__c lié aux accounts changés
        if (!idAccountChanged.isEmpty()) {
            List<AccountContactRelation__c> listAccountContactRelation = [
                SELECT ContactId__c 
                FROM AccountContactRelation__c 
                WHERE Account__c IN :idAccountChanged
            ];
            // Récupérer les contacts liés aux comptes changés
            for (AccountContactRelation__c acr : listAccountContactRelation) {
                IdContactsWithAccountUpdated.add(acr.ContactId__c);
            }
        }
    
        List<Contact> contactsToUpdate = new List<Contact>();

        if (!IdContactsWithAccountUpdated.isEmpty()) {
            //Compter d'abord le nombre total de comptes par contact et les mettre dans la map totalAccountsPerContact
            Map<Id, Integer> totalAccountsPerContact = new Map<Id, Integer>();
            AggregateResult[] totalResults = [SELECT ContactId__c, COUNT(Id) totalCount
                                              FROM AccountContactRelation__c
                                              WHERE ContactId__c IN :IdContactsWithAccountUpdated
                                              GROUP BY ContactId__c];
            
            for (AggregateResult ar : totalResults) {
                totalAccountsPerContact.put((Id) ar.get('ContactId__c'), (Integer) ar.get('totalCount'));
            }
    
            //Compter les comptes annulés par contact et les mettre dans la map cancledAccountsPerContact
            // Autre sollution: on peut créer un champ rollup summary pour compter le nombre des comptes actifs puisqu'on a une relation MD entre AccountContactRelation et Account
            Map<Id, Integer> cancledAccountsPerContact = new Map<Id, Integer>();
            AggregateResult[] resultsACR = [SELECT ContactId__c, 
                                            COUNT(Id) countCanceled
                                            FROM AccountContactRelation__c
                                            WHERE ContactId__c IN :IdContactsWithAccountUpdated AND Account__r.MissionStatus__c = 'canceled'
                                            GROUP BY ContactId__c];
            for (AggregateResult ar : resultsACR) {
                cancledAccountsPerContact.put((Id) ar.get('ContactId__c'), (Integer) ar.get('countCanceled'));
            }
    
            //On compare le nombre total des comptes par contact avec le nombre des comptes annulés et on met à jour les contacts
            for (Id contactId : IdContactsWithAccountUpdated) {
                Integer totalAccounts = totalAccountsPerContact.get(contactId);
                Integer canceledAccounts = cancledAccountsPerContact.get(contactId);

                Contact contactToUpdate;
                if (totalAccounts == canceledAccounts && canceledAccounts != null && totalAccounts != null) {
                    contactToUpdate = new Contact(Id = contactId, IsActive__c = false);
                } else { // dans le cas inverse dés qu'il y a une entreprise active liée au client on active ce client
                    contactToUpdate = new Contact(Id = contactId, IsActive__c = true);  
                }
                contactsToUpdate.add(contactToUpdate);
            }

            if (!contactsToUpdate.isEmpty()) {
                update contactsToUpdate; // on peut aussi utiliser Database.update(contactsToUpdate,false) pour faire un update partiel
            }
        }
    }
}
