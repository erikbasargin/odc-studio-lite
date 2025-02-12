import Testing
import Capture

@Suite
struct AudioControlTests {
    
    @Test func defaultCaptureMicrophone() async throws {
        let control = AudioControl()
        #expect(control.captureMicrophone == false)
    }
}
