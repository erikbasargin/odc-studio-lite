//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Testing

import Capture

@Suite
struct AudioControlTests {
    
    @Test func defaultCaptureMicrophone() async throws {
        let control = AudioControl()
        #expect(control.captureMicrophone == false)
    }
}
