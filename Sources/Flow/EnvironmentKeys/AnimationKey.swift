import SwiftUI

struct AnimationKey: EnvironmentKey {
    static let defaultValue: Animation? = nil
}

public extension EnvironmentValues {

    /// ``Animation`` stored in a view’s environment.
    var animation: Animation? {
        get { self[AnimationKey.self] }
        set { self[AnimationKey.self] = newValue }
    }
}

public extension View {

    /// Set the ``Animation`` for the view.
    ///
    /// - Parameters:
    ///   - animation: A animation that will be used by components in the view hierarchy.
    func animation(_ animation: Animation?) -> some View {
        environment(\.animation, animation)
    }
}
