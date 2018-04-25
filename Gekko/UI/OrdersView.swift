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

    @objc optional func ordersView(sender:OrdersView,
                                   didRequestCancel order:OrderStatusInfo) -> Void
    
}

class OrdersView : UIView,
                   UITableViewDataSource,
                   UITableViewDelegate {

    // MARK: Public methods and properties

    public weak var dataSource:OrdersViewDataSource?
    public weak var delegate:OrdersViewDelegate?

    public private(set) var isEditing = false

    public override init(frame:CGRect) {
        super.init(frame:frame)

        ordersTable.dataSource = self
        ordersTable.delegate = self
        ordersTable.register(OrdersViewCell.classForCoder(), forCellReuseIdentifier:OrdersView.CellIdentifier)
        ordersTable.separatorInset = UIEdgeInsets(top:0, left:40, bottom:0, right:0)
        ordersTable.allowsSelection = false

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
                else if orderStatus.status == .Completed {
                    completedOrders.append(orderStatus)
                }
            }
        }

        pendingOrders.sort { return $0.date > $1.date }
        completedOrders.sort {return $0.date > $1.date }

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

    internal func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
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

    internal func tableView(_ tableView:UITableView, viewForHeaderInSection section:Int) -> UIView? {
        if headerView == nil {
            headerView = OrdersViewCell(style:.default, reuseIdentifier:OrdersView.CellIdentifier)
            headerView?.backgroundColor = UIColor.white

            headerView!.dateLabel.text = NSLocalizedString("Date", comment:"Order publishing date label title")
            headerView!.dateLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
            headerView!.volumeLabel.text = NSLocalizedString("Volume", comment:"Order volume label title")
            headerView!.volumeLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
            headerView!.priceLabel.text = NSLocalizedString("Price", comment:"")
            headerView!.priceLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
            headerView!.remainingAmountLabel.text = NSLocalizedString("Remainder", comment:"Remaining order amount text")
            headerView!.remainingAmountLabel.font = UIFont.boldSystemFont(ofSize:UIDefaults.LabelSmallFontSize)
            
            let separatorView = UIView()
            separatorView.backgroundColor = UIDefaults.SeparatorColor
            headerView?.addSubview(separatorView)
            
            separatorView.snp.makeConstraints({ (make) in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(1)
                make.bottom.equalToSuperview()
            })
        }

        return headerView!
    }

    internal func tableView(_ tableView:UITableView, heightForHeaderInSection section:Int) -> CGFloat {
        return UIDefaults.LineHeight
    }
    
    // MARK: UITableViewDelegate implementation
    
    internal func tableView(_ tableView:UITableView, editActionsForRowAt indexPath:IndexPath) -> [UITableViewRowAction]? {
        if let cell = tableView.cellForRow(at:indexPath) as? OrdersViewCell {
            if cell.orderStatus?.status == .Pending {
                var actions = [UITableViewRowAction]()

                let cancelAction = UITableViewRowAction(style:.destructive,
                                                        title:NSLocalizedString("Cancel", comment:"Cancel order action title"),
                                                        handler: { [weak self] (action, indexPath) in
                    self?.pendingOrders = (self?.pendingOrders.filter({ (currentOrder) -> Bool in
                        currentOrder.id != cell.orderStatus!.id
                    }))!
                    
                    self?.ordersTable.deleteRows(at:[indexPath], with:.top)
                    self?.delegate?.ordersView?(sender:self!, didRequestCancel:cell.orderStatus!)
                })
                
                actions.append(cancelAction)
                
                return actions
            }
        }
        
        return [UITableViewRowAction]()
    }

    internal func tableView(_ tableView:UITableView, willBeginEditingRowAt indexPath:IndexPath) {
        isEditing = true
    }

    internal func tableView(_ tableView:UITableView, didEndEditingRowAt indexPath:IndexPath?) {
        isEditing = false
    }

    // MARK: Internal fields

    fileprivate let ordersTable = UITableView()
    fileprivate var headerView:OrdersViewCell?

    fileprivate var pendingOrders = [OrderStatusInfo]()
    fileprivate var completedOrders = [OrderStatusInfo]()

    fileprivate static let CellIdentifier = "Order Cell"
}
