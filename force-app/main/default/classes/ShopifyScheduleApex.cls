
public with sharing class ShopifyScheduleApex
    implements Schedulable {

    public void execute(SchedulableContext context) {

        System.enqueueJob(new ShopifyReportQueueable());

    }
}
