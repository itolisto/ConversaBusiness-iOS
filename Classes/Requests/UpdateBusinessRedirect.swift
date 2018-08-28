import SwiftyJSON

public class UpdateBusinessRedirect : JSONOperation<JSON> {
    
    public init(businessId: String, redirect: Bool = false) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/updateBusinessRedirect", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId, "redirect" : redirect])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
