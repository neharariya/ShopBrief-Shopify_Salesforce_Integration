
public with sharing class ShopifyReportService {

    public static void generateReport() {

        // 1. Fetch active store configuration
        List<Shopify_Report_Config__mdt> stores = [
            SELECT DeveloperName,
                   Named_Credential__c,
                   API_Version__c,
                   Recipient_Email__c,
                   Timezone__c
            FROM Shopify_Report_Config__mdt
            WHERE Active__c = true
            LIMIT 2
        ];

        // 2. Ensure exactly one store is active
        if (stores.size() != 1) {
            throw new CalloutException(
                'Exactly one Shopify store must be active.'
            );
        }

        // 3. Select active store
        Shopify_Report_Config__mdt storeConfig = stores[0];

        String recipientEmail = storeConfig.Recipient_Email__c;

        if (String.isBlank(recipientEmail)) {
            throw new CalloutException(
                'Recipient email is missing in active Shopify store configuration.'
            );
        }

        // 4. CHANGED: Receive all orders as an Apex List
        List<ShopifyOrderWrapper.Order> orders =
            ShopifyOrderService.getOrders(storeConfig);

        // REMOVED: JSON.deserialize() is now performed
        // inside ShopifyOrderService for each page.

        System.debug('Total Orders: ' + orders.size());

        // 5. Loop through all collected orders
        for (ShopifyOrderWrapper.Order order : orders) {

            System.debug('Order ID: ' + order.id);
            System.debug('Total Price: ' + order.current_total_price);
            System.debug('Financial Status: ' + order.financial_status);
            System.debug('Total Discounts: ' + order.total_discounts);
            System.debug('Current Discounts: ' + order.current_total_discounts);

            // 6. Print product details
            if (order.line_items != null) {
                for (ShopifyOrderWrapper.LineItem item : order.line_items) {
                    System.debug(
                        'Product: ' + item.title +
                        ' | Quantity: ' + item.quantity +
                        ' | Price: ' + item.price
                    );
                }
            }

            // 7. Print applied discount codes
            if (order.discount_codes != null) {
                for (ShopifyOrderWrapper.DiscountCode discount : order.discount_codes) {
                    System.debug(
                        'Discount Code: ' + discount.code +
                        ' | Amount: ' + discount.amount
                    );
                }
            }

            // 8. Print refund details
            if (order.refunds != null) {
                for (ShopifyOrderWrapper.Refund refund : order.refunds) {
                    System.debug('Refund ID: ' + refund.id);
                }
            }
        }

        // 9. CHANGED: Pass the combined orders list
        ShopifySalesCalculator.SalesSummary summary =
            ShopifySalesCalculator.calculate(orders);

        System.debug('===== SHOPIFY DAILY SALES SUMMARY =====');
        System.debug('Total Orders: ' + summary.totalOrders);
        System.debug('Total Sales Revenue: ' + summary.totalSalesRevenue);
        System.debug('Total Discounts: ' + summary.totalDiscounts);

        // 10. Send email — unchanged
        ShopifyEmailService.sendReport(
            summary,
            recipientEmail
        );
    }
}
