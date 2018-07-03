//  Created by Sergii Mykhailov on 22/11/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUABalanceProvider : BTCTradeUAProviderBase {

typealias BalanceCompletionCallback = ([BalanceItem]) -> Void

    // MARK: Public methods and properties

    public func retriveBalanceAsync(withPublicKey publicKey:String,
                                    privateKey:String,
                                    onCompletion:@escaping BalanceCompletionCallback) {
        super.performUserRequestAsync(withSuffix:BTCTradeUABalanceProvider.BalanceSuffix,
                                      publicKey:publicKey,
                                      privateKey:privateKey) { [weak self] (items, error) in
            if self != nil {
                let balanceItems = self!.balance(fromResponseItems:items)
                onCompletion(balanceItems)
            }
        }
    }

    // MARK: Internal methods

    fileprivate func balance(fromResponseItems items:[String : Any]) -> [BalanceItem] {
        var result = [BalanceItem]()

        let accounts = items[BTCTradeUABalanceProvider.AccountsKey]
        if accounts != nil {
            if let accountsDictionary = accounts as? [[String : Any]] {
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.UAH,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.BTC,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.ETH,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.LTC,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.XMR,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.DOGE,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.DASH,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.SIB,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.KRB,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.USDT,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.ZEC,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.BCH,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.ETC,
                                     andStoreInCollection:&result)
                retrieveBalanceValue(fromJSONItems:accountsDictionary,
                                     forCurrency:.NVC,
                                     andStoreInCollection:&result)
            }
        }

        return result;
    }

    fileprivate func retrieveBalanceValue(fromJSONItems items:[[String : Any]],
                                          forCurrency currency:Currency,
                                          andStoreInCollection sink:inout [BalanceItem]) {
        let balance = balanceItem(fromJSONItems:items, forCurrency:currency)
        appendBalanceItem(item:balance, toCollection: &sink)
    }

    fileprivate func balanceItem(fromJSONItems items:[[String : Any]],
                                 forCurrency currency:Currency) -> BalanceItem? {
        for item in items {
            let currencyName = item[BTCTradeUABalanceProvider.CurrencyKey] as? String
            if currencyName != nil && currencyName! == currency.rawValue as String {
                let balanceString = item[BTCTradeUABalanceProvider.BalanceKey] as? String
                if balanceString != nil {
                    if let balanceValue = Double(balanceString!) {
                        return BalanceItem(currency:currency, amount:balanceValue)
                    }
                }
            }
        }

        return nil;
    }

    fileprivate func appendBalanceItem(item:BalanceItem?, toCollection sink:inout [BalanceItem]) {
        if item != nil {
            sink.append(item!)
        }
    }

    // MARK: Internal fields and properties

    private static let BalanceSuffix = "balance"
    private static let AccountsKey = "accounts"
    private static let CurrencyKey = "currency"
    private static let BalanceKey = "balance"
}
