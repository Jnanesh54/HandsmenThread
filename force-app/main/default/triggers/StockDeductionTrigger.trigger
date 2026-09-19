trigger StockDeductionTrigger on HandsMen_Order__c (after insert, after update) {

    Set<Id> productIds = new Set<Id>();
    Map<Id, Decimal> quantityByProduct = new Map<Id, Decimal>();

    // Find products whose stock should be deducted
    for (HandsMen_Order__c order : Trigger.new) {

        Boolean shouldDeduct = false;

        // New order
        if (Trigger.isInsert && order.Status__c == 'Confirmed') {
            shouldDeduct = true;
        }

        // Existing order changed to Confirmed
        if (Trigger.isUpdate) {
            HandsMen_Order__c oldOrder = Trigger.oldMap.get(order.Id);

            if (oldOrder.Status__c != 'Confirmed' &&
                order.Status__c == 'Confirmed') {
                shouldDeduct = true;
            }
        }

        if (shouldDeduct &&
            order.Product__c != null &&
            order.Quantity__c != null) {

            Id productId = order.Product__c;

            productIds.add(productId);

            if (!quantityByProduct.containsKey(productId)) {
                quantityByProduct.put(productId, order.Quantity__c);
            } else {
                quantityByProduct.put(
                    productId,
                    quantityByProduct.get(productId) + order.Quantity__c
                );
            }
        }
    }

    if (productIds.isEmpty()) {
        return;
    }

    // Get current inventory
    List<Inventory__c> inventories = [
        SELECT Id, Stock_Quantity__c, Product__c
        FROM Inventory__c
        WHERE Product__c IN :productIds
    ];

    // IMPORTANT:
    // Create NEW Inventory records containing ONLY
    // the Id and Stock Quantity.
    List<Inventory__c> inventoriesToUpdate =
        new List<Inventory__c>();

    for (Inventory__c inv : inventories) {

        if (quantityByProduct.containsKey(inv.Product__c)) {

            Decimal quantityToDeduct =
                quantityByProduct.get(inv.Product__c);

            Inventory__c inventoryUpdate =
                new Inventory__c();

            inventoryUpdate.Id = inv.Id;

            inventoryUpdate.Stock_Quantity__c =
                inv.Stock_Quantity__c - quantityToDeduct;

            inventoriesToUpdate.add(inventoryUpdate);
        }
    }

    // Update only Id + Stock Quantity
    if (!inventoriesToUpdate.isEmpty()) {
        update inventoriesToUpdate;
    }
}