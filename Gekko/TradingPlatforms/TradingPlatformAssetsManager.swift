//  Created by Sergii Mykhailov on 09/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformAssetsManager : NSObject {

    init(withAssetProvider assetProvider:AssetsHandler,
         assets:[Currency]) {
        super.init()

        self.assetProvider = assetProvider

        retrieveCurrentAssetKeys(forAssets:assets)
    }

    public func keys(forAsset asset:Currency) -> [String] {
        assert(Thread.isMainThread, "Accessing assets manager from background thread")

        var result = [String]()

        assetsToKeysMap.accessInMainQueueReadonly { (map) in
            if let keys = map[asset] {
                result = keys
            }
        }

        return result
    }

    // MARK: Internal methods

    fileprivate func retrieveCurrentAssetKeys(forAssets assets:[Currency]) {
        // Retrieve assets keys one-by-one.
        // Next asset is handled only after current asset handling is completed.

        handleCurrentAsset(fromCollection:assets) {
            [weak self] in
            self?.currentAssetIndex += 1
            self?.retrieveCurrentAssetKeys(forAssets:assets)
        }
    }

    fileprivate func handleCurrentAsset(fromCollection assets:[Currency],
                                       onCompletion:@escaping CompletionBlock) {
        if currentAssetIndex < assets.count {
            let asset = assets[currentAssetIndex]
            self.assetProvider!.retriveAssetAddressAsync(currency:asset,
                                                         onCompletion: {
                [weak self] (keys) in
                    self?.assetsToKeysMap.accessInMainQueueMutable(withBlock: { (map) in
                        map[asset] = keys
                    },
                                                                   completion:onCompletion)
            })
        }
    }

    // MARK: Internal fields

    fileprivate weak var assetProvider:AssetsHandler?
    fileprivate var assetsToKeysMap = MainQueueAccessor<[Currency : [String]]>(element:[Currency : [String]]())
    fileprivate var currentAssetIndex = 0
}
