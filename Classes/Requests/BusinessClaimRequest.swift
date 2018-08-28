import SwiftyJSON

public class BusinessClaimRequest : JSONOperation<JSON> {
    
    public init(businessId: String, name: String, email: String, position: String, contact: String) {
        super.init()

        self.request = Request(method: .post, endpoint: "public/businessClaimRequest", params: [:])
        self.request?.body = RequestBody.json([
        										"businessId" : businessId,
        										"name" : name,
        										"email" : email,
        										"position" : position,
        										"contact" : contact
    										])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
