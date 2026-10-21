
public with sharing class ShopifyEmailService {

    public static void sendReport(
        ShopifySalesCalculator.SalesSummary summary,
        String recipientEmail
    ) {
        // 1. Validate the required data
        if (summary == null || String.isBlank(recipientEmail)) {
            throw new EmailException(
                'Missing sales summary or recipient email.'
            );
        }

        // 2. Create the HTML sales report
        String htmlBody =
            '<html><body>' +
            '<h2>Shopify Daily Sales Report</h2>' +
            '<p>Here is your sales summary for the last day.</p>' +
            '<table border="1" cellpadding="10" cellspacing="0">' +
            '<tr><th>Metric</th><th>Value</th></tr>' +
            '<tr><td>Total Orders</td><td>' +
                summary.totalOrders + '</td></tr>' +
            '<tr><td>Total Order Value</td><td>' +
                summary.totalSalesRevenue + '</td></tr>' +
            '<tr><td>Total Discounts</td><td>' +
                summary.totalDiscounts + '</td></tr>' +
            '</table>' +
            '<p>Generated automatically by Salesforce.</p>' +
            '</body></html>';

        // 3. Send the report using Gmail API
        GmailEmailService.sendHtml(
            recipientEmail,
            'Shopify Daily Sales Report',
            htmlBody
        );
    }
}
