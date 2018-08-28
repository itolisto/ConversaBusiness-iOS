import SwiftyJSON

public class BusinessValidateId : JSONOperation<JSON> {
    
    public init(conversaID: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "public/businessValidateId", params: [:])
        self.request?.body = RequestBody.json(["conversaID" : conversaID])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
