
// public with sharing class ShopifyOrderService {

//     public static String getOrders(
//         Shopify_Report_Config__mdt storeConfig
//     ) {

//         // 1. Validate store configuration
//         if (storeConfig == null ||
//             String.isBlank(storeConfig.Named_Credential__c) ||
//             String.isBlank(storeConfig.API_Version__c)) {

//             throw new CalloutException(
//                 'Missing Shopify store configuration.'
//             );
//         }

//         // 2. Retrieve values from selected store metadata
//         String namedCredential = storeConfig.Named_Credential__c;
//         String apiVersion = storeConfig.API_Version__c;

//         // 3. Get timestamps for previous 24 hours
//         Map<String, String> timestamps =
//     ShopifyTimeStampService.getTimeStamps(
//         storeConfig.Timezone__c
//     );

//         String startTime = timestamps.get('startTime');
//         String endTime = timestamps.get('endTime');

//         // 4. Construct Shopify REST API endpoint
//         String endpoint =
//             'callout:' + namedCredential +
//             '/admin/api/' + apiVersion + '/orders.json' +
//             '?status=any' +
//             '&created_at_min=' +
//                 EncodingUtil.urlEncode(startTime, 'UTF-8') +
//             '&created_at_max=' +
//                 EncodingUtil.urlEncode(endTime, 'UTF-8') +
//             '&limit=250';

//         try {

//             // 5. Create HTTP GET request
//             HttpRequest req = new HttpRequest();
//             req.setEndpoint(endpoint);
//             req.setMethod('GET');
//             req.setTimeout(20000);

//             // 6. Send request to Shopify
//             Http http = new Http();
//             HttpResponse res = http.send(req);

//             // 7. Check response status
//             if (res.getStatusCode() != 200) {
//                 throw new CalloutException(
//                     'Shopify API failed. HTTP Status: ' +
//                     res.getStatusCode() +
//                     ' - ' + res.getStatus()
//                 );
//             }

//             // 8. Return JSON response as String
//             return res.getBody();

//         } catch (CalloutException ex) {

//             // Log the error and propagate it
//             System.debug(
//                 LoggingLevel.ERROR,
//                 'Shopify callout failed: ' + ex.getMessage()
//             );

//             throw ex;
//         }
//     }
// }


public with sharing class ShopifyOrderService {

    // CHANGED: Return a List of orders instead of a JSON String
    public static List<ShopifyOrderWrapper.Order> getOrders(
        Shopify_Report_Config__mdt storeConfig
    ) {

        // 1. Validate store configuration
        if (storeConfig == null ||
            String.isBlank(storeConfig.Named_Credential__c) ||
            String.isBlank(storeConfig.API_Version__c) ||
            String.isBlank(storeConfig.Timezone__c)) {

            throw new CalloutException(
                'Missing Shopify store configuration.'
            );
        }

        // 2. Retrieve values from selected store metadata
        String namedCredential = storeConfig.Named_Credential__c;
        String apiVersion = storeConfig.API_Version__c;

        // 3. Get timestamps for previous full store day
        Map<String, String> timestamps =
            ShopifyTimeStampService.getTimeStamps(
                storeConfig.Timezone__c
            );

        String startTime = timestamps.get('startTime');
        String endTime = timestamps.get('endTime');

        // 4. Construct Shopify REST API endpoint
        String apiPath =
            '/admin/api/' + apiVersion + '/orders.json';

        String endpoint =
            'callout:' + namedCredential +
            apiPath +
            '?status=any' +
            '&created_at_min=' +
                EncodingUtil.urlEncode(startTime, 'UTF-8') +
            '&created_at_max=' +
                EncodingUtil.urlEncode(endTime, 'UTF-8') +
            '&limit=1';

        // NEW: Store orders from all pages in one list
        List<ShopifyOrderWrapper.Order> allOrders =
            new List<ShopifyOrderWrapper.Order>();

        // NEW: Track number of pages fetched
        Integer pageNumber = 0;

        try {

            Http http = new Http();

            // NEW: Continue until Shopify has no next page
            while (endpoint != null) {

                // NEW: Reserve one callout for Gmail API
                if (Limits.getCallouts() >=
                    Limits.getLimitCallouts() - 1) {

                    throw new CalloutException(
                        'Shopify pagination exceeded the available callout limit.'
                    );
                }

                // 5. Create HTTP GET request
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('GET');
                req.setTimeout(20000);

                // 6. Send request to Shopify
                HttpResponse res = http.send(req);

                // 7. Check response status
                if (res.getStatusCode() != 200) {
                    throw new CalloutException(
                        'Shopify API failed. HTTP Status: ' +
                        res.getStatusCode() +
                        ' - ' + res.getStatus()
                    );
                }

                // NEW: Deserialize the current page's JSON
                ShopifyOrderWrapper.OrderResponse response =
                    (ShopifyOrderWrapper.OrderResponse)
                    JSON.deserialize(
                        res.getBody(),
                        ShopifyOrderWrapper.OrderResponse.class
                    );

                if (response == null || response.orders == null) {
                    throw new CalloutException(
                        'Invalid Shopify response: orders data missing.'
                    );
                }

                // NEW: Add this page's orders to the main list
                allOrders.addAll(response.orders);

                pageNumber++;

                System.debug(
                    'Shopify Page: ' + pageNumber +
                    ' | Orders on page: ' + response.orders.size() +
                    ' | Total collected: ' + allOrders.size()
                );

                // NEW: Find next page URL from Link header
                endpoint = getNextPageEndpoint(
                    res.getHeader('Link'),
                    namedCredential,
                    apiPath
                );
            }

            System.debug(
                'Pagination completed. Total Orders: ' +
                allOrders.size()
            );

            // CHANGED: Return all collected Apex Order objects
            return allOrders;

        } catch (CalloutException ex) {

            System.debug(
                LoggingLevel.ERROR,
                'Shopify callout failed: ' + ex.getMessage()
            );

            throw ex;
        }
    }

    // NEW: Helper method to find Shopify's next page
    private static String getNextPageEndpoint(
        String linkHeader,
        String namedCredential,
        String apiPath
    ) {

        // No Link header means no next page
        if (String.isBlank(linkHeader)) {
            return null;
        }

        // Shopify may return next and previous links
        for (String part : linkHeader.split(',')) {

            // We only want the next-page link
            if (!part.contains('rel="next"') &&
                !part.contains('rel=next')) {
                continue;
            }

            // Extract URL between < and >
            Integer startIndex = part.indexOf('<');
            Integer endIndex = part.indexOf('>');

            if (startIndex < 0 || endIndex <= startIndex) {
                throw new CalloutException(
                    'Invalid Shopify pagination Link header.'
                );
            }

            String nextUrl = part.substring(
                startIndex + 1,
                endIndex
            );

            // Extract query parameters from Shopify's URL
            Integer questionMark = nextUrl.indexOf('?');

            if (questionMark < 0) {
                throw new CalloutException(
                    'Missing Shopify pagination query parameters.'
                );
            }

            String query = nextUrl.substring(
                questionMark + 1
            );

            if (!query.contains('page_info=')) {
                throw new CalloutException(
                    'Missing Shopify page_info cursor.'
                );
            }

            // Use the same Named Credential for the next request
            return 'callout:' + namedCredential +
                apiPath + '?' + query;
        }

        // No rel="next" means pagination is finished
        return null;
    }
}
