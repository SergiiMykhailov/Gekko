//  Created by Sergii Mykhailov on 29/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

struct CurrencyPair : Hashable, Equatable {
    var primaryCurrency:Currency
    var secondaryCurrency:Currency

    var hashValue:Int {
        return primaryCurrency.hashValue ^ secondaryCurrency.hashValue
    }

    func toString() -> String {
        return "\(secondaryCurrency.rawValue.lowercased)_\(primaryCurrency.rawValue.lowercased)"
    }

    static func ==(lhs:CurrencyPair, rhs:CurrencyPair) -> Bool {
        return lhs.primaryCurrency == rhs.primaryCurrency &&
               lhs.secondaryCurrency == rhs.secondaryCurrency
    }
}

typealias CandlesCompletionCallback = ([CandleInfo]) -> Void
typealias BalanceCompletionCallback = (BalanceItem?) -> Void
typealias CompletedOrdersCompletionCallback = ([OrderInfo], CandleInfo?) -> Void
typealias PendingOrdersCompletionCallback = ([OrderInfo]) -> Void
typealias OrderCompletionCallback = (String?) -> Void
typealias CancelOrderCompletionCallback = () -> Void
typealias UserOrderStatusCallback = (OrderStatusInfo?) -> Void
typealias UserOrdersCallback = ([OrderStatusInfo]?) -> Void
typealias UserDealsCallback = ([OrderStatusInfo]?) -> Void

protocol TradingPlatform : class {

    var mainCurrency:Currency { get }

    var supportedCurrencyPairs:[CurrencyPair] { get }

    var isAuthorized:Bool { get }

    var assetProvider:AssetProvider? { get }

    var accountManager:AccountManager? { get }

    func retrieveCandlesAsync(forPair pair:CurrencyPair,
                              onCompletion:@escaping CandlesCompletionCallback)

    func retriveBalanceAsync(forCurrency currency:Currency,
                             onCompletion:@escaping BalanceCompletionCallback)

    func retrieveDealsAsync(forPair pair:CurrencyPair,
                            onCompletion:@escaping CompletedOrdersCompletionCallback)

    func retrieveBuyOrdersAsync(forPair pair:CurrencyPair,
                                onCompletion:@escaping PendingOrdersCompletionCallback)

    func retrieveSellOrdersAsync(forPair pair:CurrencyPair,
                                 onCompletion:@escaping PendingOrdersCompletionCallback)

    func performBuyOrderAsync(forPair pair:CurrencyPair,
                              amount:Double,
                              price:Double,
                              onCompletion:@escaping OrderCompletionCallback)

    func performSellOrderAsync(forPair pair:CurrencyPair,
                               amount:Double,
                               price:Double,
                               onCompletion:@escaping OrderCompletionCallback)

    func retrieveOrderStatusAsync(withID id:String,
                                  onCompletion:@escaping UserOrderStatusCallback)

    func retrieveUserOrdersAsync(forPair pair:CurrencyPair,
                                 onCompletion:@escaping UserOrdersCallback)

    func retrieveUserDealsAsync(forPair pair:CurrencyPair,
                                fromDate:Date,
                                toDate:Date,
                                onCompletion:@escaping UserDealsCallback)

    func cancelOrderAsync(withID id:String,
                          onCompletion:@escaping CancelOrderCompletionCallback)
}

typealias AssetAddressCompletionCallback = ([String]?) -> Void

protocol AssetProvider : class {

    func retriveAssetAddressAsync(currency:Currency,
                                  onCompletion:@escaping AssetAddressCompletionCallback)

}

enum AccountRegistrationStatus {
    case Succeeded
    case AccountAlreadyExists
    case UnknownError
}

typealias AccountRegistrationCompletionCallback = (AccountRegistrationStatus?, [String : Any]) -> Void

protocol AccountManager : class {

    func registerAccount(withEmail email:String,
                         phoneNumber:String,
                         password:String,
                         onCompletion:@escaping AccountRegistrationCompletionCallback)
}
