//  Created by Sergii Mykhailov on 29/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformModel : NSObject {

    public var currencyPairToCompletedOrdersMap = [CurrencyPair : CandleInfo]()
    public var currencyPairToBuyOrdersMap = [CurrencyPair : [OrderInfo]]()
    public var currencyPairToSellOrdersMap = [CurrencyPair : [OrderInfo]]()
    public var currencyPairToCandlesMap = [CurrencyPair : [CandleInfo]]()
    public var currencyPairToUserOrdersStatusMap = [CurrencyPair : [OrderStatusInfo]]()

    public var balance = [BalanceItem]()

    public func set(orderStatusInfo statusInfo:OrderStatusInfo,
                    forCurrencyPair currencyPair:CurrencyPair) {
        if (self.currencyPairToUserOrdersStatusMap[currencyPair] == nil) {
            self.currencyPairToUserOrdersStatusMap[currencyPair] = [OrderStatusInfo]()
        }

        var ordersForCurrencyPair = self.currencyPairToUserOrdersStatusMap[currencyPair]
        if let existingOrderIndex = ordersForCurrencyPair?.index(where: { (currentOrder) -> Bool in
            return currentOrder.id == statusInfo.id
        }) {
            ordersForCurrencyPair![existingOrderIndex] = statusInfo
        }
        else {
            ordersForCurrencyPair!.append(statusInfo)
        }

        self.currencyPairToUserOrdersStatusMap[currencyPair] = ordersForCurrencyPair
    }

    public func balanceFor(currency:Currency) -> Double? {
        if let balanceItem = balance.first(where: { $0.currency == currency } ) {
            return balanceItem.amount
        }

        return nil
    }
}