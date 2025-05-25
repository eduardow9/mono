import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    var container: NSPersistentCloudKitContainer
    
    init() {
        // Registrar transformadores personalizados
        registerAllValueTransformers()
        
        container = NSPersistentCloudKitContainer(name: "Model")
        
        // Configurar opções CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Falha ao recuperar descrição do persistent store")
        }
        
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.AerisDesign.Mono"
        )
        
        // Configurar políticas de sincronização
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        // Carregar as stores
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        // Configuração para CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
