trigger AccountTrigger on Account (before update, after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHelper.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        AccountTriggerHelper.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}
