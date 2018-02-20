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

@objc enum OrderType : Int8 {
    case Buy
    case Sell
}

@objc enum OrderStatus : Int8 {
    case Pending
    case Completed
    case Canceled
}

@objc class OrderStatusInfo : NSObject {
    
    init(id:String,
         status:OrderStatus,
         date:Date,
         currency:Currency,
         initialAmount:Double,
         remainingAmount:Double,
         price:Double,
         type:OrderType) {
        self.id = id
        self.status = status
        self.date = date
        self.currency = currency
        self.initialAmount = initialAmount
        self.remainingAmount = remainingAmount
        self.price = price
        self.type = type
    }
    
    var id:String
    var status:OrderStatus
    var date:Date
    var currency:Currency
    var initialAmount:Double
    var remainingAmount:Double
    var price:Double
    var type:OrderType
}
