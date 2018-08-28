import SwiftyJSON

public class GetOnlyCategories : JSONOperation<JSON> {
    
    public init(language: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "public/getOnlyCategories", params: [:])
        self.request?.body = RequestBody.json(["language" : language])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
