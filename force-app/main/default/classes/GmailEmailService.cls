
public with sharing class GmailEmailService {

    public static void sendHtml(
        String recipient,
        String subject,
        String htmlBody
    ) {

        // 1. Validate required information
        if (String.isBlank(recipient) ||
            String.isBlank(subject) ||
            htmlBody == null) {

            throw new CalloutException(
                'Recipient, subject and email body are required.'
            );
        }

        // 2. Prevent newline characters in email headers
        if (recipient.contains('\r') ||
            recipient.contains('\n') ||
            subject.contains('\r') ||
            subject.contains('\n')) {

            throw new CalloutException(
                'Invalid email header.'
            );
        }

        // 3. Construct MIME email message
        String mimeMessage =
            'To: ' + recipient + '\r\n' +
            'Subject: ' + subject + '\r\n' +
            'MIME-Version: 1.0\r\n' +
            'Content-Type: text/html; charset=UTF-8\r\n' +
            '\r\n' +
            htmlBody;

        // 4. Convert MIME message to Base64URL
        String encodedMessage =
            EncodingUtil.base64Encode(
                Blob.valueOf(mimeMessage)
            )
            .replace('+', '-')
            .replace('/', '_')
            .replace('=', '');

        // 5. Prepare HTTP request
        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'callout:Gmail_API/gmail/v1/users/me/messages/send'
        );

        req.setMethod('POST');

        req.setHeader(
            'Content-Type',
            'application/json'
        );

        req.setTimeout(20000);

        // 6. Add encoded email to request body
        req.setBody(
            JSON.serialize(
                new Map<String, String>{
                    'raw' => encodedMessage
                }
            )
        );

        // 7. Send request to Gmail API
        HttpResponse res = new Http().send(req);

        // 8. Check Gmail API response
        if (res.getStatusCode() < 200 ||
            res.getStatusCode() >= 300) {

            throw new CalloutException(
                'Gmail API failed. HTTP Status: ' +
                res.getStatusCode() +
                ' - ' + res.getBody()
            );
        }

        System.debug(
            'Gmail API accepted email. HTTP Status: ' +
            res.getStatusCode()
        );
    }
}
