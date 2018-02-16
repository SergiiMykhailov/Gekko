//  Created by Sergii Mykhailov on 15/01/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAOrdersStatusProvider : BTCTradeUAProviderBase {

typealias OrderStatusRetreivingCallback = ([OrderStatusInfo]) -> Void

    // MARK: Public methods and properties

typealias OrderStatusCallback = (OrderStatusInfo?) -> Void

    public func retrieveStatusAsync(forOrderWithID id:String,
                                    publicKey:String,
                                    privateKey:String,
                                    onCompletion:@escaping OrderStatusCallback) {
        let suffix = "\(BTCTradeUAOrdersStatusProvider.OrderStatusSuffix)/\(id)"

        super.performUserRequestAsync(withSuffix:suffix,
                                      publicKey:publicKey,
                                      privateKey:privateKey) { (items, error) in
            let orderInfo = BTCTradeUAOrdersStatusProvider.orderStatusInfo(fromResponseItems:items)
            onCompletion(orderInfo)
        }
    }

    // MARK: Internal methods

    fileprivate static func orderStatusInfo(fromResponseItems items:[String : Any]) -> OrderStatusInfo? {
        let id = items[IDKey] as? String
        let currencyString = items[CryptoCurrencyKey] as? String
        let statusString = items[StatusKey] as? String
        let dateString = items[DateKey] as? String
        let initialCryptoCurrencyAmount = items[InitialCryptoCurrencyAmountKey] as? Double
        let initialFiatCurrencyAmount = items[InitialFiatCurrencyAmountKey] as? Double
        let remainingCryptoCurrencyAmount = items[RemainingAmountKey] as? Double
        let typeString = items[TypeKey] as? String

        if id != nil && statusString != nil && dateString != nil &&
           initialCryptoCurrencyAmount != nil && initialFiatCurrencyAmount != nil &&
           remainingCryptoCurrencyAmount != nil && typeString != nil && currencyString != nil {

            var status:OrderStatus?
            switch statusString! {
            case "processing":
                status = OrderStatus.Pending
            case "processed":
                status = OrderStatus.Completed
            case "canceled":
                status = OrderStatus.Canceled
            default:
                status = nil
            }

            let date = dateFormatter.date(from:dateString!)

            var type:OrderType?
            switch typeString! {
            case "buy":
                type = OrderType.Buy
            case "sell":
                type = OrderType.Sell
            default:
                type = nil
            }

            let currency = Currency(rawValue:currencyString! as Currency.RawValue)
            let price = initialCryptoCurrencyAmount! / initialFiatCurrencyAmount!

            if status != nil && date != nil && type != nil && currency != nil {
                return OrderStatusInfo(id:id!,
                                       status:status!,
                                       date:date!,
                                       currency:currency!,
                                       initialAmount:initialCryptoCurrencyAmount!,
                                       remainingAmount:remainingCryptoCurrencyAmount!,
                                       price:price,
                                       type:type!)
            }
        }

        return nil
    }

    // MARK: Internal fields

    private static let dateFormatter = DateFormatter()

    private static let OrdersSuffix = "my_orders"
    private static let OrderStatusSuffix = "order/status"

    private static let RemainingAmountKey = "sum1"
    private static let InitialCryptoCurrencyAmountKey = "sum1_history"
    private static let InitialFiatCurrencyAmountKey = "sum2_history"
    private static let StatusKey = "status"
    private static let IDKey = "id"
    private static let CryptoCurrencyKey = "currency1"
    private static let TypeKey = "type"
    private static let DateKey = "pub_date"
}
