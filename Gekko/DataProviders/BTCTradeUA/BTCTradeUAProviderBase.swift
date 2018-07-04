//  Created by Sergii Mykhailov on 21/11/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAProviderBase : NSObject {

    // MARK: Public methods and properties

    public func performGetRequestAsync(withSuffix suffix:String, onCompletion:@escaping ServiceResponse) {
        let requestURL = String(format: "%@%@?MerchantID=iOS_Gekko", BTCTradeUAProviderBase.btcTradeBaseUrl, suffix)

        RestApiRequestsExecutor.performHTTPGetRequest(path:requestURL, onCompletion:onCompletion)
    }

    public func performUserRequestAsync(withSuffix suffix:String,
                                        publicKey:String,
                                        privateKey:String,
                                        body:String = "",
                                        onCompletion:@escaping ServiceResponse) {
        let requestURL = String(format: "%@%@", BTCTradeUAProviderBase.btcTradeBaseUrl, suffix)

        let request = BTCTradeUAPostRequestFactory.makePostRequest(forURL:requestURL,
                                                                   withPublicKey:publicKey,
                                                                   privateKey:privateKey,
                                                                   body:body)

        RestApiRequestsExecutor.performHTTPRequest(request:request, onCompletion:onCompletion)
    }

    // MARK: Internal fields

    private static let btcTradeBaseUrl = "https://btc-trade.com.ua/api/"
}
