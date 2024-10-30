trigger ContactTrigger on Contact (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        ContactTriggerHelper.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
