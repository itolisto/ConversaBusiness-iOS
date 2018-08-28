import SwiftyJSON

public class UpdateBusinessName : JSONOperation<JSON> {
    
    public init(businessId: String, displayName: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/updateBusinessName", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId, "displayName" : displayName])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
