import SwiftyJSON

public class UpdateBusinessAvatar : JSONOperation<JSON> {
    
    public init(businessId: String, avatar: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/updateBusinessStatus", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId, "avatar" : avatar])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
