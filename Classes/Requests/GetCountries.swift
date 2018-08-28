import SwiftyJSON

public class GetCountries : JSONOperation<JSON> {
    
    public override init() {
        super.init()
        self.request = Request(method: .post, endpoint: "public/getCountries", params: [:])
        self.request?.body = RequestBody.json([:])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
