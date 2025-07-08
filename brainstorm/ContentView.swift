//
//  ContentView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainNavigationView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Packet.self, PacketSection.self, ChecklistItem.self, Capture.self], inMemory: true)
}
