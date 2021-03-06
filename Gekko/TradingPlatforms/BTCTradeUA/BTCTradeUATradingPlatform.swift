//  Created by Sergii Mykhailov on 29/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUATradingPlatform : TradingPlatform,
                                  AssetsHandler,
                                  AccountManager {

    // MARK: Public methods and properties

    var publicKey:String?
    var privateKey:String?

    // MARK: TradingPlatform implementation

    public var isAuthorized:Bool {
        return publicKey != nil && !publicKey!.isEmpty && privateKey != nil && !publicKey!.isEmpty
    }

    public var mainCurrency:Currency {
        return .UAH
    }

    public var supportedCurrencies:[Currency] {
        return BTCTradeUATradingPlatform.SupportedCurrencies
    }

    public var supportedCurrencyPairs:[CurrencyPair] {
        return BTCTradeUATradingPlatform.SupportedCurrencyPairs
    }

    public var assetsHandler:AssetsHandler? {
        return self
    }

    public var accountManager:AccountManager? {
        return self
    }

    public func retrieveCandlesAsync(forPair pair:CurrencyPair,
                                     onCompletion:@escaping CandlesCompletionCallback) {
        if let convertedPair = platformCurrencyPair(forGenericCurrencyPair:pair) {
            candlesProvider.retrieveCandlesAsync(forPair:convertedPair,
                                                 withCompletionHandler:onCompletion)
        }
        else {
            onCompletion([CandleInfo]())
        }
    }

    public func retriveBalanceAsync(forCurrency currency:Currency,
                                    onCompletion:@escaping BalanceCompletionCallback) {
        if !isAuthorized {
            onCompletion(nil)
            return
        }

        let handleBalanceRetrieving = { () -> Bool in
            let cachedBalance = self.currencyToBalanceMap[currency]

            if cachedBalance != nil && cachedBalance! != nil {
                // We have balance item in cache.
                // Return it for now and mark balance for the specified currency
                // as 'dirty' via assigning 'nil' to curresponding item in map
                // so it will be retrieved from server next time.
                self.currencyToBalanceMap[currency] = nil
                onCompletion(BalanceItem(currency:currency, amount:cachedBalance!!))
                return true
            }

            return false
        }

        let cachedValueRetrieved = handleBalanceRetrieving()
        if !cachedValueRetrieved {
            // There is no balance item in cache.
            // We should request all balances from server
            // and mark the specified one as 'dirty'

            if !isRetrievingBalance {
                isRetrievingBalance = true
                balanceProvider.retriveBalanceAsync(withPublicKey:publicKey!,
                                                    privateKey:privateKey!) {
                    [weak self] (balanceItems) in
                    for balanceItem in balanceItems {
                        self?.currencyToBalanceMap[balanceItem.currency] = balanceItem.amount

                        if let storedCompletionCallback = self!.currencyToBalanceRetrievingCompletionCallbackMap[balanceItem.currency] {
                            storedCompletionCallback(balanceItem)
                        }
                    }

                    _ = handleBalanceRetrieving()

                    self?.isRetrievingBalance = false
                    self?.currencyToBalanceRetrievingCompletionCallbackMap.removeAll()
                }
            }
            else {
                currencyToBalanceRetrievingCompletionCallbackMap[currency] = onCompletion
            }
        }
    }

    public func retrieveDealsAsync(forPair pair:CurrencyPair,
                                   onCompletion:@escaping CompletedOrdersCompletionCallback) {
        if let convertedPair = platformCurrencyPair(forGenericCurrencyPair:pair) {
            orderProvider.retrieveDealsAsync(forPair:convertedPair,
                                             withCompletionHandler: { (orders, candle) in
                onCompletion(orders, candle)
            })
        }
        else {
            onCompletion([OrderInfo](), nil)
        }
    }

    public func retrieveBuyOrdersAsync(forPair pair:CurrencyPair,
                                       onCompletion:@escaping PendingOrdersCompletionCallback) {
        if let convertedPair = platformCurrencyPair(forGenericCurrencyPair:pair) {
            orderProvider.retrieveBuyOrdersAsync(forPair:convertedPair,
                                                 withCompletionHandler:onCompletion)
        }
        else {
            onCompletion([OrderInfo]())
        }
    }

    public func retrieveSellOrdersAsync(forPair pair:CurrencyPair,
                                        onCompletion:@escaping PendingOrdersCompletionCallback) {
        if let convertedPair = platformCurrencyPair(forGenericCurrencyPair:pair) {
            orderProvider.retrieveSellOrdersAsync(forPair:convertedPair,
                                                  withCompletionHandler:onCompletion)
        }
        else {
            onCompletion([OrderInfo]())
        }
    }

    func retrieveUserOrdersAsync(forPair pair:CurrencyPair,
                                 onCompletion:@escaping UserOrdersCallback) {
        if !isAuthorized {
            onCompletion(nil)
            return
        }

        if let convertedPair = platformCurrencyPair(forGenericCurrencyPair:pair) {
            userOrdersProvider.retrieveUserOrdersAsync(forPair:convertedPair,
                                                       publicKey:publicKey!,
                                                       privateKey:privateKey!,
                                                       onCompletion:onCompletion)
        }
        else {
            onCompletion(nil)
        }
    }

    public func performBuyOrderAsync(forPair pair:CurrencyPair,
                                     amount:Double,
                                     price:Double,
                                     onCompletion:@escaping OrderCompletionCallback) {
        if !isAuthorized {
            onCompletion(nil)
            return
        }

        let currency = pair.primaryCurrency == mainCurrency ? pair.secondaryCurrency : pair.primaryCurrency
        orderProvider.performBuyOrderAsync(forCurrency:currency,
                                           amount:amount,
                                           price:price,
                                           publicKey:publicKey!,
                                           privateKey:privateKey!,
                                           onCompletion:onCompletion)
    }

    public func performSellOrderAsync(forPair pair:CurrencyPair,
                                      amount:Double,
                                      price:Double,
                                      onCompletion:@escaping OrderCompletionCallback) {
        if !isAuthorized {
            onCompletion(nil)
            return
        }

        let currency = pair.primaryCurrency == mainCurrency ? pair.secondaryCurrency : pair.primaryCurrency
        orderProvider.performSellOrderAsync(forCurrency:currency,
                                            amount:amount,
                                            price:price,
                                            publicKey:publicKey!,
                                            privateKey:privateKey!,
                                            onCompletion:onCompletion)
    }

    public func cancelOrderAsync(withID id:String,
                                 onCompletion:@escaping CancelOrderCompletionCallback) {
        if !isAuthorized {
            onCompletion()
            return
        }

        orderProvider.cancelOrderAsync(withID:id,
                                       publicKey:publicKey!,
                                       privateKey:privateKey!,
                                       onCompletion:onCompletion)
    }

    public func retrieveOrderStatusAsync(withID id:String,
                                         onCompletion:@escaping UserOrderStatusCallback) {
        if !isAuthorized {
            onCompletion(nil)
            return
        }

        ordersStatusProvider.retrieveStatusAsync(forOrderWithID:id,
                                                 publicKey:publicKey!,
                                                 privateKey:privateKey!,
                                                 onCompletion:onCompletion)
    }

    public func retrieveUserDealsAsync(forPair pair:CurrencyPair,
                                       fromDate:Date,
                                       toDate:Date,
                                       onCompletion:@escaping UserDealsCallback) {
        if !isAuthorized {
            onCompletion(nil)
            return
        }

        if let convertedPair = platformCurrencyPair(forGenericCurrencyPair:pair) {
            userDealsProvider.retrieveCompletedDealsAsync(forCurrencyPair:convertedPair,
                                                          startDate:fromDate,
                                                          finishDate:toDate,
                                                          publicKey:publicKey!,
                                                          privateKey:privateKey!,
                                                          onCompletion: {
                (deals) in

                // Deals provider returns data with invalid cryptocurrency.
                // Need to update.
                for deal in deals {
                    deal.currency = pair.secondaryCurrency
                }

                onCompletion(deals)
            })
        }
        else {
            onCompletion(nil)
        }
    }

    // MARK: AssetProvider implementation

    func retriveAssetAddressAsync(currency:Currency, onCompletion:@escaping AssetAddressCompletionCallback) {
        if !isAuthorized {
            onCompletion(nil)
            return
        }

        assetKeysProvider.retriveAssetAddressAsync(withPublicKey:publicKey!,
                                                   privateKey:privateKey!,
                                                   currency:currency,
                                                   onCompletion:onCompletion)
    }

    // MARK: AccountManager implementation

    func registerAccount(withEmail email:String,
                         password:String,
                         onCompletion:@escaping AccountRegistrationCompletionCallback) {
        accountRegistrator.registerAccount(withEmail:email,
                                           password:password,
                                           onCompletion:onCompletion)
    }

    // MARK: Internal methods

    func platformCurrencyPair(forGenericCurrencyPair pair:CurrencyPair) -> BTCTradeUACurrencyPair? {
        assert(pair.primaryCurrency == .UAH)

        return BTCTradeUATradingPlatform.CurrencyToCurrencyPairMap[pair.secondaryCurrency]
    }

    // MARK: Internal fields

    fileprivate let balanceProvider = BTCTradeUABalanceProvider()
    fileprivate let candlesProvider = BTCTradeUACandlesProvider()
    fileprivate let orderProvider = BTCTradeUAOrderProvider()
    fileprivate let ordersStatusProvider = BTCTradeUAOrdersStatusProvider()
    fileprivate let userDealsProvider = BTCTradeUADealsProvider()
    fileprivate let userOrdersProvider = BTCTradeUAUserOrdersProvider()
    fileprivate let assetKeysProvider = BTCTradeUAAssetsProvider()
    fileprivate let accountRegistrator = BTCTradeUAAccountRegistrator()

    fileprivate var currencyToBalanceMap = [Currency : Double?]()

    fileprivate var isRetrievingBalance = false
    fileprivate var currencyToBalanceRetrievingCompletionCallbackMap = [Currency : BalanceCompletionCallback]()

    fileprivate static let SupportedCurrencies = [Currency.BTC,
                                                  Currency.ETH,
                                                  Currency.LTC,
                                                  Currency.XMR,
                                                  Currency.DOGE,
                                                  Currency.DASH,
                                                  Currency.ZEC,
                                                  Currency.BCH,
                                                  Currency.ETC,
                                                  Currency.KRB,
                                                  Currency.USDT]

    fileprivate static let SupportedCurrencyPairs:[CurrencyPair] = [
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.BTC),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.ETH),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.LTC),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.XMR),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.DOGE),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.DASH),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.ZEC),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.BCH),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.ETC),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.KRB),
         CurrencyPair(primaryCurrency:Currency.UAH, secondaryCurrency:Currency.USDT)]

    fileprivate static let CurrencyToCurrencyPairMap = [Currency.BTC : BTCTradeUACurrencyPair.BtcUah,
                                                        Currency.ETH : BTCTradeUACurrencyPair.EthUah,
                                                        Currency.LTC : BTCTradeUACurrencyPair.LtcUah,
                                                        Currency.XMR : BTCTradeUACurrencyPair.XmrUah,
                                                        Currency.DOGE : BTCTradeUACurrencyPair.DogeUah,
                                                        Currency.DASH : BTCTradeUACurrencyPair.DashUah,
                                                        Currency.SIB : BTCTradeUACurrencyPair.SibUah,
                                                        Currency.KRB : BTCTradeUACurrencyPair.KrbUah,
                                                        Currency.ZEC : BTCTradeUACurrencyPair.ZecUah,
                                                        Currency.BCH : BTCTradeUACurrencyPair.BchUah,
                                                        Currency.ETC : BTCTradeUACurrencyPair.EtcUah,
                                                        Currency.NVC : BTCTradeUACurrencyPair.NvcUah,
                                                        Currency.USDT : BTCTradeUACurrencyPair.UsdtUah]
}
