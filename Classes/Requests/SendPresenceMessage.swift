import SwiftyJSON

public class SendPresenceMessage : JSONOperation<JSON> {
    
    public init(userId: String, channelName: String, isTyping: Bool = false) {
        super.init()
        self.request = Request(method: .post, endpoint: "message/sendPresenceMessage", params: [:])
        self.request?.body = RequestBody.json(["userId" : userId, "channelName" : channelName, "isTyping" : isTyping])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
