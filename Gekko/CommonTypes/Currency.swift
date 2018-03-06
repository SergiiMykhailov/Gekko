//  Created by Sergii Mykhailov on 08/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

@objc enum Currency : Int, RawRepresentable {

    case UAH
    case BTC
    case ETH
    case LTC
    case XMR
    case DOGE
    case DASH
    case SIB
    case KRB
    case ZEC
    case BCH
    case ETC
    case NVC

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
        case .XMR:
            return "XMR"
        case .DOGE:
            return "DOGE"
        case .DASH:
            return "DASH"
        case .SIB:
            return "SIB"
        case .KRB:
            return "KRB"
        case .ZEC:
            return "ZEC"
        case .BCH:
            return "BCH"
        case .ETC:
            return "ETC"
        case .NVC:
            return "NVC"
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
        case "XMR":
            self = .XMR
        case "DOGE":
            self = .DOGE
        case "DASH":
            self = .DASH
        case "SIB":
            self = .SIB
        case "KRB":
            self = .KRB
        case "ZEC":
            self = .ZEC
        case "BCH":
            self = .BCH
        case "ETC":
            self = .ETC
        case "NVC":
            self = .NVC
        default:
            self = .UAH
        }
    }
}
