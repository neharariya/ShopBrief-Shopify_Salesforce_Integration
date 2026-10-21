
public with sharing class ShopifyTimeStampService {

    public static Map<String, String> getTimeStamps(
        String storeTimezone
    ) {

        if (String.isBlank(storeTimezone)) {
            throw new CalloutException(
                'Shopify store timezone is missing.'
            );
        }

        // Find today's date in the store timezone
        String todayText = System.now().format(
            'yyyy-MM-dd',
            storeTimezone
        );

        Date today = Date.valueOf(todayText);

        // Find yesterday's date
        Date yesterday = today.addDays(-1);

        // Create midnight boundaries
        Datetime startPlaceholder = Datetime.newInstanceGmt(
            yesterday,
            Time.newInstance(0, 0, 0, 0)
        );

        Datetime endPlaceholder = Datetime.newInstanceGmt(
            today,
            Time.newInstance(0, 0, 0, 0)
        );

        // Convert Brisbane midnight to UTC
        TimeZone tz = TimeZone.getTimeZone(storeTimezone);

        Datetime startUtc = startPlaceholder.addSeconds(
            -(tz.getOffset(startPlaceholder) / 1000)
        );

        Datetime endUtc = endPlaceholder.addSeconds(
            -(tz.getOffset(endPlaceholder) / 1000)
        );

        // Last second of yesterday
        endUtc = endUtc.addSeconds(-1);

        String startTimeStamp = startUtc.formatGmt(
            'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''
        );

        String endTimeStamp = endUtc.formatGmt(
            'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''
        );

        return new Map<String, String>{
            'startTime' => startTimeStamp,
            'endTime' => endTimeStamp
        };
    }
}
