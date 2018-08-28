import SwiftyJSON

public class UpdateBusinessCategory : JSONOperation<JSON> {
    
    public init(businessId: String, categories: Date, limit: Int = 5) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/updateBusinessCategory", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId, "categories" : categories, "limit" : limit])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
