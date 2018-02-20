//  Created by Sergii Mykhailov on 12/01/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class OrdersViewCell : UITableViewCell {

    public var orderStatus:OrderStatusInfo? {
        didSet {
            updateLabels()
        }
    }

    public let typeLabel = UILabel()
    public let priceLabel = UILabel()
    public let initialAmountLabel = UILabel()
    public let remainingAmountLabel = UILabel()

    public var shadeOverlayView = UIView()

    // MARK: Overriden methods

    override init(style:UITableViewCellStyle, reuseIdentifier:String?) {
        super.init(style:style, reuseIdentifier:reuseIdentifier)

        typeLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
        typeLabel.textColor = UIDefaults.LabelDefaultFontColor
        typeLabel.textAlignment = .center

        priceLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)
        priceLabel.textColor = UIDefaults.LabelDefaultFontColor
        priceLabel.textAlignment = .center

        initialAmountLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)
        initialAmountLabel.textColor = UIDefaults.LabelDefaultFontColor
        initialAmountLabel.textAlignment = .center

        remainingAmountLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)
        remainingAmountLabel.textColor = UIDefaults.LabelDefaultFontColor
        remainingAmountLabel.textAlignment = .center

        shadeOverlayView.backgroundColor = UIColor(white:1, alpha:0.5)

        addSubview(typeLabel)
        addSubview(priceLabel)
        addSubview(initialAmountLabel)
        addSubview(remainingAmountLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        typeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(UIDefaults.TableCellSpacing)
            make.width.equalToSuperview().multipliedBy(0.05)
            make.centerY.equalToSuperview()
        }

        priceLabel.snp.makeConstraints { (make) in
            make.left.equalTo(typeLabel.snp.right)
            make.width.equalToSuperview().multipliedBy(0.3)
            make.centerY.equalToSuperview()
        }

        initialAmountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(priceLabel.snp.right)
            make.width.equalToSuperview().multipliedBy(0.3)
            make.centerY.equalToSuperview()
        }

        remainingAmountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(initialAmountLabel.snp.right)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    // Internal methods

    fileprivate func updateLabels() {
        if orderStatus == nil {
            typeLabel.text = " "
            return
        }

        if orderStatus!.type == .Buy {
            typeLabel.textColor = UIDefaults.GreenColor
            typeLabel.text = "↓"
        }
        else {
            typeLabel.textColor = UIDefaults.RedColor
            typeLabel.text = "↑"
        }

        priceLabel.text = String(format:"%.02f", orderStatus!.price)
        initialAmountLabel.text = String(format:"%.06f", orderStatus!.initialAmount)
        remainingAmountLabel.text = String(format:"%.06f", orderStatus!.remainingAmount)

        if orderStatus!.status == .Completed {
            addSubview(shadeOverlayView)

            shadeOverlayView.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
        }
        else {
            shadeOverlayView.removeFromSuperview()
        }
    }
}
