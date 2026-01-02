import SwiftUI


/// A SwiftUI wrapper around UIKIt TextField
/// ChatGPT says this (with isSecureTextEntry) may be more performant than SwiftUI's SecureField.
struct UIKitTextField: UIViewRepresentable {
    var placeholder: String
    var text: Binding<String>
    var isSecureTextEntry: Bool
    var onCommit: (() -> Void)?
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        isSecureTextEntry: Bool = false,
        onCommit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.text = text
        self.isSecureTextEntry = isSecureTextEntry
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.isSecureTextEntry = isSecureTextEntry
        textField.placeholder = placeholder
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text.wrappedValue
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitTextField

        init(_ textField: UIKitTextField) {
            self.parent = textField
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let currentText = textField.text,
               let range = Range(range, in: currentText) {
                parent.text.wrappedValue = currentText.replacingCharacters(in: range, with: string)
            }
            return true
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder() // Dismiss the keyboard
            parent.onCommit?()
            return true
        }
    }
}


struct MFTextField_Previews: PreviewProvider {
    static var previews: some View {
        @State var text = "Example Text"
        Group {
            VStack {
                UIKitTextField("Field title...", text: $text)
            }
            .padding()
            .previewDisplayName("Regular text")
            VStack {
                UIKitTextField("Field title...", text: $text, isSecureTextEntry: true)
            }
            .padding()
            .previewDisplayName("Secure text")
        }
    }
}
