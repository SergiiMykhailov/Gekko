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
                let uahBalance = balanceItem(fromJSONItems:accountsDictionary, forCurrency:.UAH)
                appendBalanceItem(item:uahBalance, toCollection:&result)

                let btcBalance = balanceItem(fromJSONItems:accountsDictionary, forCurrency:.BTC)
                appendBalanceItem(item:btcBalance, toCollection:&result)

                let ethBalance = balanceItem(fromJSONItems:accountsDictionary, forCurrency:.ETH)
                appendBalanceItem(item:ethBalance, toCollection:&result)

                let ltcBalance = balanceItem(fromJSONItems:accountsDictionary, forCurrency:.LTC)
                appendBalanceItem(item:ltcBalance, toCollection:&result)
            }
        }

        return result;
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
