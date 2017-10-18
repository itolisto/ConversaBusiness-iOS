//
//  NotificationService.swift
//  NotificationService
//
//  Created by Edgar Gomez on 10/17/17.
//  Copyright © 2017 Conversa. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void)
    {
        self.contentHandler = contentHandler
        self.bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        // look for existance of taplytics data with image_url
        if let tlData = request.content.userInfo["taplytics"] as? [String: Any], let imageUrl = tlData["image_url"] as? String, let url = URL(string: imageUrl) {
            URLSession.shared.downloadTask(with: url) { (location, response, error) in
                if let location = location {
                    // get path in temp directory for file
                    let tempFileURL = URL(string: "file://".appending(NSTemporaryDirectory()).appending(url.lastPathComponent))!

                    var attachment: UNNotificationAttachment?
                    do {
                        // move file into temp directory to be displayed by Notification Service Extension
                        if (FileManager.default.fileExists(atPath: tempFileURL.relativePath)) {
                            try FileManager.default.removeItem(at: tempFileURL)
                        }
                        try FileManager.default.moveItem(at: location, to: tempFileURL)

                        // generate image attachment
                        attachment = try UNNotificationAttachment(identifier: "tl_image", url: tempFileURL)
                    } catch let error {
                        print("Error: \(error)")
                    }

                    // Add the attachment to the notification content
                    if let attachment = attachment {
                        self.bestAttemptContent?.attachments = [attachment]
                    }
                }

                // render notification
                self.contentHandler!(self.bestAttemptContent!)
                }.resume()
        } else {
            // If there is no image payload render the notification as a normal notification.
            self.contentHandler!(self.bestAttemptContent!)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
