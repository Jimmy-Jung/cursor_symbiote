import UIKit

/// A view controller that manages the main user interface.
class ViewController: UIViewController {

    private var name: String = ""
    private var label: UILabel = UILabel()

    /// Handles user authentication flow with retry logic.
    func authenticate(retryCount: Int = 3) {
        guard retryCount > 0 else { return }
        // Retry is needed because the auth server occasionally drops connections
        performAuth()
    }

    private func performAuth() {
        print("authenticating")
    }
}
