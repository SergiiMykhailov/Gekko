//  Created by Sergii Mykhailov on 21/11/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUALoginSession : NSObject {

typealias LoginCompletionCallback = (Bool) -> Void

    static func loginIfNeeded(withPublicKey publicKey:String,
                              privateKey:String,
                              completionCallback:@escaping LoginCompletionCallback) {
        let postRequest = BTCTradeUAPostRequestFactory.makePostRequest(forURL:AuthorizationUrl, withPublicKey:publicKey, privateKey:privateKey)

        RestApiRequestsExecutor.performHTTPRequest(request:postRequest) { (replyItems, error) in
            let loginSucceeded = isLoginSucceeded(replyItems:replyItems)
            completionCallback(loginSucceeded)
        }
    }

    private static func isLoginSucceeded(replyItems:[String : Any]) -> Bool {
        let loginStatusValue = replyItems[LoginStatusJSONKey]
        if (loginStatusValue != nil) {
            if let loginStatusValueAsBoolean = loginStatusValue! as? Bool {
                return loginStatusValueAsBoolean
            }
        }
        return false
    }

    private static let AuthorizationUrl = "https://btc-trade.com.ua/api/auth"
    private static let LoginStatusJSONKey = "status"
}
