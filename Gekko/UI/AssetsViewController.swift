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

class AssetsViewController : NavigatableViewController,
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
        assetsTable?.allowsSelection = false
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
            result.keys = dataSource?.keys(forAsset:currency, forCryptoAssetsViewController:self)
            result.assetIcon = #imageLiteral(resourceName: "currencies")
        }

        return result
    }

    // MARK: AssetCellDelegate implementation

    func assetCell(_ sender:AssetCell, didCaptureKey key:String) {
        UIPasteboard.general.string = key

        presentNotification { }
    }

    // MARK: Internal methods

    fileprivate func presentNotification(onCompletion:CompletionBlock) {
        let label = UILabel()
        label.text = NSLocalizedString("Key was copied to clipboard", comment:"Key copying message")
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping

        let labelContainerView = UIView()
        labelContainerView.backgroundColor = UIColor(white:0, alpha:0.1)
        labelContainerView.alpha = 0
        labelContainerView.layer.cornerRadius = UIDefaults.CornerRadius

        view.addSubview(labelContainerView)
        labelContainerView.addSubview(label)

        labelContainerView.setContentHuggingPriority(.required, for:.vertical)
        labelContainerView.setContentHuggingPriority(.required, for:.horizontal)
        labelContainerView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(UIDefaults.Spacing)
            make.right.equalToSuperview().offset(-UIDefaults.Spacing)
        }

        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIDefaults.Spacing)
            make.bottom.equalToSuperview().offset(-UIDefaults.Spacing)
            make.left.equalToSuperview().offset(UIDefaults.Spacing)
            make.right.equalToSuperview().offset(-UIDefaults.Spacing)
        }

        UIView.animateKeyframes(withDuration:AssetsViewController.NotificationAnimationDuration,
                                delay:0,
                                options:.calculationModeLinear,
                                animations: {
            UIView.addKeyframe(withRelativeStartTime:0,
                               relativeDuration:1.0 / 8.0,
                               animations: {
                labelContainerView.alpha = 1
                label.alpha = 1
            })

            UIView.addKeyframe(withRelativeStartTime: 1.0 / 4.0 * AssetsViewController.NotificationAnimationDuration,
                               relativeDuration:1.0 / 4.0,
                               animations: {
                labelContainerView.alpha = 0
                label.alpha = 0
            })
        }) { (_) in
            labelContainerView.removeFromSuperview()
        }
    }

    // MARK: Outlets

    @IBOutlet weak var assetsTable:UITableView?

    // MARK: Internal fields

    fileprivate var supportedAssets:[Currency]?

    fileprivate static let CellIdentifier = "Asset Cell"
    fileprivate static let NotificationAnimationDuration:TimeInterval = 2.0
}
