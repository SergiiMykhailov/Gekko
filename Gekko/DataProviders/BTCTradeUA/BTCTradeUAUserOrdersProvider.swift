//  Created by Sergii Mykhailov on 05/05/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAUserOrdersProvider : BTCTradeUAProviderBase {

    // MARK: Public methods and properties

    public func retrieveUserOrdersAsync(forPair pair:BTCTradeUACurrencyPair,
                                        publicKey:String,
                                        privateKey:String,
                                        onCompletion:@escaping UserOrdersCallback) {
        let userOrdersSuffix = String(format:"my_orders/%@", pair.rawValue)

        super.performUserRequestAsync(withSuffix:userOrdersSuffix,
                                      publicKey:publicKey,
                                      privateKey:privateKey) { [weak self] (items, _) in
            if self != nil {
                var result:[OrderStatusInfo]? = nil
                if items[BTCTradeUAUserOrdersProvider.OpenOrdersKey] != nil {
                    result = BTCTradeUAUtils.ordersStatus(fromResponseItems:items, withStatus:.Pending)
                }

                onCompletion(result)
            }
        }
    }

    // MARK: Internal fields

    fileprivate static let OpenOrdersKey = "your_open_orders"
}
