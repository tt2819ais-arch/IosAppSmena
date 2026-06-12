import SwiftUI
import UIKit

/// Resigns the first responder, dismissing the keyboard from anywhere.
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
}

extension View {
    /// Adds a "Готово" button above the keyboard so number pads (which have no
    /// return key) can always be dismissed.
    func keyboardDoneToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { hideKeyboard() }
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
        }
    }

    /// Dismisses the keyboard when tapping anywhere on this view's empty space.
    func dismissKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
    }
}
