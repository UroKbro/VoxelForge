import Foundation

final class InputManager {

    static let shared = InputManager()

    private init() {}

    var w = false
    var a = false
    var s = false
    var d = false

    var q = false
    var e = false
    var up = false
    var down = false

    func handleKey(_ keyCode: UInt16, isDown: Bool) {
        switch keyCode {
        case 13:
            w = isDown
        case 0:
            a = isDown
        case 1:
            s = isDown
        case 2:
            d = isDown
        case 12:
            q = isDown
        case 14:
            e = isDown
        case 126:
            up = isDown
        case 125:
            down = isDown
        default:
            break
        }
    }
}
