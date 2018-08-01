//  Created by Sergii Mykhailov on 21/06/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

protocol AssetsViewControllerDataSource : class {

    func supportedAssets(forCryptoAssetsViewController sender:AssetsViewController) -> [Currency]

    func keys(forAsset asset:Currency, forCryptoAssetsViewController sender:AssetsViewController) -> [String]
}

class AssetsViewController : UIViewController,
                             UITableViewDataSource,
                             UITableViewDelegate,
                             AssetCellDelegate {

    // MARK: Public methods and properties

    public weak var dataSource:AssetsViewControllerDataSource?

    // MARK: Overriden metnods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Assets", comment:"Assets view controller title")

        assetsTable?.register(AssetCell.classForCoder(),
                              forCellReuseIdentifier:AssetsViewController.CellIdentifier)
        assetsTable?.dataSource = self
        assetsTable?.delegate = self

        assetsTable?.separatorStyle = .singleLine
        assetsTable?.rowHeight = UIDefaults.LineHeight
        assetsTable?.separatorInset = UIEdgeInsets(top:0,
                                                   left:UIDefaults.LineHeight,
                                                   bottom:0,
                                                   right:0)
        assetsTable?.tableFooterView = UIView(frame: .zero)
        assetsTable?.allowsSelection = false
    }

    override func prepare(for segue:UIStoryboardSegue, sender:Any?) {
        if let assetWithdrawController = segue.destination as? AssetWithdrawalAddressViewController {
            assetWithdrawController.currency = withdrawCurrency!
        }
    }

    // MARK: UITableViewDataSource implementation

    internal func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        if dataSource != nil {
            supportedAssets = dataSource?.supportedAssets(forCryptoAssetsViewController:self)
            return supportedAssets!.count
        }

        return 0
    }

    // MARK: UITableViewDelegate implementation

    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let result = tableView.dequeueReusableCell(withIdentifier:AssetsViewController.CellIdentifier) as! AssetCell

        result.delegate = self

        if dataSource != nil && supportedAssets != nil {
            let currency = supportedAssets![indexPath.row]
            result.currency = currency
            result.keys = dataSource?.keys(forAsset:currency, forCryptoAssetsViewController:self)

            var iconToAssign = AssetIconsProvider.icon(forAsset:currency)
            iconToAssign = iconToAssign ?? AssetIconsProvider.defaultAssetIcon

            result.assetIcon = iconToAssign!

            result.title = currency.rawValue as String
        }

        return result
    }

    // MARK: AssetCellDelegate implementation

    func assetCell(_ sender:AssetCell, didCaptureKey key:String) {
        UIPasteboard.general.string = key

        UIUtils.presentNotification(withMessage:NSLocalizedString("Key was copied to clipboard", comment:"Key copying message"),
                                    onView:view,
                                    onCompletion: {})
    }

    func assetCellDidPressWithdrawButton(_ sender:AssetCell) {
        withdrawCurrency = sender.currency

        performSegue(withIdentifier:AssetsViewController.WithdrawSegueName, sender:self)
    }

    // MARK: Outlets

    @IBOutlet weak var assetsTable:UITableView?

    // MARK: Internal fields

    fileprivate var supportedAssets:[Currency]?
    fileprivate var withdrawCurrency:Currency?

    fileprivate static let CellIdentifier = "Asset Cell"
    fileprivate static let WithdrawSegueName = "Show Asset Withdrawal Segue"
}
