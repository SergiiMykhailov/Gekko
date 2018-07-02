//  Created by Sergii Mykhailov on 02/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

protocol CurrenciesCollectionViewControllerDataSource : class {

    func supportedCurrencies(forCurrenciesCollectionViewController sender:CurrenciesCollectionViewController) -> [Currency]

    func currenciesViewController(sender:CurrenciesCollectionViewController,
                                  balanceForCurrency:Currency) -> Double?

    func currenciesViewController(sender:CurrenciesCollectionViewController,
                                  minPriceForCurrency:Currency) -> Double?

    func currenciesViewController(sender:CurrenciesCollectionViewController,
                                  maxPriceForCurrency:Currency) -> Double?

    func currenciesViewController(sender:CurrenciesCollectionViewController,
                                  dailyUpdateInPercentsForCurrency:Currency) -> Double?
}

@objc protocol CurrenciesCollectionViewControllerDelegate : class {

    @objc optional func currenciesViewController(sender:CurrenciesCollectionViewController,
                                                 didSelectCurrency currency:Currency)
}

class CurrenciesCollectionViewController : UICollectionViewController {

    public weak var dataSource:CurrenciesCollectionViewControllerDataSource?
    public weak var delegate:CurrenciesCollectionViewControllerDelegate?

    public var selectedCurrency:Currency? {
        if currentSelectedItem == nil {
            return nil
        }
        else {
            let selectedCell = self.collectionView?.cellForItem(at:currentSelectedItem!) as! CurrencyCollectionViewCell
            let currency = currencyForCell(selectedCell)
            return currency
        }
    }

    init() {
        super.init(collectionViewLayout:layout)

        setupLayout()

        self.collectionView!.delegate = self
        self.collectionView!.register(CurrencyCollectionViewCell.self,
                                      forCellWithReuseIdentifier:CurrenciesCollectionViewController.CellIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overriden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView!.backgroundColor = UIColor.clear
        self.collectionView!.allowsSelection = true
        self.collectionView!.allowsMultipleSelection = false
    }

    // MARK: UICollectionViewDelegate implementation

    internal override func collectionView(_ collectionView:UICollectionView,
                                          numberOfItemsInSection section:Int) -> Int {
        if dataSource != nil {
            supportedCurrencies = dataSource!.supportedCurrencies(forCurrenciesCollectionViewController:self)
            return supportedCurrencies!.count
        }

        return 0
    }

    internal override func collectionView(_ collectionView:UICollectionView,
                                          cellForItemAt indexPath:IndexPath) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier:CurrenciesCollectionViewController.CellIdentifier,
                                               for:indexPath) as! CurrencyCollectionViewCell

        if dataSource != nil {
            let requestedCurrency = supportedCurrencies![indexPath.row]
            let balance = dataSource!.currenciesViewController(sender:self,
                                                               balanceForCurrency:requestedCurrency)
            let minPrice = dataSource!.currenciesViewController(sender:self,
                                                                minPriceForCurrency:requestedCurrency)
            let maxPrice = dataSource!.currenciesViewController(sender:self,
                                                                maxPriceForCurrency:requestedCurrency)

            cell.balance = balance
            cell.minPrice = minPrice
            cell.maxPrice = maxPrice
            cell.currencyText = requestedCurrency.rawValue as String
        }

        if currentSelectedItem == nil && cell.isSelected {
            currentSelectedItem = indexPath
        }

        if currentSelectedItem == indexPath {
            cell.backgroundColor = UIDefaults.CellDefaultSelectedColor
        }
        else {
            cell.backgroundColor = UIColor.white
        }

        cell.layer.cornerRadius = UIDefaults.CornerRadius
        return cell
    }

    internal override func collectionView(_ collectionView:UICollectionView,
                                          didSelectItemAt indexPath:IndexPath) {
        let cell = collectionView.cellForItem(at:indexPath)
        if currentSelectedItem != nil {
            let currentSelectedCell = collectionView.cellForItem(at:currentSelectedItem!)
            currentSelectedCell?.backgroundColor = UIColor.white
        }

        currentSelectedItem = indexPath
        cell?.backgroundColor = UIDefaults.CellDefaultSelectedColor

        let currencyCell = cell as? CurrencyCollectionViewCell
        if currencyCell != nil {
            let currency = currencyForCell(currencyCell!)

            let boundsInCollectionView = cell?.convert(cell!.bounds, to:collectionView)

            if !collectionView.bounds.contains(boundsInCollectionView!) {
                collectionView.scrollToItem(at:indexPath, at:.right, animated:true)
            }

            delegate?.currenciesViewController?(sender:self, didSelectCurrency:currency)
        }
    }

    // MARK: CurrencyCollectionViewCellDelegate implementation

    fileprivate func currencyForCell(_ cell:CurrencyCollectionViewCell) -> Currency {
        let result = Currency(rawValue:cell.currencyText as Currency.RawValue)
        return result!
    }

    // MARK: Internal methods

    func setupLayout() -> Void {
        layout.scrollDirection = .horizontal

        // Try to fit at least 3 items (with 2 interitem spacings)
        let itemWidth = UIDefaults.LineHeight * 3
        let itemHeight = UIDefaults.LineHeight * 2
        layout.itemSize = CGSize(width:itemWidth, height:itemHeight)
        layout.minimumInteritemSpacing = UIDefaults.Spacing
        layout.minimumLineSpacing = UIDefaults.Spacing
    }

    // MARK: Internal fields

    fileprivate var supportedCurrencies:[Currency]?

    fileprivate let layout = UICollectionViewFlowLayout()
    fileprivate var currentSelectedItem:IndexPath?

    fileprivate static let CellIdentifier = "Currency Cell"
}
