//
//  ContentView.swift
//  ODC
//
//  Created by Erik Basargin on 06/10/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("ODC Lite", systemImage: "hat.widebrim.fill")
                
                Spacer()
                
                Button {
                    // Start stream
                } label: {
                    Image(systemName: "record.circle")
                }
                .buttonStyle(.borderless)
            }
            .font(.title)
            .padding()
            
            Divider()
            
            Form {
                Section("Video") {
                    Toggle("Exclude app from stream", isOn: .constant(false))
                }
            }
            .formStyle(ContentFormStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .bottom])
            .background(Color.secondary.quaternary)
        }
    }
}

private struct ContentFormStyle: FormStyle {
    func makeBody(configuration: Configuration) -> some View {
        ForEach(sections: configuration.content) { section in
            VStack(alignment: .leading) {
                section.header
                    .font(.title3)
                    .padding(.top, 8)
                
                section.content
                
                section.footer
            }
        }
    }
}

#Preview {
    ContentView()
}
