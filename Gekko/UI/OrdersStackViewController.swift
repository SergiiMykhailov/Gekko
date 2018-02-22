//  Created by Sergii Mykhailov on 18/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

protocol OrdersStackViewControllerDataSource : class {

    func sellOrdersForOrdersViewController(sender:OrdersStackViewController) -> [OrderInfo]

    func buyOrdersForOrdersViewController(sender:OrdersStackViewController) -> [OrderInfo]

}

class OrdersStackViewController : UIViewController,
                                  UITableViewDataSource {

    // MARK: Public methods and properties

    public weak var dataSource:OrdersStackViewControllerDataSource?

    public func reloadData() {
        if dataSource != nil {
            buyOrders = dataSource!.buyOrdersForOrdersViewController(sender:self)
            sellOrders = dataSource!.sellOrdersForOrdersViewController(sender:self)

            buyOrdersTableView.reloadData()
            sellOrdersTableView.reloadData()

            updateHeaderLabels()
        }
    }

    // MARK: Overriden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()

        reloadData()
    }

    // MARK: UITableViewDataSource implementation

    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return ordersFor(tableView:tableView).count
    }

    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:OrdersStackViewController.CellIdentifier) as?
                   OrdersStackViewTableCell

        let orders = ordersFor(tableView:tableView)
        let orderInfo = orders[indexPath.row]

        cell?.order = orderInfo

        return cell!
    }

    // MARK: Internal methods

    fileprivate func setupSubviews() {
        view.addSubview(headerSeparatorView)
        headerSeparatorView.backgroundColor = UIColor.white // UIDefaults.SeparatorColor

        view.addSubview(topVerticalSeparatorView)
        topVerticalSeparatorView.backgroundColor = UIDefaults.SeparatorColor

        view.addSubview(bottomVerticalSeparatorView)
        bottomVerticalSeparatorView.backgroundColor = UIDefaults.SeparatorColor

        view.addSubview(sellHeaderLabel)
        sellHeaderLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
        sellHeaderLabel.textColor = UIDefaults.LabelDefaultFontColor
        sellHeaderLabel.textAlignment = .center

        view.addSubview(buyHeaderLabel)
        buyHeaderLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
        buyHeaderLabel.textColor = UIDefaults.LabelDefaultFontColor
        buyHeaderLabel.textAlignment = .center

        view.addSubview(sellOrdersTableView)
        setup(table:sellOrdersTableView)

        view.addSubview(buyOrdersTableView)
        setup(table:buyOrdersTableView)
    }

    fileprivate func setup(table:UITableView) {
        table.rowHeight = UIDefaults.LineHeight / 2
        table.dataSource = self
        table.separatorStyle = .none
        table.allowsSelection = false
        table.register(OrdersStackViewTableCell.classForCoder(),
                       forCellReuseIdentifier:OrdersStackViewController.CellIdentifier)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        buyHeaderLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIDefaults.Spacing)
            make.left.equalToSuperview()
            make.right.equalTo(topVerticalSeparatorView.snp.left)
            make.height.equalTo(UIDefaults.LabelDefaultFontSize)
        }

        sellHeaderLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIDefaults.Spacing)
            make.left.equalTo(topVerticalSeparatorView.snp.right)
            make.right.equalToSuperview()
            make.height.equalTo(UIDefaults.LabelDefaultFontSize)
        }

        headerSeparatorView.snp.makeConstraints { (make) in
            make.top.equalTo(sellHeaderLabel.snp.bottom).offset(UIDefaults.Spacing)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(1)
        }

        topVerticalSeparatorView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIDefaults.Spacing)
            make.centerX.equalToSuperview()
            make.width.equalTo(1)
            make.bottom.equalTo(headerSeparatorView.snp.top).offset(-UIDefaults.Spacing)
        }

        bottomVerticalSeparatorView.snp.makeConstraints { (make) in
            make.top.equalTo(topVerticalSeparatorView.snp.bottom)
            make.centerX.equalTo(topVerticalSeparatorView)
            make.width.equalTo(1)
            make.bottom.equalToSuperview().offset(-UIDefaults.Spacing)
        }

        buyOrdersTableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerSeparatorView.snp.bottom)
            make.left.equalToSuperview().offset(UIDefaults.Spacing)
            make.right.equalTo(topVerticalSeparatorView.snp.left).offset(-UIDefaults.SpacingSmall)
            make.bottom.equalToSuperview()
        }

        sellOrdersTableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerSeparatorView.snp.bottom)
            make.left.equalTo(topVerticalSeparatorView.snp.right).offset(UIDefaults.SpacingSmall)
            make.right.equalToSuperview().offset(-UIDefaults.Spacing)
            make.bottom.equalToSuperview()
        }
    }

    fileprivate func ordersFor(tableView:UITableView) -> [OrderInfo] {
        let orders = tableView == sellOrdersTableView ? sellOrders : buyOrders

        return orders
    }

    fileprivate func updateHeaderLabels() {
        var bidText = NSLocalizedString("Bid", comment:"Buy orders title")
        var askText = NSLocalizedString("Ask", comment:"Sell orders title")

        if !buyOrders.isEmpty && !sellOrders.isEmpty {
            let averagePrice = (buyOrders.first!.price + sellOrders.first!.price) / 2
            let deviation = averagePrice * OrdersStackViewController.OrdersDeviation
            let minBidPrice = averagePrice - deviation
            let maxAskPrice = averagePrice + deviation

            var bidVolume:Double = 0
            for buyOrder in buyOrders {
                if buyOrder.price >= minBidPrice {
                    bidVolume += buyOrder.fiatCurrencyAmount
                }
                else {
                    break
                }
            }

            var askVolume:Double = 0
            for sellOrder in sellOrders {
                if sellOrder.price <= maxAskPrice {
                    askVolume += sellOrder.fiatCurrencyAmount
                }
                else {
                    break
                }
            }

            bidText = String(format:"%@ %.00f (UAH)", bidText, bidVolume)
            askText = String(format:"%@ %.00f (UAH)", askText, askVolume)
        }

        sellHeaderLabel.text = askText
        buyHeaderLabel.text = bidText
    }

    // MARK: Internal fields

    fileprivate var headerSeparatorView = UIView()
    fileprivate var topVerticalSeparatorView = UIView()
    fileprivate var bottomVerticalSeparatorView = UIView()
    fileprivate var sellHeaderLabel = UILabel()
    fileprivate var buyHeaderLabel = UILabel()
    fileprivate var sellOrdersTableView = UITableView()
    fileprivate var buyOrdersTableView = UITableView()

    public var buyOrders:[OrderInfo] = [OrderInfo]()
    public var sellOrders:[OrderInfo] = [OrderInfo]()

    fileprivate static let CellIdentifier = "Order Cell"
    fileprivate static let OrdersDeviation = 0.05
}
