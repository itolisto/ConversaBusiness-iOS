import SwiftyJSON

public class GetBusinessCategories : JSONOperation<JSON> {
    
    public init(businessId: String, language: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/getBusinessCategories", params: [:])
        self.request?.body = RequestBody.json(["language" : language, "businessId" : businessId])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
