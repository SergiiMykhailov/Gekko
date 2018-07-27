//  Created by Sergii Mykhailov on 29/06/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

@objc protocol AssetCellDelegate : class {

    @objc optional func assetCell(_ sender:AssetCell, didCaptureKey key:String)

}

class AssetCell : UITableViewCell {

    // MARK: Public methods and properties

    public weak var delegate:AssetCellDelegate?

    public var assetIcon:UIImage? {
        set {
            imageView?.image = newValue
        }
        get {
            return imageView?.image
        }
    }

    public var keys:[String]? {
        didSet {
            setupKeysButtons()
        }
    }

    // MARK: Overriden methods

    override init(style:UITableViewCellStyle, reuseIdentifier:String?) {
        super.init(style:style, reuseIdentifier:reuseIdentifier)

        let setupKeyButton = { (button:UIButton) in
            button.contentHorizontalAlignment = .left
            button.contentEdgeInsets = UIEdgeInsets(top:0, left:UIDefaults.Spacing, bottom:0, right:0)
            button.titleLabel?.font = UIFont.systemFont(ofSize:UIDefaults.LabelVerySmallFontSize)
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.contentEdgeInsets = UIEdgeInsets(top:0,
                                                    left:UIDefaults.Spacing,
                                                    bottom:0,
                                                    right:UIDefaults.Spacing)
            button.layer.cornerRadius = UIDefaults.CornerRadius
            button.layer.borderColor = button.tintColor.cgColor
            button.layer.borderWidth = 1 / UIScreen.main.nativeScale

            button.addTarget(self, action:#selector(self.keyButtonPressed(sender:)), for:.touchUpInside)
        }

        setupKeyButton(fillPrimaryKeyButton)
        setupKeyButton(fillSecondaryKeyButton)
        setupKeyButton(withdrawButton)
        withdrawButton.contentHorizontalAlignment = .center

        addSubview(fillPrimaryKeyButton)
        addSubview(fillSecondaryKeyButton)
        addSubview(withdrawButton)

        setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        withdrawButton.layer.cornerRadius = UIDefaults.CornerRadius
        withdrawButton.snp.makeConstraints { (make) in
            make.width.equalTo(keys != nil ? UIDefaults.LineHeight * 0.75 : 0.0)
            make.height.equalTo(keys != nil ? UIDefaults.LineHeight * 0.75 : 0.0)
            make.right.equalToSuperview().offset(-UIDefaults.Spacing)
            make.centerY.equalToSuperview()
        }

        let secondaryKeyPresent = keys != nil && keys!.count > 1

        fillSecondaryKeyButton.layer.cornerRadius = UIDefaults.CornerRadius
        fillSecondaryKeyButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(withdrawButton)
            make.height.equalTo(withdrawButton)

            if secondaryKeyPresent {
                make.right.equalTo(withdrawButton.snp.left).offset(-UIDefaults.Spacing)
                make.width.equalTo(fillPrimaryKeyButton)
            }
            else {
                make.width.equalTo(0)
            }
        }

        fillPrimaryKeyButton.layer.cornerRadius = UIDefaults.CornerRadius
        fillPrimaryKeyButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(withdrawButton)
            make.height.equalTo(withdrawButton)
            make.left.equalTo(UIDefaults.LineHeight)

            let constraint = secondaryKeyPresent ? fillSecondaryKeyButton.snp.left : withdrawButton.snp.left

            make.right.equalTo(constraint).offset(-UIDefaults.Spacing)
        }
    }

    // MARK: Internal methods

    fileprivate func setupKeysButtons() {
        withdrawButton.setTitle("↑", for:.normal)

        if keys != nil {
            if keys!.count > 0 {
                fillPrimaryKeyButton.setTitle("↓: \(keys![0])", for:.normal)
            }
            if keys!.count > 1 {
                fillSecondaryKeyButton.setTitle("↓: \(keys![1])", for:.normal)
            }
        }
    }

    @objc fileprivate func keyButtonPressed(sender:UIButton) {
        var capturedKey:String?

        if keys != nil {
            if sender == fillPrimaryKeyButton && keys!.count > 0 {
                capturedKey = keys![0]
            }
            else if sender == fillSecondaryKeyButton && keys!.count > 1 {
                capturedKey = keys![1]
            }
        }

        if capturedKey != nil {
            delegate?.assetCell?(self, didCaptureKey:capturedKey!)
        }
    }

    // MARK: Internal fields

    fileprivate let fillPrimaryKeyButton = UIButton(type:UIButtonType.roundedRect)
    fileprivate let fillSecondaryKeyButton = UIButton(type:UIButtonType.roundedRect)
    fileprivate let withdrawButton = UIButton(type:UIButtonType.roundedRect)
}
