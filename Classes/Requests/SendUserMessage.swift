import SwiftyJSON

public class SendUserMessage : JSONOperation<JSON> {
    
    public init(dictionary: [String : String]) {
        super.init()
        self.request = Request(method: .post, endpoint: "message/sendUserMessage", params: [:])
        self.request?.body = RequestBody.json(dictionary)
        self.onParseResponse = { json in
            return json
        }
    }
    
}
