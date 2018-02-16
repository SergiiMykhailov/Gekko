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
                    try persistentStoreCoordinator.addPersistentStore(ofType:NSSQLiteStoreType,
                                                                      configurationName:nil,
                                                                      at:storeURL,
                                                                      options:nil)
                } catch {
                    fatalError("Error migrating store: \(error)")
                }
            }

            completionBlock()
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

    // MARK: Internal fields

    fileprivate var persistentContainer:NSPersistentContainer = NSPersistentContainer(name:CoreDataFacade.ModelName)
    fileprivate var managedObjectContext:NSManagedObjectContext?
    fileprivate var ordersFetch = NSFetchRequest<NSFetchRequestResult>(entityName:CoreDataFacade.StoredOrderEntityName)

    fileprivate static let ModelName = "Gekko"
    fileprivate static let StoredOrderEntityName = "StoredOrder"
}
