import AppKit

// Create the application
let app = NSApplication.shared

// Create and set the delegate on the main actor
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate

// Run the app
app.run()
