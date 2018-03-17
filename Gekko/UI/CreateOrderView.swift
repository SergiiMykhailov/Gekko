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
    
    public private(set) var mode = OrderMode.Buy
    public private(set) var currency = Currency.BTC
    
    init(withMode mode:OrderMode,
         currency:Currency) {
        super.init(frame:CGRect.zero)

        self.mode = mode
        self.currency = currency

        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var amount: Double? {
        get {
            let result = numberFormatter.number(from:amountInputField.text!)?.doubleValue
            return result
        }
    }
    
    public var price: Double? {
        get {
            let result = numberFormatter.number(from:priceInputField.text!)?.doubleValue
            return result
        }
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

        amountSeparatorView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().priority(1000)
        }
        
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

        headerLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(amountSeparatorView.snp.top)
        }
        
        amountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(verticalLeftGuide)
            make.centerY.equalTo(amountSeparatorView).offset(UIDefaults.LineHeight / 2)
        }

        amountInputField.snp.makeConstraints { (make) in
            make.left.equalTo(verticalCenterGuide)
            make.centerY.equalTo(amountLabel.snp.centerY)
        }

        priceLabel.snp.makeConstraints { (make) in
            make.left.equalTo(verticalLeftGuide)
            make.centerY.equalTo(priceSeparatorView).offset(UIDefaults.LineHeight / 2)
        }

        priceInputField.snp.makeConstraints { (make) in
            make.left.equalTo(verticalCenterGuide)
            make.centerY.equalTo(priceLabel.snp.centerY)
            make.right.equalToSuperview()
        }

        orderAmountLabel.snp.makeConstraints { (make) in
            make.left.equalTo(verticalLeftGuide)
            make.centerY.equalTo(volumeSeparatorView).offset(UIDefaults.LineHeight / 2)
        }

        orderAmountValueLabel.snp.makeConstraints { (make) in
            make.left.equalTo(verticalCenterGuide)
            make.centerY.equalTo(orderAmountLabel.snp.centerY)
            make.right.equalToSuperview()
        }
        
        orderAmountValueOverlay.snp.makeConstraints { (make) in
            make.edges.equalTo(orderAmountValueLabel)
        }
    }

    fileprivate func layoutSeparator(separator:UIView,
                                     offsetFrom view:UIView) {
        separator.snp.makeConstraints { (make) in
            make.left.equalTo(verticalLeftGuide).priority(750)
            make.right.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(view).offset(UIDefaults.LineHeight)
        }
    }

    fileprivate func notifySubmitButtonPressed() {
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

        headerLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelDefaultFontSize)
        headerLabel.textAlignment = .center
        let title = mode == .Buy
                            ? NSLocalizedString("Buy", comment:"Buy button title")
                            : NSLocalizedString("Sell", comment:"Sell button title")
        headerLabel.text = String(format:"%@ (%@)", title, currency.rawValue)
        
        let amountText = NSLocalizedString("Amount", comment:"Order amount")
        amountLabel.text = String(format:"%@ (%@)", amountText, currency.rawValue)
        amountLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)

        let priceText = NSLocalizedString("Price", comment:"Order price")
        priceLabel.text = String(format:"%@ (UAH)", priceText)
        priceLabel.font = UIFont.systemFont(ofSize:UIDefaults.LabelSmallFontSize)

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
        
        orderAmountValueOverlay.backgroundColor = UIColor(white:1, alpha:0.5)

        addSubview(amountSeparatorView)
        addSubview(priceSeparatorView)
        addSubview(volumeSeparatorView)

        addSubview(verticalLeftGuide)
        addSubview(verticalCenterGuide)

        addSubview(headerLabel)
        addSubview(amountLabel)
        addSubview(amountInputField)
        addSubview(priceLabel)
        addSubview(priceInputField)
        addSubview(orderAmountLabel)
        addSubview(orderAmountValueLabel)
        addSubview(orderAmountValueOverlay)

        setupInputFieldsAccessoryButtons()
    }

    fileprivate func actionString() -> String {
        return mode == .Buy ?
            NSLocalizedString("Buy", comment:"Buy button title") :
            NSLocalizedString("Sell", comment:"Sell button title")
    }

    fileprivate func setupInputFieldsAccessoryButtons() {
        let cancelItem = UIBarButtonItem(title:NSLocalizedString("Cancel", comment:"Cancel order"),
                                         style:.plain,
                                         target:self,
                                         action:#selector(cancelButtonPressed))
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
                                  cancelItem,
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

    fileprivate let headerLabel = UILabel()
    fileprivate let amountLabel = UILabel()
    fileprivate let amountInputField = UITextField()
    fileprivate let priceLabel = UILabel()
    fileprivate let priceInputField = UITextField()
    fileprivate let orderAmountLabel = UILabel()
    fileprivate let orderAmountValueLabel = UILabel()
    fileprivate let orderAmountValueOverlay = UIView()
    fileprivate let accessoryToolbar = UIToolbar()

    fileprivate let verticalLeftGuide = UIView()
    fileprivate let verticalCenterGuide = UIView()
    fileprivate let amountSeparatorView = UIView()
    fileprivate let priceSeparatorView = UIView()
    fileprivate let volumeSeparatorView = UIView()

    fileprivate var orderAmountUpdatingTimer = Timer()

    fileprivate let numberFormatter = NumberFormatter()

    fileprivate static let OrderAmountUpdatingDelay:TimeInterval = 0.1
}
