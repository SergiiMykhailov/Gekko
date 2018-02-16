//  Created by Sergii Mykhailov on 08/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

struct OrderInfo {
    var fiatCurrencyAmount:Double
    var cryptoCurrencyAmount:Double
    var price:Double
    var user:String
    var isBuy:Bool
}

enum OrderType : Int8 {
    case Buy
    case Sell
}

enum OrderStatus : Int8 {
    case Pending
    case Completed
    case Canceled
}

struct OrderStatusInfo {
    var id:String
    var status:OrderStatus
    var date:Date
    var currency:Currency
    var initialAmount:Double
    var remainingAmount:Double
    var price:Double
    var type:OrderType
}
