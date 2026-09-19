trigger OrderTotalTrigger on HandsMen_Order__c (before insert, before update) {

    Set<Id> productIds = new Set<Id>();

    for (HandsMen_Order__c order : Trigger.new) {
        if (order.Product__c != null) {
            productIds.add(order.Product__c);
        }
    }

    Map<Id, HandsMen_Product__c> productMap = new Map<Id, HandsMen_Product__c>();

    for (HandsMen_Product__c product : [
        SELECT Id, Price__c
        FROM HandsMen_Product__c
        WHERE Id IN :productIds
    ]) {
        productMap.put(product.Id, product);
    }

    for (HandsMen_Order__c order : Trigger.new) {
        if (order.Product__c != null && order.Quantity__c != null) {

            HandsMen_Product__c product = productMap.get(order.Product__c);

            if (product != null && product.Price__c != null) {
                order.Total_Amount__c =
                    order.Quantity__c * product.Price__c;
            }
        }
    }
}