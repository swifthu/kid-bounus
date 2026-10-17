import SwiftUI

@Observable
final class AppState {
    var currentKidID: String {
        didSet { UserDefaults.standard.set(currentKidID, forKey: "currentKidID") }
    }
    init() {
        self.currentKidID = UserDefaults.standard.string(forKey: "currentKidID") ?? ""
    }
}
