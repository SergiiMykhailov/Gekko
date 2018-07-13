//  Created by Sergii Mykhailov on 30/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformManager : NSObject {

    // MARK: Public methods and properties

    public static let shared = TradingPlatformManager()

    public private(set) lazy var tradingPlatform = TradingPlatformManager.createTradingPlatform()

    // MARK: Internal methods

    fileprivate override init() {
        super.init()
    }

    fileprivate static func createTradingPlatform() -> TradingPlatform {
        return createBTCTradeUATradingPlatform()
    }

    fileprivate static func createBTCTradeUATradingPlatform() -> TradingPlatform {
        let result = BTCTradeUATradingPlatform()

        let userDefaults = UserDefaults.standard

        result.publicKey = userDefaults.string(forKey:UIUtils.PublicKeySettingsKey)
        result.privateKey = userDefaults.string(forKey:UIUtils.PrivateKeySettingsKey)

        return result
    }
}
