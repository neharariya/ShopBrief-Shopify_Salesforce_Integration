
public with sharing class ShopifySalesCalculator {

    // Holds the calculated report values
    public class SalesSummary {
        public Integer totalOrders = 0;
        public Decimal totalSalesRevenue = 0;
        public Decimal totalDiscounts = 0;
    }

    // Calculates sales metrics from Shopify orders
    public static SalesSummary calculate(
        List<ShopifyOrderWrapper.Order> orders
    ) {
        SalesSummary summary = new SalesSummary();

        if (orders == null) {
            return summary;
        }

        // Count all orders
        summary.totalOrders = orders.size();

        // Calculate revenue and discounts
        for (ShopifyOrderWrapper.Order order : orders) {

            if (order == null) {
                continue;
            }

            // Include all orders regardless of payment status
            if (String.isNotBlank(order.current_total_price)) {
                summary.totalSalesRevenue +=
                    Decimal.valueOf(order.current_total_price);
            }

            // Add discounts from each order
            if (String.isNotBlank(order.total_discounts)) {
                summary.totalDiscounts +=
                    Decimal.valueOf(order.total_discounts);
            }
        }

        return summary;
    }
}
