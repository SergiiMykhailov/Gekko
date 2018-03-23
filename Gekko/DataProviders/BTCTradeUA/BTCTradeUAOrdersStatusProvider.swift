//  Created by Sergii Mykhailov on 15/01/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAOrdersStatusProvider : BTCTradeUAProviderBase {

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
        
        let typeString = items[TypeKey] as? String
        if typeString == nil {
            return nil
        }
        
        var type:OrderType?
        switch typeString! {
        case "buy":
            type = OrderType.Buy
        case "sell":
            type = OrderType.Sell
        default:
            return nil
        }
        
        let statusString = items[StatusKey] as? String
        if statusString == nil {
            return nil
        }
        
        var status:OrderStatus?
        switch statusString! {
        case "processing":
            status = OrderStatus.Pending
        case "processed":
            status = OrderStatus.Completed
        case "canceled":
            status = OrderStatus.Canceled
        default:
            return nil
        }
        
        let cryptoCurrencyKey = type == .Sell ? "currency1" : "currency2"
        let currencyString = items[cryptoCurrencyKey] as? String
        
        let dateString = items[DateKey] as? String
        
        let initialCryptoCurrencyAmountKey = type == .Sell ? "sum1_history" : "sum2_history"
        let initialFiatCurrencyAmountKey = type == .Sell ? "sum2_history" : "sum1_history"
        let remainingAmountKey = type == .Sell ? "sum1" : "sum2"
        let initialCryptoCurrencyAmountString = items[initialCryptoCurrencyAmountKey] as? String
        let initialFiatCurrencyAmountString = items[initialFiatCurrencyAmountKey] as? String
        let remainingCryptoCurrencyAmountString = items[remainingAmountKey] as? String

        if id != nil && statusString != nil && dateString != nil &&
           initialCryptoCurrencyAmountString != nil && initialFiatCurrencyAmountString != nil &&
           remainingCryptoCurrencyAmountString != nil && typeString != nil && currencyString != nil {

            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = dateFormatter.date(from:dateString!)

            let currency = Currency(rawValue:currencyString! as Currency.RawValue)
            let initialCryptoCurrencyAmount = Double(initialCryptoCurrencyAmountString!)
            let initialFiatCurrencyAmount = Double(initialFiatCurrencyAmountString!)
            let remainingCryptoCurrencyAmount = status == .Completed ? 0 : Double(remainingCryptoCurrencyAmountString!)
            let price = initialFiatCurrencyAmount! / initialCryptoCurrencyAmount!

            if status != nil &&
                date != nil &&
                type != nil &&
                currency != nil &&
                remainingCryptoCurrencyAmount != nil {
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

    private static let OrderStatusSuffix = "order/status"

    private static let StatusKey = "status"
    private static let IDKey = "id"
    private static let TypeKey = "type"
    private static let DateKey = "pub_date"
}
