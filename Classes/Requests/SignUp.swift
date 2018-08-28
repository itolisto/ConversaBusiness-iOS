import SwiftyJSON

public class SignUp : JSONOperation<JSON> {
    
    public init(email: String, username: String, password: String, avatar: String, countryId: String, displayName: String, conversaID: String, categoryId: String) {
        super.init()
        self.request = Request(method: .post, endpoint: "users", params: [:])
        self.request?.body = RequestBody.json(["email" : email, "username" : username, "password" : password, "avatar" : avatar, "countryId" : countryId, "displayName" : displayName, "conversaID" : conversaID, "categoryId" : categoryId])
        self.onParseResponse = { json in
            return json
        }
    }
    
}
