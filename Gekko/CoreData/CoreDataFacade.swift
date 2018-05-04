//  Created by Sergii Mykhailov on 13/01/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import CoreData

class CoreDataFacade : NSObject {

    // MARK: Public methods and properties

    init(completionBlock:@escaping () -> ()) {
        super.init()

        persistentContainer.loadPersistentStores(completionHandler: { [weak self] (description, error) in
            if error != nil {
                fatalError("Failed to load Core Data stack: \(error!)")
            }

            //This resource is the same name as your xcdatamodeld contained in your project
            guard let modelURL = Bundle.main.url(forResource:CoreDataFacade.ModelName,
                                                 withExtension:"momd") else {
                fatalError("Error loading model from bundle")
            }

            // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
            guard let objectModel = NSManagedObjectModel(contentsOf:modelURL) else {
                fatalError("Error initializing mom from: \(modelURL)")
            }

            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel:objectModel)

            self!.managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
            self!.managedObjectContext!.persistentStoreCoordinator = persistentStoreCoordinator

            let queue = DispatchQueue.global(qos:DispatchQoS.QoSClass.background)
            queue.async {
                guard let docURL = FileManager.default.urls(for:.documentDirectory,
                                                            in:.userDomainMask).last else {
                    fatalError("Unable to resolve document directory")
                }
                let storeURL = docURL.appendingPathComponent("\(CoreDataFacade.ModelName).sqlite")
                do {
                    let options = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
                    try persistentStoreCoordinator.addPersistentStore(ofType:NSSQLiteStoreType,
                                                                      configurationName:nil,
                                                                      at:storeURL,
                                                                      options:options)

                    completionBlock()
                } catch {
                    fatalError("Error migrating store: \(error)")
                }
            }
        })
    }

    public func makeOrder(withInitializationBlock initializationBlock:(StoredOrder) -> ()) {
        if managedObjectContext != nil {
            let order = NSEntityDescription.insertNewObject(forEntityName:CoreDataFacade.StoredOrderEntityName,
                                                            into:managedObjectContext!) as! StoredOrder

            initializationBlock(order)

            do {
                try managedObjectContext!.save()
                managedObjectContext!.reset()
            } catch {
                fatalError("Failed to save context: \(error)")
            }
        }
    }

    public func allOrders() -> [StoredOrder] {
        do {
            let fetchedOrders = try managedObjectContext!.fetch(ordersFetch) as! [StoredOrder]

            return fetchedOrders
        }
        catch {
            return [StoredOrder]()
        }
    }

    public func orders(forCurrencyPair pair:String) -> [StoredOrder] {
        do {
            let fetch = ordersFetch.copy() as! NSFetchRequest<NSFetchRequestResult>
            fetch.predicate = NSPredicate(format:"currency == %@", pair)

            let fetchedOrders = try managedObjectContext!.fetch(fetch) as! [StoredOrder]

            return fetchedOrders
        }
        catch {
            return [StoredOrder]()
        }
    }
    
    public func updateStoredBalance(withBalanceItems balanceItems:[BalanceItem]) {
        if managedObjectContext == nil {
            return
        }
        
        for item in balanceItems {
            if let balanceDataItem = self.balanceItem(forCurrency:String(item.currency.rawValue)) {
                balanceDataItem.currency = String(item.currency.rawValue)
                balanceDataItem.amount = item.amount
            }
            else {
                let balanceData = NSEntityDescription.insertNewObject(forEntityName:CoreDataFacade.BalanceDataEntityName,
                                                                      into:managedObjectContext!) as! BalanceData
                balanceData.currency = String(item.currency.rawValue)
                balanceData.amount = item.amount
            }
        }
        
        do {
            if !balanceItems.isEmpty {
                try managedObjectContext!.save()
                managedObjectContext!.reset()
            }
        } catch {
            fatalError("Failed to save context: \(error)")
        }
    }
    
    fileprivate func balanceItem(forCurrency currency:String) -> BalanceData? {
        do {
            let fetch = balanceFetch.copy() as! NSFetchRequest<NSFetchRequestResult>
            fetch.predicate = NSPredicate(format: "currency = %@", currency)
            
            if let fetchedBalanceItem = try managedObjectContext!.fetch(fetch) as? [BalanceData] {
                let balanceDataItem = fetchedBalanceItem.first
                return balanceDataItem
            }
            
            return nil
        }
        catch {
            return nil
        }
    }
    
    public func allBalanceItems() -> [BalanceData] {
        do {
            let fetchedBalanceItems = try managedObjectContext!.fetch(balanceFetch) as! [BalanceData]
            
            return fetchedBalanceItems
        }
        catch {
            return [BalanceData]()
        }
    }

    // MARK: Internal fields

    fileprivate var persistentContainer:NSPersistentContainer = NSPersistentContainer(name:CoreDataFacade.ModelName)
    fileprivate var managedObjectContext:NSManagedObjectContext?
    fileprivate var ordersFetch = NSFetchRequest<NSFetchRequestResult>(entityName:CoreDataFacade.StoredOrderEntityName)
    fileprivate var balanceFetch = NSFetchRequest<NSFetchRequestResult>(entityName:CoreDataFacade.BalanceDataEntityName)

    fileprivate static let ModelName = "Gekko"
    fileprivate static let StoredOrderEntityName = "StoredOrder"
    fileprivate static let BalanceDataEntityName = "BalanceData"
}
