import SwiftyJSON

public class UpdateBusinessStatus : JSONOperation<JSON> {
    
    public init(businessId: String, status: Int = 5) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/updateBusinessStatus", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId, "status" : status])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
