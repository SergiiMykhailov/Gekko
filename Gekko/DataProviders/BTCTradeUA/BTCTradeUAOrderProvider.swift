//  Created by Sergii Mykhailov on 11/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAOrderProvider : BTCTradeUAProviderBase {

typealias OrderCompletionCallback = (String?) -> Void
typealias CompletedOrdersCompletionCallback = ([OrderInfo], Double, Double) -> Void
typealias PendingOrdersCompletionCallback = ([OrderInfo]) -> Void
typealias CancelOrderCompletionCallback = () -> Void

    // MARK: Public methods and properties

    public func retrieveDealsAsync(forPair pair:BTCTradeUACurrencyPair,
                                   withCompletionHandler completionHandler:@escaping CompletedOrdersCompletionCallback)
    {
        let dealsSuffix = String(format:"deals/%@", pair.rawValue)

        super.performGetRequestAsync(withSuffix:dealsSuffix) { [weak self] (items, _) in
            if (self != nil) {
                let dealsCollection = self!.deals(fromResponseItems:items)

                var minPrice:Double = 0
                var maxPrice:Double = 0
                self!.minMaxPrice(forDeals:dealsCollection, minValue:&minPrice, maxValue:&maxPrice)

                completionHandler(dealsCollection, minPrice, maxPrice)
            }
        }
    }

    public func retrieveBuyOrdersAsync(forPair pair:BTCTradeUACurrencyPair,
                                       withCompletionHandler completionHandler:@escaping PendingOrdersCompletionCallback) {
        let ordersSuffix = String(format:"trades/buy/%@", pair.rawValue)

        handleOrders(withSuffix:ordersSuffix, isBuy:true, withCompletion:completionHandler)
    }

    public func retrieveSellOrdersAsync(forPair pair:BTCTradeUACurrencyPair,
                                        withCompletionHandler completionHandler:@escaping PendingOrdersCompletionCallback) {
        let ordersSuffix = String(format:"trades/sell/%@", pair.rawValue)

        handleOrders(withSuffix:ordersSuffix, isBuy:false, withCompletion:completionHandler)
    }

    public func performBuyOrderAsync(forCurrency currency:Currency,
                                     amount:Double,
                                     price:Double,
                                     publicKey:String,
                                     privateKey:String,
                                     onCompletion:@escaping OrderCompletionCallback) {
        performOrderAsync(forCurrency:currency,
                          amount:amount,
                          price:price,
                          publicKey:publicKey,
                          privateKey:privateKey,
                          urlSuffix:BTCTradeUAOrderProvider.BuySuffix,
                          onCompletion:onCompletion)
    }

    public func performSellOrderAsync(forCurrency currency:Currency,
                                      amount:Double,
                                      price:Double,
                                      publicKey:String,
                                      privateKey:String,
                                      onCompletion:@escaping OrderCompletionCallback) {
        performOrderAsync(forCurrency:currency,
                          amount:amount,
                          price:price,
                          publicKey:publicKey,
                          privateKey:privateKey,
                          urlSuffix:BTCTradeUAOrderProvider.SellSuffix,
                          onCompletion:onCompletion)
    }

    public func cancelOrderAsync(withID id:String,
                                 publicKey:String,
                                 privateKey:String,
                                 onCompletion:@escaping CancelOrderCompletionCallback) {
        let cancelSuffix = "remove/order/\(id)"
        
        super.performUserRequestAsync(withSuffix:cancelSuffix,
                                      publicKey:publicKey,
                                      privateKey:privateKey) { (items, _) in
            onCompletion()
        }
    }
    
    // MARK: Internal methods

    fileprivate func handleOrders(withSuffix suffix:String,
                                  isBuy:Bool,
                                  withCompletion completionCallback:@escaping PendingOrdersCompletionCallback) {
        super.performGetRequestAsync(withSuffix:suffix) {
            [weak self] (items, _) in
            if self != nil {
                if let ordersList = items[BTCTradeUAOrderProvider.OrdersListKey] as? [Any] {

                    var orders = [OrderInfo]()

                    for order in ordersList {
                        if let orderDictionary = order as? [String : String] {
                            let cryptocurrencyAmount = orderDictionary[BTCTradeUAOrderProvider.OrderAmountKey]
                            let price = orderDictionary[BTCTradeUAOrderProvider.FiatCurrencyPriceKey]
                            let fiatCurrencyAmount = orderDictionary[BTCTradeUAOrderProvider.FiatCurrencyAmountKey]

                            if cryptocurrencyAmount != nil &&
                               price != nil &&
                                fiatCurrencyAmount != nil {

                                let cryptocurrencyAmountValue = Double(cryptocurrencyAmount!)
                                let priceValue = Double(price!)
                                let fiatCurrencyAmountValue = Double(fiatCurrencyAmount!)

                                if cryptocurrencyAmountValue != nil &&
                                   priceValue != nil &&
                                   fiatCurrencyAmountValue != nil {
                                    orders.append(OrderInfo(fiatCurrencyAmount:fiatCurrencyAmountValue!,
                                                            cryptoCurrencyAmount:cryptocurrencyAmountValue!,
                                                            price:priceValue!,
                                                            user:"",
                                                            isBuy:isBuy))
                                }
                            }
                        }
                    }

                    completionCallback(orders)
                }
            }
        }
    }

    fileprivate func performOrderAsync(forCurrency currency:Currency,
                                       amount:Double,
                                       price:Double,
                                       publicKey:String,
                                       privateKey:String,
                                       urlSuffix:String,
                                       onCompletion:@escaping OrderCompletionCallback) {
        let body = requestBody(forCurrency:currency,
                               amount:amount,
                               price:price)

        var currencyPair:BTCTradeUACurrencyPair?
        switch currency {
        case .BTC:
            currencyPair = .BtcUah
        case .ETH:
            currencyPair = .EthUah
        case .LTC:
            currencyPair = .LtcUah
        case .XMR:
            currencyPair = .XmrUah
        case .DOGE:
            currencyPair = .DogeUah
        case .DASH:
            currencyPair = .DashUah
        case .SIB:
            currencyPair = .SibUah
        case .KRB:
            currencyPair = .KrbUah
        case .ZEC:
            currencyPair = .ZecUah
        case .BCH:
            currencyPair = .BchUah
        case .ETC:
            currencyPair = .EtcUah
        case .NVC:
            currencyPair = .NvcUah
        case .UAH:
            currencyPair = nil
        }

        let suffixWithCurrency = "\(urlSuffix)/\(currencyPair!.rawValue)"

        super.performUserRequestAsync(withSuffix:suffixWithCurrency,
                                      publicKey:publicKey,
                                      privateKey:privateKey,
                                      body:body) { [weak self] (items, _) in
            let orderIdValue = self?.orderId(fromResponseItems:items)

            onCompletion(orderIdValue)
        }
    }

    fileprivate func requestBody(forCurrency currency:Currency,
                                 amount:Double,
                                 price:Double) -> String {
        return String(format:"count=%.8f&price=%.2f&currency1=UAH&currency=%@",
                      amount,
                      price,
                      currency.rawValue)
    }

    fileprivate func orderId(fromResponseItems items:[String : Any]) -> String? {
        let orderValue = items[BTCTradeUAOrderProvider.OrderIdKey] as? Int64

        if orderValue != nil {
            return String(orderValue!)
        }

        return nil;
    }

    fileprivate func deals(fromResponseItems items:[String : Any]) -> [OrderInfo] {
        var result = [OrderInfo]()

        for (_, value) in items {
            if let deals = value as? [Any] {
                for deal in deals {
                    if let singleDealDictionary = deal as? [String : Any] {
                        let traditionalCurrencyAmount =
                            singleDealDictionary[BTCTradeUAOrderProvider.TraditionalCurrencyAmountKey] as? String
                        let cryptoCurrencyAmount =
                            singleDealDictionary[BTCTradeUAOrderProvider.CryptoCurrencyAmountKey] as? String
                        let price = singleDealDictionary[BTCTradeUAOrderProvider.PriceKey] as? String
                        let date = singleDealDictionary[BTCTradeUAOrderProvider.DateKey] as? String
                        let user = singleDealDictionary[BTCTradeUAOrderProvider.UserKey] as? String
                        let type = singleDealDictionary[BTCTradeUAOrderProvider.DealTypeKey] as? String

                        if traditionalCurrencyAmount != nil &&
                            cryptoCurrencyAmount != nil &&
                            price != nil &&
                            date != nil &&
                            type != nil {
                            let traditionalCurrencyAmountCasted = Double(traditionalCurrencyAmount!)
                            let cryptoCurrencyAmountCasted = Double(cryptoCurrencyAmount!)
                            let priceCasted = Double(price!)
                            let isBuy = type! == "buy"

                            if traditionalCurrencyAmountCasted != nil &&
                                cryptoCurrencyAmountCasted != nil &&
                                priceCasted != nil {
                                let itemToInsert =
                                    OrderInfo(fiatCurrencyAmount:traditionalCurrencyAmountCasted!,
                                              cryptoCurrencyAmount:cryptoCurrencyAmountCasted!,
                                              price:priceCasted!,
                                              user:user!,
                                              isBuy:isBuy)

                                result.append(itemToInsert)
                            }
                        }
                    }
                }
            }
        }

        return result
    }

    fileprivate func minMaxPrice(forDeals deals:[OrderInfo],
                                 minValue:inout Double,
                                 maxValue:inout Double) -> Void {
        minValue = Double.greatestFiniteMagnitude
        maxValue = -Double.greatestFiniteMagnitude

        for dealInfo in deals {
            if dealInfo.isBuy && dealInfo.fiatCurrencyAmount > BTCTradeUAOrderProvider.MinFiatCurrencyAmount {
                minValue = min(minValue, dealInfo.price)
                maxValue = max(maxValue, dealInfo.price)
            }
        }
    }

    // MARK: Internal fields

    fileprivate static let BuySuffix = "buy"
    fileprivate static let SellSuffix = "sell"

    fileprivate static let TraditionalCurrencyAmountKey = "amnt_base"
    fileprivate static let CryptoCurrencyAmountKey = "amnt_trade"
    fileprivate static let PriceKey = "price"
    fileprivate static let DateKey = "pub_date"
    fileprivate static let UserKey = "user"
    fileprivate static let DealTypeKey = "type"

    fileprivate static let OrdersListKey = "list"
    fileprivate static let OrderAmountKey = "currency_trade"
    fileprivate static let FiatCurrencyPriceKey = "price"
    fileprivate static let FiatCurrencyAmountKey = "currency_base"

    fileprivate static let OrderIdKey = "order_id"
    
    fileprivate static let MinFiatCurrencyAmount:Double = 20
}
