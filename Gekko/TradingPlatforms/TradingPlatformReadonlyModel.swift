//  Created by Sergii Mykhailov on 13/06/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

protocol TradingPlatformReadonlyThreadsafeModel : class {
 
    func allBalanceItems(handlingBlock:@escaping ([BalanceItem]) -> Void)

    func allDealsRange(forCurrencyPair currencyPair:CurrencyPair,
                       handlingBlock:@escaping (CandleInfo?) -> Void)

    func allBuyOrders(forCurrencyPair currencyPair:CurrencyPair,
                      handlingBlock:@escaping ([OrderInfo]?) -> Void)

    func allSellOrders(forCurrencyPair currencyPair:CurrencyPair,
                       handlingBlock:@escaping ([OrderInfo]?) -> Void)

    func candles(forCurrencyPair currencyPair:CurrencyPair,
                 handlingBlock:@escaping ([CandleInfo]?) -> Void)

    func userOrdersStatus(forCurrencyPair currencyPair:CurrencyPair,
                          handlingBlock:@escaping ([OrderStatusInfo]?) -> Void)

    func userOrderStatus(forOrderWithID orderID:String,
                         handlingBlock:@escaping (OrderStatus?) -> Void)

    func userDeals(forCurrencyPair currencyPair:CurrencyPair,
                   handlingBlock:@escaping ([OrderStatusInfo]?) -> Void)
}
