//  Created by Sergii Mykhailov on 02/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public let CurrencyCellSelectedOpacity:Float = 0.2

class CurrencyCollectionViewCell : UICollectionViewCell {

    override init(frame:CGRect) {
        super.init(frame:frame)

        clipsToBounds = false
        backgroundColor = UIColor.white

        layer.borderWidth = 1.0
        layer.borderColor = UIDefaults.SeparatorColor.cgColor
        
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
    
    public var isHighlightVisible:Bool = false {
        didSet {
            if isHighlightVisible != oldValue {
                let selectionIndicatorAlpha:CGFloat = isHighlightVisible ? 1.0 : 0.0
                selectionIndicatorView.alpha = selectionIndicatorAlpha
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        topSeparatorView.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.bottom).dividedBy(3)
            make.left.equalToSuperview().offset(2 * UIDefaults.Spacing)
            make.right.equalToSuperview().offset(-2 * UIDefaults.Spacing)
            make.height.equalTo(1)
        }

        currencyLabel.setContentHuggingPriority(.required, for:.horizontal)
        currencyLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(topSeparatorView).dividedBy(2)
        }

        priceLabelPlaceholder.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.bottom.equalTo(balanceLabelPlaceholder.snp.top).offset(-UIDefaults.Spacing * 2)
            make.right.equalToSuperview()
        }

        priceLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        balanceLabelPlaceholder.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UIDefaults.Spacing * 3)
        }

        balanceLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        selectionIndicatorClipView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        selectionIndicatorView.snp.remakeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(UIDefaults.CornerRadius / 2)
        }
        
        applyFullShadow()
    }

    // MARK: Internal methods

    fileprivate func updatePriceText() -> Void {
        if minPrice == nil || maxPrice == nil {
            priceLabel.text = NSLocalizedString(CurrencyCollectionViewCell.BalanceDefaultString,
                                                comment:"Unavailable balance placeholder")
        }
        else if isAnyValueInfinite(firstValue:minPrice!, secondValue:maxPrice!) {
            priceLabel.text = NSLocalizedString(CurrencyCollectionViewCell.BalanceDefaultString,
                                                comment:"Unavailable balance placeholder")
        }
        else {
            let adjustedMinPrice = min(minPrice!, maxPrice!)
            let adjustedMaxPrice = max(minPrice!, maxPrice!)

            let labelText = "\(UIUtils.formatAssetValue(amount:adjustedMinPrice)) - \(UIUtils.formatAssetValue(amount:adjustedMaxPrice))"

            priceLabel.text = labelText
        }
    }

    fileprivate func updateBalanceText() -> Void {
        let formatString = "%.\(balancePrecission)f"
        let balanceValue = balance != nil ? balance! : 0
        let labelText = String(format:formatString, balanceValue)
        balanceLabel.text = labelText
    }

    fileprivate func setupControls() -> Void {
        addSubview(selectionIndicatorClipView)
        selectionIndicatorClipView.clipsToBounds = true
        selectionIndicatorClipView.layer.cornerRadius = UIDefaults.CornerRadius
        addSubview(currencyLabel)
        addSubview(topSeparatorView)
        addSubview(priceLabelPlaceholder)
        priceLabelPlaceholder.addSubview(priceLabel)
        addSubview(balanceLabelPlaceholder)
        balanceLabelPlaceholder.addSubview(balanceLabel)
        selectionIndicatorClipView.addSubview(selectionIndicatorView)
        selectionIndicatorView.backgroundColor = UIDefaults.RedColor
        selectionIndicatorView.alpha = 0.0
        
        currencyLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
        currencyLabel.textColor = UIDefaults.LabelDefaultFontColor
        currencyLabel.textAlignment = .center

        topSeparatorView.backgroundColor = UIDefaults.SeparatorColor

        priceLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelVerySmallFontSize)
        priceLabel.textColor = UIDefaults.LabelDefaultFontColor
        priceLabel.text = NSLocalizedString(CurrencyCollectionViewCell.BalanceDefaultString,
                                            comment:"Unavailable balance placeholder")

        balanceLabel.font = UIFont.systemFont(ofSize: UIDefaults.LabelVerySmallFontSize)
        balanceLabel.textColor = UIDefaults.LabelDefaultFontColor
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
    fileprivate var priceLabelPlaceholder = UIView()
    fileprivate var priceLabel = UILabel()
    fileprivate var balanceLabelPlaceholder = UIView()
    fileprivate var balanceLabel = UILabel()
    fileprivate var topSeparatorView = UIView()
    fileprivate var selectionIndicatorClipView = UIView()
    fileprivate var selectionIndicatorView = UIView()

    fileprivate static let BalanceDefaultString = "Not available"
}
