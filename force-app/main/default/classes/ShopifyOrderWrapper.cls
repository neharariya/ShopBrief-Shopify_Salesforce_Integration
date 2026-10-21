
public class ShopifyOrderWrapper {

    public class OrderResponse {
        public List<Order> orders;
    }

    public class Order {
        public Long id;
        public String created_at;

        // Currency field removed for now

        public String total_price;
        public String current_total_price;
        public String total_line_items_price;
        public String subtotal_price;
        public String current_subtotal_price;
        public String total_discounts;
        public String current_total_discounts;
        public String total_tax;

        public String financial_status;
        public String fulfillment_status;
        public String cancelled_at;

        public List<LineItem> line_items;
        public List<DiscountCode> discount_codes;
        public List<DiscountApplication> discount_applications;
        public List<Refund> refunds;
    }

    public class LineItem {
        public Long id;
        public Long product_id;
        public Long variant_id;
        public String title;
        public String sku;
        public Integer quantity;
        public String price;
        public String total_discount;
    }

    public class DiscountCode {
        public String code;
        public String amount;
        public String type;
    }

    public class DiscountApplication {
        public String type;
        public String title;
        public String code;
        public String value;
        public String value_type;
        public String allocation_method;
        public String target_type;
        public String target_selection;
    }

    public class Refund {
        public Long id;
        public String created_at;
        public List<RefundLineItem> refund_line_items;
        public List<ShopifyTransaction> transactions;
    }

    public class RefundLineItem {
        public Long id;
        public Integer quantity;
        public String subtotal;
        public String total_tax;
        public LineItem line_item;
    }

    public class ShopifyTransaction {
        public Long id;
        public String kind;
        public String status;
        public String amount;
    }
}
