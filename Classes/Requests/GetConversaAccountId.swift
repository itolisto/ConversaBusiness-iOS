import SwiftyJSON

public class GetConversaAccountId : JSONOperation<JSON> {
    
    public init(purpose: Int) {
        super.init()
        self.request = Request(method: .post, endpoint: "support/getConversaAccountId", params: [:])
        self.request?.body = RequestBody.json(["purpose" : purpose])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
