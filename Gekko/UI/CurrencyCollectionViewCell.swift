//  Created by Sergii Mykhailov on 02/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class CurrencyCollectionViewCell : UICollectionViewCell {

    override init(frame:CGRect) {
        super.init(frame:frame)

        clipsToBounds = true
        backgroundColor = UIColor.white

        setupControls()
    }

    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    public var currencyText:String {
        get {
            return currencyLabel.text!
        }
        set (value) {
            currencyLabel.text = value
        }
    }

    public var minPrice:Double? {
        didSet {
            updatePriceText()
        }
    }

    public var maxPrice:Double? {
        didSet {
            updatePriceText()
        }
    }

    public var balancePrecission:UInt = 6 {
        didSet {
            updateBalanceText()
        }
    }

    public var balance:Double? {
        didSet {
            updateBalanceText()
        }
    }

    public var dailyPercentage:Double? {
        didSet {
            updateDailyPercentageText()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        topSeparatorView.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.bottom).dividedBy(3)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(1)
        }

        currencyLabel.setContentHuggingPriority(.required, for:.horizontal)
        currencyLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(topSeparatorView).dividedBy(2)
        }

        dailyPercentageLabel.setContentHuggingPriority(.required, for:.horizontal)
        dailyPercentageLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-UIDefaults.Spacing)
            make.centerY.equalTo(currencyLabel)
        }

        priceLabelPlaceholder.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(topSeparatorView.snp.bottom)
            make.right.equalToSuperview()
            make.height.equalToSuperview().dividedBy(3)
        }

        priceLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        balanceLabelPlaceholder.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(priceLabelPlaceholder.snp.bottom)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        balanceLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    // MARK: Internal methods

    fileprivate func updatePriceText() -> Void {
        if minPrice == nil || maxPrice == nil {
            priceLabel.text = NSLocalizedString(CurrencyCollectionViewCell.BalanceDefaultString,
                                                comment:"Unavailable balance placeholder")
        }
        else if isAnyValueInfinite(firstValue: minPrice!, secondValue: maxPrice!) {
            priceLabel.text = NSLocalizedString(CurrencyCollectionViewCell.BalanceDefaultString,
                                                comment:"Unavailable balance placeholder")
        }
        else {
            let adjustedMinPrice = min(minPrice!, maxPrice!)
            let adjustedMaxPrice = max(minPrice!, maxPrice!)

            let floatingPointCount = adjustedMinPrice < CurrencyCollectionViewCell.MinBalanceValueForFloatingPoints ?
                                     2 :
                                     0

            let labelText = String(format:"%.\(floatingPointCount)f - %.\(floatingPointCount)f",
                                   adjustedMinPrice,
                                   adjustedMaxPrice)

            priceLabel.text = labelText
        }
    }

    fileprivate func updateBalanceText() -> Void {
        let formatString = "%.\(balancePrecission)f"
        let balanceValue = balance != nil ? balance! : 0
        let labelText = String(format:formatString, balanceValue)
        balanceLabel.text = labelText
    }

    fileprivate func updateDailyPercentageText() {
        if dailyPercentage != nil {
            let labelText = String(format:"%+.1f%", dailyPercentage!) + "%"

            dailyPercentageLabel.textColor = dailyPercentage! >= 0.0
                                             ? UIDefaults.GreenColor
                                             : UIDefaults.RedColor

            dailyPercentageLabel.text = labelText
        }
        else {
            dailyPercentageLabel.text = ""
        }
    }

    fileprivate func setupControls() -> Void {
        addSubview(currencyLabel)
        addSubview(dailyPercentageLabel)
        addSubview(topSeparatorView)
        addSubview(priceLabelPlaceholder)
        priceLabelPlaceholder.addSubview(priceLabel)
        addSubview(balanceLabelPlaceholder)
        balanceLabelPlaceholder.addSubview(balanceLabel)

        currencyLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelDefaultFontSize)
        currencyLabel.textAlignment = .center

        dailyPercentageLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
        dailyPercentageLabel.textAlignment = .center

        topSeparatorView.backgroundColor = UIDefaults.SeparatorColor

        priceLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)
        priceLabel.text = NSLocalizedString(CurrencyCollectionViewCell.BalanceDefaultString,
                                            comment:"Unavailable balance placeholder")

        balanceLabel.font = UIFont.systemFont(ofSize: UIDefaults.LabelSmallFontSize)
        balanceLabel.text = NSLocalizedString(CurrencyCollectionViewCell.BalanceDefaultString,
                                              comment:"Unavailable balance placeholder")
    }
    
    fileprivate func isAnyValueInfinite(firstValue:Double, secondValue:Double) -> Bool {
        let minValue = min(firstValue, secondValue)
        let maxValue = max(firstValue, secondValue)
        
        if minValue == -Double.greatestFiniteMagnitude || maxValue == Double.greatestFiniteMagnitude {
            return true
        }
        
        return false
    }

    // MARK: Internal fields

    fileprivate var currencyLabel = UILabel()
    fileprivate var dailyPercentageLabel = UILabel()
    fileprivate var priceLabelPlaceholder = UIView()
    fileprivate var priceLabel = UILabel()
    fileprivate var balanceLabelPlaceholder = UIView()
    fileprivate var balanceLabel = UILabel()
    fileprivate var topSeparatorView = UIView()

    fileprivate static let BalanceDefaultString = "Not available"
    fileprivate static let MinBalanceValueForFloatingPoints:Double = 100
}
