import SwiftUI
import AppKit


// AppKit wrapper for SecureField
struct AppKitSecureField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?
    
    func makeNSView(context: Context) -> NSSecureTextField {
        let textField = NSSecureTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.textFieldAction(_:))
        return textField
    }
    
    func updateNSView(_ nsView: NSSecureTextField, context: Context) {
        if nsView.stringValue != text {
            if nsView.currentEditor() == nil {
                nsView.stringValue = text
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: AppKitSecureField
        
        init(_ parent: AppKitSecureField) {
            self.parent = parent
        }
        
        @MainActor
        @objc func textFieldAction(_ sender: NSTextField) {
            parent.onSubmit?()
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}

// AppKit wrapper for TextField
struct AppKitTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.textFieldAction(_:))
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            // Only update if not currently being edited to avoid cursor jumping/resetting
            if nsView.currentEditor() == nil {
                nsView.stringValue = text
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: AppKitTextField
        
        init(_ parent: AppKitTextField) {
            self.parent = parent
        }
        
        @MainActor
        @objc func textFieldAction(_ sender: NSTextField) {
            parent.onSubmit?()
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}