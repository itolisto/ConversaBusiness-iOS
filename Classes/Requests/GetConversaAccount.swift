import SwiftyJSON

public class GetConversaAccount : JSONOperation<JSON> {
    
    public init(accountId: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "support/getConversaAccount", params: [:])
        self.request?.body = RequestBody.json(["accountId" : accountId])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
