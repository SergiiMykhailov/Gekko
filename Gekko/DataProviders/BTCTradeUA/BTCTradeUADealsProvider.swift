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
        let body = "ts=\(startDateString)&ts1=\(finishDateString)"

        super.performUserRequestAsync(withSuffix:suffix,
                                      publicKey:publicKey,
                                      privateKey:privateKey,
                                      body:body) { [weak self] (items, error) in
            if self != nil {
                let result = self!.deals(fromResponseItems:items)
                onCompletion(result)
            }
        }
    }

    // MARK: Internal methods

    fileprivate func deals(fromResponseItems items:[String : Any]) -> [OrderStatusInfo] {
        var result = [OrderStatusInfo]()

        for item in items.enumerated() {
            if let dealsCollection = item.element.value as? [Any] {
                for dealItem in dealsCollection {
                    if let singleDealDictionary = dealItem as? [String : Any] {
                        if let dealInfo = BTCTradeUAUtils.orderInfo(fromDictionary:singleDealDictionary) {
                            if let id = singleDealDictionary[BTCTradeUADealsProvider.IDKey] as? UInt32 {
                                if let date = BTCTradeUAUtils.publishDate(fromDictionary:singleDealDictionary) {
                                    let itemToInsert = OrderStatusInfo(id:"\(id)",
                                                                       status:.Completed,
                                                                       date:date,
                                                                       currency:.UAH,
                                                                       initialAmount:dealInfo.cryptoCurrencyAmount,
                                                                       remainingAmount:0.0,
                                                                       price:dealInfo.price,
                                                                       type:dealInfo.isBuy ? OrderType.Buy : OrderType.Sell)

                                    result.append(itemToInsert)
                                }
                            }
                        }
                    }
                }
            }
        }

        return result
    }

    // MARK: Internal fields

    private static let dateFormatter = DateFormatter()

    private static let DealsSuffix = "my_deals"

    private static let IDKey = "id"

}
