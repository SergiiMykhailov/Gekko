//  Created by Sergii Mykhailov on 08/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

struct BalanceItem {
    var currency:Currency
    var amount:Double

    init(currency:Currency, amount:Double) {
        self.currency = currency
        self.amount = amount
    }
}
