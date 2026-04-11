//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import AppIntents
import ComposableArchitecture
import ScreenCaptureKit
import SwiftUI

import AudioVideoKit

#if DEBUG
import Logboard
import HaishinKit
import RTMPHaishinKit
#endif

@main
struct ODCLiteApp: App {
    
    private let broadcastManager: BroadcastManager
    private let store: StoreOf<AppFeature>
    private let streamConfiguration = StreamConfiguration()
    
    init() {
        #if DEBUG
        LBLogger(kHaishinKitIdentifier).level = .debug
        LBLogger(kRTMPHaishinKitIdentifier).level = .debug
        #endif

        let streamConfiguration = self.streamConfiguration
        let broadcastManager = BroadcastManager(streamConfiguration: streamConfiguration)
        self.broadcastManager = broadcastManager
        self.store = Store(initialState: AppFeature.State(snapshot: broadcastManager.broadcastStateSnapshot())) {
            AppFeature()
        } withDependencies: {
            $0.broadcastClient = .live(broadcastManager)
        }

        AppDependencyManager.shared.add(dependency: broadcastManager)

        ODCLiteShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            LaunchView(store: store)
        }
        
        MenuBarExtra {
            MenuBarExtraContentView(
                store: store.scope(state: \.broadcast, action: \.broadcast)
            )
                .environment(broadcastManager)
                .environment(streamConfiguration)
        } label: {
            MenuBarExtraLabelView(
                store: store.scope(state: \.broadcast, action: \.broadcast)
            )
        }
        
        Settings {
            GeneralSettingsView(
                store: store.scope(state: \.broadcast, action: \.broadcast)
            )
                .frame(width: 830)
                .environment(broadcastManager)
        }
        .windowResizability(.contentSize)
    }
}

private struct LaunchView: View {

    let store: StoreOf<AppFeature>
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Color.clear
            .task {
                store.send(.task)
                dismiss()
            }
    }
}

private struct MenuBarExtraLabelView: View {

    let store: StoreOf<BroadcastFeature>

    var body: some View {
        Image(.menuBarExtra)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, store.isBroadcasting ? .green : .white)
    }
}
