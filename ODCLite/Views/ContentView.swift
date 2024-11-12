//
//  This source file is part of the ODCLite open source project
//
//  Copyright (c) 2024 Erik Basargin
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI

struct ContentView: View {

    @Environment(BroadcastManager.self) private var broadcastManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("ODC Lite", systemImage: "hat.widebrim.fill")

                Spacer()

                Button(action: broadcastManager.toogleBroadcast) {
                    Image(systemName: "record.circle")
                }
                .buttonStyle(.borderless)
            }
            .font(.title)
            .padding()

            Divider()

            BroadcastConfigurationView()

            Button("Quit") {
                NSApplication.shared.terminate(self)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
