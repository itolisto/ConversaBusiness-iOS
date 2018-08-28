import SwiftyJSON

public class GetBusinessProfile : JSONOperation<JSON> {
    
    public init(businessId: String, count: Bool = false) {
        super.init()
        self.request = Request(method: .post, endpoint: "general/getBusinessProfile", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId, "count" : count])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
