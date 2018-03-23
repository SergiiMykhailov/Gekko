//  Created by Sergii Mykhailov on 22/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUADealsProvider : BTCTradeUAProviderBase {

    // MARK: Public methods and properties

typealias DealsCompletionCallback = ([OrderStatusInfo]?) -> Void

    public func retrieveCompletedDealsAsync(forCurrencyPair currencyPair:BTCTradeUACurrencyPair,
                                            startDate:Date,
                                            finishDate:Date,
                                            publicKey:String,
                                            privateKey:String,
                                            onCompletion:@escaping DealsCompletionCallback) {
        BTCTradeUADealsProvider.dateFormatter.dateFormat = "dd-MM-YYYY"
        let startDateString = BTCTradeUADealsProvider.dateFormatter.string(from:startDate)
        let finishDateString = BTCTradeUADealsProvider.dateFormatter.string(from:finishDate)
        let currentMilisecondsString = "\(UInt(Date().timeIntervalSince1970))"

        let suffix = "\(BTCTradeUADealsProvider.DealsSuffix)/\(currencyPair.rawValue)"
        let body = "ts=\(startDateString)&ts1=\(finishDateString)&_=\(currentMilisecondsString)"

        super.performUserRequestAsync(withSuffix:suffix,
                                      publicKey:publicKey,
                                      privateKey:privateKey,
                                      body:body) { [weak self] (items, error) in
            let result = self?.deals(fromResponseItems:items)
            onCompletion(result)
        }
    }

    // MARK: Internal methods

    fileprivate func deals(fromResponseItems items:[String : Any]) -> [OrderStatusInfo]? {
        return nil
    }

    // MARK: Internal fields

    private static let dateFormatter = DateFormatter()

    private static let DealsSuffix = "my_deals"
}
