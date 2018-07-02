//  Created by Sergii Mykhailov on 29/06/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAAssetsProvider : BTCTradeUAProviderBase {

    public func retriveAssetAddressAsync(withPublicKey publicKey:String,
                                         privateKey:String,
                                         currency:Currency,
                                         onCompletion:@escaping AssetAddressCompletionCallback) {
        let suffix = currency.rawValue as String

        super.performUserRequestAsync(withSuffix:suffix,
                                      publicKey:publicKey,
                                      privateKey:privateKey,
                                      prefixUrl:BTCTradeUAAssetsProvider.PrefixUrl) { [weak self] (items, error) in
                                        if self != nil {
                                            let keys = self!.assetKeys(fromResponseItems:items)
                                            onCompletion(keys)
                                        }
        }
    }

    // MARK: Internal methods

    fileprivate func assetKeys(fromResponseItems items:[String : Any]) -> [String]? {
        return nil
    }

    // MARK: Internal fields

    fileprivate static let PrefixUrl = "https://btc-trade.com.ua/finance/crypto_currency"
}
