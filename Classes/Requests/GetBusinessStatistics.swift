import SwiftyJSON

public class GetBusinessStatistics : JSONOperation<JSON> {
    
    public init(businessId: String, language: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "business/getBusinessStatisticsAll", params: [:])
        self.request?.body = RequestBody.json(["businessId" : businessId, "language" : language])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
