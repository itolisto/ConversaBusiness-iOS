import SwiftyJSON

public class UpdateBusinessLastConnection : JSONOperation<JSON> {
    
    public init(businessId: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/updateBusinessLastConnection", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
