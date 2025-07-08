//
//  brainstormApp.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

@main
struct brainstormApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Packet.self,
            PacketSection.self,
            ChecklistItem.self,
            Capture.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.serviceContainer, ServiceContainer(modelContext: sharedModelContainer.mainContext))
        }
        .modelContainer(sharedModelContainer)
    }
}
