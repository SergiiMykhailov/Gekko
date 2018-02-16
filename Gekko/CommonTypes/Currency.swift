//  Created by Sergii Mykhailov on 08/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

@objc enum Currency : Int, RawRepresentable {

    case UAH
    case BTC
    case ETH
    case LTC

    typealias RawValue = NSString

    public var rawValue: RawValue {
        switch self {
        case .UAH:
            return "UAH"
        case .BTC:
            return "BTC"
        case .ETH:
            return "ETH"
        case .LTC:
            return "LTC"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "UAH":
            self = .UAH
        case "BTC":
            self = .BTC
        case "ETH":
            self = .ETH
        case "LTC":
            self = .LTC
        default:
            self = .UAH
        }
    }
}
