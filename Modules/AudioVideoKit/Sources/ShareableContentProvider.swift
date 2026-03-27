//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit

struct ShareableContentPayload {
    let displays: [SCDisplay]
    let applications: [SCRunningApplication]
}

protocol ShareableContentProvider {
    func invoke() async throws -> ShareableContentPayload
}

struct ShareableContentRequest: ShareableContentProvider {
    
    func invoke() async throws -> ShareableContentPayload {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        return .init(displays: content.displays, applications: content.applications)
    }
}
