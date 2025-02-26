//
// https://github.com/erikbasargin/odc-studio-lite
// See LICENSE for license information.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    
    static func megaYield() async {
        for _ in 0..<50 {
            await Task.yield()
        }
    }
}