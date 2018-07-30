//  Created by Sergii Mykhailov on 30/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

class AssetIconsProvider : NSObject {

    // MARK: Public methods and properties

    public static func icon(forAsset asset:Currency) -> UIImage? {
        switch asset {
        case .BTC:
            return #imageLiteral(resourceName: "BTC")

        case .ETH:
            return #imageLiteral(resourceName: "ETC")

        case .LTC:
            return #imageLiteral(resourceName: "LTC")

        case .XMR:
            return #imageLiteral(resourceName: "XMR")

        case .DOGE:
            return #imageLiteral(resourceName: "DOGE")

        case .DASH:
            return #imageLiteral(resourceName: "DASH")

        case .ZEC:
            return #imageLiteral(resourceName: "ZEC")

        case .BCH:
            return #imageLiteral(resourceName: "BTC")

        case .ETC:
            return #imageLiteral(resourceName: "ETC")

        case .KRB:
            return #imageLiteral(resourceName: "KRB")

        default:
            return nil
        }
    }

    public static var defaultAssetIcon:UIImage {
        get {
            return DefaultAssetIcon
        }
    }

    // MARK: Internal methods

    fileprivate override init() {

    }

    // MARK: Internal fields

    fileprivate static let DefaultAssetIcon:UIImage = #imageLiteral(resourceName: "currencies")
}
