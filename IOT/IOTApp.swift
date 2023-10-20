//
//  IOTApp.swift
//  IOT
//
//  Created by Leo Cheung on 20/10/2023.
//

import SwiftUI

@main
struct IOTApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
