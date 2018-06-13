//  Created by Sergii Mykhailov on 12/06/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

// Proxy-class for subscribtion for model events.
// It's used by controller in order to completely hide model from
// controller's client code.
class TradingPlatformModelNotifications {

    init(model:TradingPlatformModel) {
        self.model = model
    }

    public var onDealsUpdated:CurrencyPairCompletionHandler? {
        set {
            model.onDealsUpdated = newValue
        }
        get {
            return model.onDealsUpdated
        }
    }

    public var onBuyOrdersUpdated:CurrencyPairCompletionHandler? {
        set {
            model.onBuyOrdersUpdated = newValue
        }
        get {
            return model.onBuyOrdersUpdated
        }
    }

    public var onSellOrdersUpdated:CurrencyPairCompletionHandler? {
        set {
            model.onSellOrdersUpdated = newValue
        }
        get {
            return model.onSellOrdersUpdated
        }
    }

    public var onCandlesUpdated:CurrencyPairCompletionHandler? {
        set {
            model.onCandlesUpdated = newValue
        }
        get {
            return model.onCandlesUpdated
        }
    }

    public var onUserOrdersStatusUpdated:CurrencyPairCompletionHandler? {
        set {
            model.onUserOrdersStatusUpdated = newValue
        }
        get {
            return model.onUserOrdersStatusUpdated
        }
    }

    public var onUserBalanceUpdated:BalanceCompletionHandler? {
        set {
            model.onUserBalanceUpdated = newValue
        }
        get {
            return model.onUserBalanceUpdated
        }
    }

// MARK: Internal fields

    fileprivate let model:TradingPlatformModel
}
