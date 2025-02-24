//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

package protocol PreferredCameraControlling {
    
    var preferredCamera: AsyncStream<CaptureDevice?> { get }
    
    func setPreferredCamera(_ preferredCamera: CaptureDevice?)
}
