//  Created by Sergii Mykhailov on 19/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

class OrdersStackViewTableCell : UITableViewCell {

    // MARK: Public methods and properties

    override init(style:UITableViewCellStyle, reuseIdentifier:String?) {
        super.init(style:style, reuseIdentifier:reuseIdentifier)
    }

    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    public var order:OrderInfo? {
        didSet {
            updateLabels()
        }
    }

    // MARK: Overriden methods

    override func layoutSubviews() {
        super.layoutSubviews()

        setup(label:fiatPriceLabel)
        fiatPriceLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
        setup(label:cryptocurrencyAmountLabel)
        setup(label:fiatAmountLabel)

        fiatPriceLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(UIDefaults.Spacing)
            make.centerY.equalToSuperview()
            make.height.equalTo(UIDefaults.LabelDefaultFontSize)
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        cryptocurrencyAmountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(fiatPriceLabel.snp.right).offset(UIDefaults.SpacingSmall)
            make.centerY.equalToSuperview().dividedBy(2)
            make.height.equalTo(UIDefaults.LabelDefaultFontSize)
            make.right.equalToSuperview()
        }

        fiatAmountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(fiatPriceLabel.snp.right).offset(UIDefaults.SpacingSmall)
            make.centerY.equalToSuperview().offset(UIDefaults.LineHeight / 4)
            make.height.equalTo(UIDefaults.LabelDefaultFontSize)
            make.right.equalToSuperview()
        }
    }

    // MARK: Internal methods

    fileprivate func setup(label:UILabel) {
        if label.superview != nil {
            return
        }

        addSubview(label)
        label.font = UIFont.systemFont(ofSize:UIDefaults.LabelVerySmallFontSize)
        label.textColor = UIDefaults.LabelDefaultFontColor
    }

    fileprivate func updateLabels() {
        fiatPriceLabel.text = order != nil ? String(format:"%.2f", order!.price) : "---"
        cryptocurrencyAmountLabel.text = order != nil ? String(format:"%.6f", order!.cryptoCurrencyAmount) : "---"
        fiatAmountLabel.text = order != nil ? String(format:"%.2f", order!.fiatCurrencyAmount) : "---"
    }

    // MARK: Internal fields

    fileprivate let fiatPriceLabel = UILabel()
    fileprivate let cryptocurrencyAmountLabel = UILabel()
    fileprivate let fiatAmountLabel = UILabel()
}
