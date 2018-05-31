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
    public let dateLabel = UILabel()
    public let volumeLabel = UILabel()
    public let priceLabel = UILabel()
    public let remainingAmountLabel = UILabel()

    public var shadeOverlayView = UIView()

    // MARK: Overriden methods

    override init(style:UITableViewCellStyle, reuseIdentifier:String?) {
        super.init(style:style, reuseIdentifier:reuseIdentifier)

        typeLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
        typeLabel.textColor = UIDefaults.LabelDefaultFontColor
        typeLabel.textAlignment = .center

        dateLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)
        dateLabel.textColor = UIDefaults.LabelDefaultFontColor
        dateLabel.textAlignment = .center

        volumeLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)
        volumeLabel.textColor = UIDefaults.LabelDefaultFontColor
        volumeLabel.textAlignment = .center

        priceLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)
        priceLabel.textColor = UIDefaults.LabelDefaultFontColor
        priceLabel.textAlignment = .center

        remainingAmountLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)
        remainingAmountLabel.textColor = UIDefaults.LabelDefaultFontColor
        remainingAmountLabel.textAlignment = .center

        shadeOverlayView.backgroundColor = UIColor(white:1, alpha:0.5)

        addSubview(volumeLabel)
        addSubview(dateLabel)
        addSubview(typeLabel)
        addSubview(priceLabel)
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

        dateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(typeLabel.snp.right)
            make.width.equalToSuperview().multipliedBy(0.2)
            make.centerY.equalToSuperview()
        }

        volumeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(dateLabel.snp.right)
            make.width.equalToSuperview().multipliedBy(0.2)
            make.centerY.equalToSuperview()
        }

        priceLabel.snp.makeConstraints { (make) in
            make.left.equalTo(volumeLabel.snp.right)
            make.width.equalToSuperview().multipliedBy(0.2)
            make.centerY.equalToSuperview()
        }

        remainingAmountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(priceLabel.snp.right)
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

        switch orderStatus!.status {
        case .Publishing:
            backgroundColor = UIDefaults.GreenColor.withAlphaComponent(0.05)

        case .Cancelling:
            backgroundColor = UIDefaults.RedColor.withAlphaComponent(0.05)

        default:
            backgroundColor = UIColor.white
        }

        OrdersViewCell.formatter.dateFormat = "dd.MM.yy"
        dateLabel.text = OrdersViewCell.formatter.string(from:orderStatus!.date)
        let fiatAmount = orderStatus!.initialAmount * orderStatus!.price
        volumeLabel.text = String(format:"%.02f", fiatAmount)
        priceLabel.text = String(format:"%.02f", orderStatus!.price)
        remainingAmountLabel.text = String(format:"%.04f / %.04f", orderStatus!.remainingAmount, orderStatus!.initialAmount)

        if orderStatus!.status == .Completed {
            addSubview(shadeOverlayView)

            shadeOverlayView.snp.makeConstraints({ (make) in
                make.top.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(1)
            })
        }
        else {
            shadeOverlayView.removeFromSuperview()
        }
    }

    // MARK: Internal fields

    fileprivate static let formatter = DateFormatter()
}
