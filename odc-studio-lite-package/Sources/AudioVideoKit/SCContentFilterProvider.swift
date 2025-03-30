//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import ScreenCaptureKit

protocol SCContentFilterProvider {
    func invoke(
        display: SCDisplay,
        excludingApplications applications: [SCRunningApplication],
        exceptingWindows: [SCWindow]
    ) -> SCContentFilter
}

struct SCContentFilterRequest: SCContentFilterProvider {
    
    func invoke(
        display: SCDisplay,
        excludingApplications applications: [SCRunningApplication],
        exceptingWindows: [SCWindow]
    ) -> SCContentFilter {
        .init(display: display, excludingApplications: applications, exceptingWindows: exceptingWindows)
    }
}
