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
    
    private let store: StoreOf<AppFeature>
    
    init() {
        #if DEBUG
        LBLogger(kHaishinKitIdentifier).level = .debug
        LBLogger(kRTMPHaishinKitIdentifier).level = .debug
        #endif

        let captureRuntime = CaptureRuntime()
        let store = Store(
            initialState: AppFeature.State(
                configuration: CaptureClient.initialConfiguration()
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.captureClient = .live(captureRuntime)
        }
        self.store = store

        AppDependencyManager.shared.add(dependency: store)

        ODCLiteShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            LaunchView(store: store)
        }
        
        MenuBarExtra {
            MenuBarExtraContentView(store: store)
        } label: {
            MenuBarExtraLabelView(store: store.scope(state: \.broadcast, action: \.broadcast))
        }
        
        Settings {
            GeneralSettingsView(store: store.scope(state: \.settings, action: \.settings))
                .frame(width: 830)
        }
        .windowResizability(.contentSize)
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
