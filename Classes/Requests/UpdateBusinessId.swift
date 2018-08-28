import SwiftyJSON

public class UpdateBusinessId : JSONOperation<JSON> {
    
    public init(businessId: String, conversaId: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/updateBusinessId", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId, "conversaId" : conversaId])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
