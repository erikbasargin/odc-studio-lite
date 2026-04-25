//
//  LaunchView.swift
//  ODCLite
//
//  Created by Erik Basargin on 12/04/2026.
//

import ComposableArchitecture
import SwiftUI

struct LaunchView: View {
    
    @Bindable var store: StoreOf<AppFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            switch store.bootstrapState {
            case .idle, .inProgress:
                ProgressView("Starting ODC Lite…")
                    .controlSize(.large)
                    .padding(24)

            case .finished:
                Color.clear

            case .failed(let message):
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unable to start ODC Lite")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        store.send(.retryButtonTapped)
                    }
                }
                .padding(24)
            }
        }
        .task {
            store.send(.bootstrap)
        }
        .onChange(of: store.bootstrapState) { _, bootstrapState in
            if case .finished = bootstrapState {
                dismiss()
            }
        }
        .frame(minWidth: 280, minHeight: 120)
    }
}
