//  Created by Sergii Mykhailov on 10/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

@objc enum OrderMode : Int, RawRepresentable {
    case Buy
    case Sell
}

@objc protocol CreateOrderViewDelegate : class {

    @objc optional func createOrderView(sender:CreateOrderView,
                                        didSubmitRequestWithAmount amount:Double,
                                        price:Double,
                                        forMode mode:OrderMode)

    @objc optional func createOrderViewDidCancelRequest(sender:CreateOrderView)

}

class CreateOrderView : UIView,
                        UITextFieldDelegate {

    // MARK: Public methods and properties

    public static let PreferredHeight = UIDefaults.LineHeight * 4

    public weak var delegate:CreateOrderViewDelegate?

    init(withMode mode:OrderMode,
         currency:Currency,
         availableCryptocurrencyAmount:Double) {
        super.init(frame:CGRect.zero)

        self.mode = mode
        self.currency = currency
        self.availableCryptocurrencyAmount = availableCryptocurrencyAmount

        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overriden methods

    override func becomeFirstResponder() -> Bool {
        return amountInputField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        if amountInputField.isFirstResponder {
            return amountInputField.resignFirstResponder()
        }
        else if priceInputField.isFirstResponder {
            return priceInputField.resignFirstResponder()
        }

        return true
    }

    override public var isFirstResponder: Bool {
        return amountInputField.isFirstResponder || priceInputField.isFirstResponder
    }

    override func layoutSubviews() {
        layoutSeparator(separator:amountSeparatorView, offsetFrom:self)
        layoutSeparator(separator:priceSeparatorView, offsetFrom:amountSeparatorView)
        layoutSeparator(separator:volumeSeparatorView, offsetFrom:priceSeparatorView)

        verticalLeftGuide.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(15)
            make.width.equalTo(0)
        }

        verticalCenterGuide.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(155)
            make.width.equalTo(0)
        }

        amountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(verticalLeftGuide)
            make.centerY.equalTo(amountSeparatorView).offset(-UIDefaults.LineHeight / 2)
        }

        amountInputField.snp.makeConstraints { (make) in
            make.left.equalTo(verticalCenterGuide)
            make.centerY.equalTo(amountLabel.snp.centerY)
        }

        priceLabel.snp.makeConstraints { (make) in
            make.left.equalTo(verticalLeftGuide)
            make.centerY.equalTo(priceSeparatorView).offset(-UIDefaults.LineHeight / 2)
        }

        priceInputField.snp.makeConstraints { (make) in
            make.left.equalTo(verticalCenterGuide)
            make.centerY.equalTo(priceLabel.snp.centerY)
            make.right.equalToSuperview()
        }

        orderAmountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(verticalLeftGuide)
            make.centerY.equalTo(volumeSeparatorView).offset(-UIDefaults.LineHeight / 2)
        }

        orderAmountValueLabel.snp.makeConstraints { (make) in
            make.left.equalTo(verticalCenterGuide)
            make.centerY.equalTo(orderAmountLabel.snp.centerY)
            make.right.equalToSuperview()
        }

        submitCancelButtonsSeparator.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(1)
            make.top.equalTo(self.snp.bottom).offset(-UIDefaults.LineHeight + UIDefaults.Spacing)
            make.bottom.equalToSuperview().offset(-UIDefaults.Spacing)
        }

        cancelButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalTo(submitCancelButtonsSeparator.snp.left)
            make.centerY.equalTo(self.snp.bottom).offset(-UIDefaults.LineHeight / 2)
        }

        submitButton.snp.makeConstraints { (make) in
            make.left.equalTo(submitCancelButtonsSeparator.snp.right)
            make.right.equalToSuperview()
            make.centerY.equalTo(cancelButton)
        }
    }

    fileprivate func layoutSeparator(separator:UIView,
                                     offsetFrom view:UIView) {
        separator.snp.makeConstraints { (make) in
            make.left.equalTo(verticalLeftGuide)
            make.right.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(view).offset(UIDefaults.LineHeight)
        }
    }

    fileprivate func notifySubmitButtonPressed() {
        let amount = numberFormatter.number(from:amountInputField.text!)?.doubleValue
        let price = numberFormatter.number(from:priceInputField.text!)?.doubleValue

        if (amount != nil && price != nil) {
            delegate?.createOrderView?(sender:self,
                                       didSubmitRequestWithAmount:amount!,
                                       price:price!,
                                       forMode:mode)
        }
    }

    // MARK: Events Handling

    @objc fileprivate func submitButtonPressed(button:UIButton) {
        notifySubmitButtonPressed()
    }

    @objc fileprivate func cancelButtonPressed(button:UIButton) {
        delegate?.createOrderViewDidCancelRequest?(sender:self)
    }

    // MARK: UITextFieldDelegate implementation

    internal func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        priceInputField.becomeFirstResponder()

        return true;
    }

    internal func textField(_ textField:UITextField,
                            shouldChangeCharactersIn range: NSRange,
                            replacementString string: String) -> Bool {
        orderAmountUpdatingTimer.invalidate()

        orderAmountUpdatingTimer = Timer.scheduledTimer(withTimeInterval:CreateOrderView.OrderAmountUpdatingDelay,
                                                        repeats:false,
                                                        block:{ [weak self] (_) in
            self?.updateOrderAmountLabel()
        })

        return true
    }

    // MARK: Internal methods

    fileprivate func setupSubviews() {
        amountSeparatorView.backgroundColor = UIDefaults.SeparatorColor
        priceSeparatorView.backgroundColor = UIDefaults.SeparatorColor
        volumeSeparatorView.backgroundColor = UIDefaults.SeparatorColor

        let amountText = NSLocalizedString("Amount", comment:"Order amount")
        amountLabel.text = String(format:"%@ (%@)", amountText, currency.rawValue)
        amountLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)

        let priceText = NSLocalizedString("Price", comment:"Order price")
        priceLabel.text = String(format:"%@ (UAH)", priceText)
        priceLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)

        let submitButtonTitle = actionString()
        submitButton.setTitle(submitButtonTitle, for:.normal)
        submitButton.addTarget(self, action:#selector(submitButtonPressed(button:)), for:.touchUpInside)

        cancelButton.setTitle(NSLocalizedString("Cancel", comment:"Cancel order"), for:.normal)
        cancelButton.addTarget(self, action:#selector(cancelButtonPressed(button:)), for:.touchUpInside)

        submitCancelButtonsSeparator.backgroundColor = UIDefaults.SeparatorColor

        amountInputField.keyboardType = .decimalPad
        amountInputField.placeholder = "12345678.90"
        amountInputField.font = UIFont.systemFont(ofSize:UIDefaults.LabelDefaultFontSize)
        amountInputField.delegate = self

        priceInputField.keyboardType = .decimalPad
        priceInputField.placeholder = "12345678.90"
        priceInputField.font = UIFont.systemFont(ofSize:UIDefaults.LabelDefaultFontSize)
        priceInputField.delegate = self

        orderAmountLabel.text = NSLocalizedString("Order amount",
                                                  comment:"Order amount.")
        orderAmountLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)

        orderAmountValueLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelDefaultFontSize)

        addSubview(amountSeparatorView)
        addSubview(priceSeparatorView)
        addSubview(volumeSeparatorView)

        addSubview(verticalLeftGuide)
        addSubview(verticalCenterGuide)

        addSubview(amountLabel)
        addSubview(amountInputField)
        addSubview(priceLabel)
        addSubview(priceInputField)
        addSubview(orderAmountLabel)
        addSubview(orderAmountValueLabel)
        addSubview(submitButton)
        addSubview(submitCancelButtonsSeparator)
        addSubview(cancelButton)

        setupInputFieldsAccessoryButtons()
    }

    fileprivate func actionString() -> String {
        return mode == .Buy ?
            NSLocalizedString("Buy", comment:"Buy button title") :
            NSLocalizedString("Sell", comment:"Sell button title")
    }

    fileprivate func setupInputFieldsAccessoryButtons() {
        let applyItem = UIBarButtonItem(title:actionString(),
                                        style:.plain,
                                        target:self,
                                        action:#selector(applyButtonPressed))
        let prevItem = UIBarButtonItem(title:"↑",
                                       style:.plain,
                                       target:self,
                                       action:#selector(previousButtonPressed))
        let nextItem = UIBarButtonItem(title:"↓",
                                       style:.plain,
                                       target:self,
                                       action:#selector(nextButtonPressed))
        let hideKeyboardItem = UIBarButtonItem(title:NSLocalizedString("Hide", comment:"Hide keyboard button title"),
                                               style:.plain,
                                               target:self,
                                               action:#selector(hideKeyboardPressed))

        accessoryToolbar.items = [hideKeyboardItem,
                                  UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target:nil, action:nil),
                                  prevItem,
                                  nextItem,
                                  applyItem]
        accessoryToolbar.sizeToFit()

        amountInputField.inputAccessoryView = accessoryToolbar
        priceInputField.inputAccessoryView = accessoryToolbar
    }

    @objc fileprivate func applyButtonPressed() {
        notifySubmitButtonPressed()
    }

    @objc fileprivate func previousButtonPressed() {
        if priceInputField.isFirstResponder {
            amountInputField.becomeFirstResponder()
        }
    }

    @objc fileprivate func nextButtonPressed() {
        if amountInputField.isFirstResponder {
            priceInputField.becomeFirstResponder()
        }
    }

    @objc fileprivate func hideKeyboardPressed() {
        if amountInputField.isFirstResponder {
            amountInputField.resignFirstResponder()
        }
        else if priceInputField.isFirstResponder {
            priceInputField.resignFirstResponder()
        }
    }

    fileprivate func updateOrderAmountLabel() {
        let fiatCurrencyAmount = numberFormatter.number(from:priceInputField.text!)?.doubleValue
        let cryptocurrencyAmount = numberFormatter.number(from:amountInputField.text!)?.doubleValue

        if fiatCurrencyAmount != nil && cryptocurrencyAmount != nil {
            let orderAmount = fiatCurrencyAmount! * cryptocurrencyAmount!

            let orderAmountText = String(format:"%.02f", orderAmount)
            orderAmountValueLabel.text = orderAmountText
        }
        else {
            orderAmountValueLabel.text = ""
        }
    }

    // MARK: Internal fields

    fileprivate let amountLabel = UILabel()
    fileprivate let amountInputField = UITextField()
    fileprivate let priceLabel = UILabel()
    fileprivate let priceInputField = UITextField()
    fileprivate let orderAmountLabel = UILabel()
    fileprivate let orderAmountValueLabel = UILabel()
    fileprivate let submitButton = UIButton(type:.system)
    fileprivate let submitCancelButtonsSeparator = UIView()
    fileprivate let cancelButton = UIButton(type:.system)
    fileprivate let accessoryToolbar = UIToolbar()

    fileprivate let verticalLeftGuide = UIView()
    fileprivate let verticalCenterGuide = UIView()
    fileprivate let amountSeparatorView = UIView()
    fileprivate let priceSeparatorView = UIView()
    fileprivate let volumeSeparatorView = UIView()

    fileprivate var orderAmountUpdatingTimer = Timer()

    fileprivate let numberFormatter = NumberFormatter()

    fileprivate var availableCryptocurrencyAmount:Double = 0
    fileprivate var mode = OrderMode.Buy
    fileprivate var currency = Currency.BTC

    fileprivate static let OrderAmountUpdatingDelay:TimeInterval = 0.1
}
