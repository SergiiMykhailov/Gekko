//  Created by Sergii Mykhailov on 22/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

typealias DealsCompletionCallback = ([OrderStatusInfo]) -> Void

class BTCTradeUADealsProvider : BTCTradeUAProviderBase {

    // MARK: Public methods and properties

    public func retrieveCompletedDealsAsync(forCurrencyPair currencyPair:BTCTradeUACurrencyPair,
                                            startDate:Date,
                                            finishDate:Date,
                                            publicKey:String,
                                            privateKey:String,
                                            onCompletion:@escaping DealsCompletionCallback) {
        BTCTradeUADealsProvider.dateFormatter.dateFormat = "dd-MM-YYYY"
        let startDateString = BTCTradeUADealsProvider.dateFormatter.string(from:startDate)
        let finishDateString = BTCTradeUADealsProvider.dateFormatter.string(from:finishDate)

        let suffix = "\(BTCTradeUADealsProvider.DealsSuffix)/\(currencyPair.rawValue)"
        let body = HTTPRequestUtils.makePostRequestBody(fromDictionary:["ts" : startDateString,
                                                                        "ts1" : finishDateString])

        super.performUserRequestAsync(withSuffix:suffix,
                                      publicKey:publicKey,
                                      privateKey:privateKey,
                                      body:body) { [weak self] (items, error) in
            if self != nil {
                let result = BTCTradeUAUtils.ordersStatus(fromResponseItems:items, withStatus:.Completed)
                onCompletion(result)
            }
        }
    }

    // MARK: Internal fields

    private static let dateFormatter = DateFormatter()

    private static let DealsSuffix = "my_deals"
}
