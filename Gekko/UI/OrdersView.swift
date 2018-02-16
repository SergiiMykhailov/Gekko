//  Created by Sergii Mykhailov on 11/01/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

protocol OrdersViewDataSource : class {

    func ordersFor(ordersView sender:OrdersView) -> [OrderStatusInfo]
    
}

@objc protocol OrdersViewDelegate : class {

}

class OrdersView : UIView,
                   UITableViewDataSource,
                   UITableViewDelegate {

    // MARK: Public methods and properties

    public weak var dataSource:OrdersViewDataSource?
    public weak var delegate:OrdersViewDelegate?

    public override init(frame:CGRect) {
        super.init(frame:frame)

        ordersTable.dataSource = self
        ordersTable.delegate = self
        ordersTable.register(OrdersViewCell.classForCoder(), forCellReuseIdentifier:OrdersView.CellIdentifier)

        addSubview(ordersTable)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func reloadData() {
        pendingOrders.removeAll()
        completedOrders.removeAll()

        let orders = dataSource?.ordersFor(ordersView:self)
        if orders != nil {
            for orderStatus in orders! {
                if orderStatus.status == .Pending {
                    pendingOrders.append(orderStatus)
                }
                else {
                    completedOrders.append(orderStatus)
                }
            }
        }

        ordersTable.reloadData()
    }

    // MARK: Overriden methods

    override func updateConstraints() {
        super.updateConstraints()

        ordersTable.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // MARK: UITableViewDataSource implementation

    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pendingOrders.count + completedOrders.count
    }

    func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:OrdersView.CellIdentifier) as! OrdersViewCell

        var orderStatus:OrderStatusInfo?
        if indexPath.row < pendingOrders.count {
            orderStatus = pendingOrders[indexPath.row]
        }
        else {
            let index = indexPath.row - pendingOrders.count
            orderStatus = completedOrders[index]
        }

        cell.orderStatus = orderStatus

        return cell
    }

    internal func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if headerView == nil {
            headerView = OrdersViewCell(style:.default, reuseIdentifier:OrdersView.CellIdentifier)

            headerView!.priceLabel.text = NSLocalizedString("Price", comment:"")
            headerView!.initialAmountLabel.text = NSLocalizedString("Initial", comment:"Initial order amount text")
            headerView!.remainingAmountLabel.text = NSLocalizedString("Remaining", comment:"Remaining order amount text")
        }

        return headerView!
    }

    internal func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIDefaults.LineHeight / 2
    }

    // MARK: Internal fields

    fileprivate let ordersTable = UITableView()
    fileprivate var headerView:OrdersViewCell?

    fileprivate var pendingOrders = [OrderStatusInfo]()
    fileprivate var completedOrders = [OrderStatusInfo]()

    fileprivate static let CellIdentifier = "Order Cell"
}
