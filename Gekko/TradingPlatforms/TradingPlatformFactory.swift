//  Created by Sergii Mykhailov on 30/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformFactory : NSObject {

    // MARK: Public methods and properties

    public static func createTradingPlatform() -> TradingPlatform {
        return createBTCTradeUATradingPlatform()
    }

    // MARK: Internal methods

    fileprivate static func createBTCTradeUATradingPlatform() -> TradingPlatform {
        let result = BTCTradeUATradingPlatform()

        let userDefaults = UserDefaults.standard

        result.publicKey = userDefaults.string(forKey:UIUtils.PublicKeySettingsKey)
        result.privateKey = userDefaults.string(forKey:UIUtils.PrivateKeySettingsKey)

        return result
    }
}
