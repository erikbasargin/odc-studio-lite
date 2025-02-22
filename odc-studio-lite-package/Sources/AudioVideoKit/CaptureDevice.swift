//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

public struct CaptureDevice: Identifiable, Hashable {
    public let id: String
    public let name: String
    
    @available(*, deprecated, message: "Will be removed")
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
