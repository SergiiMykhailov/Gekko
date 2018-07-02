//  Created by Sergii Mykhailov on 21/06/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

protocol AssetsViewControllerDataSource : class {

    func supportedCryptoAssets(forCryptoAssetsViewController sender:AssetsViewController) -> [Currency]

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
            supportedAssets = dataSource?.supportedCryptoAssets(forCryptoAssetsViewController:self)
            return supportedAssets!.count
        }

        return 0
    }

    // MARK: UITableViewDelegate implementation

    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let result = tableView.dequeueReusableCell(withIdentifier:AssetsViewController.CellIdentifier) as! AssetCell

        result.delegate = self
        result.keys = ["key1"]
        result.assetIcon = #imageLiteral(resourceName: "currencies")

        return result
    }

    // MARK: AssetCellDelegate implementation

    func assetCell(_ sender:AssetCell, didCaptureKey key:String) {
        
    }

    // MARK: Internal methods

    // MARK: Outlets

    @IBOutlet weak var assetsTable:UITableView?

    // MARK: Internal fields

    fileprivate var supportedAssets:[Currency]?

    fileprivate static let CellIdentifier = "Asset Cell"
}
