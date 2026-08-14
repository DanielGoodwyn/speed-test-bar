import AppKit
import SwiftUI
import CoreLocation

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var refreshTimer: Timer?
    private let speedTestManager = SpeedTestManager()
    private let locationManager = LocationManager()
    private let historyStore = HistoryStore()
    private var dashboardWindow: NSWindow?
    private var isTesting = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        setupStatusItem()
        locationManager.requestAuthorization()
        startAutoRefresh()

        // Run initial speed test after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.runSpeedTest()
        }
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "⏳ Testing..."
            button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        }

        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let testItem = NSMenuItem(title: "Run Speed Test", action: #selector(menuRunSpeedTest), keyEquivalent: "r")
        testItem.target = self
        menu.addItem(testItem)

        menu.addItem(NSMenuItem.separator())

        let dashboardItem = NSMenuItem(title: "Show Dashboard", action: #selector(menuShowDashboard), keyEquivalent: "d")
        dashboardItem.target = self
        menu.addItem(dashboardItem)

        menu.addItem(NSMenuItem.separator())

        // Show last result summary if available
        if let latest = historyStore.results.first {
            let summaryItem = NSMenuItem(title: "Last Test", action: nil, keyEquivalent: "")
            summaryItem.isEnabled = false
            menu.addItem(summaryItem)

            let downItem = NSMenuItem(title: String(format: "  ↓ %.1f Mbps", latest.downloadMbps), action: nil, keyEquivalent: "")
            downItem.isEnabled = false
            menu.addItem(downItem)

            let upItem = NSMenuItem(title: String(format: "  ↑ %.1f Mbps", latest.uploadMbps), action: nil, keyEquivalent: "")
            upItem.isEnabled = false
            menu.addItem(upItem)

            let pingItem = NSMenuItem(title: String(format: "  ⚡ %.0f ms ping", latest.pingMs), action: nil, keyEquivalent: "")
            pingItem.isEnabled = false
            menu.addItem(pingItem)

            if let lat = latest.latitude, let lng = latest.longitude {
                let locItem = NSMenuItem(title: String(format: "  📍 %.4f, %.4f", lat, lng), action: nil, keyEquivalent: "")
                locItem.isEnabled = false
                menu.addItem(locItem)
            }

            let timeItem = NSMenuItem(title: "  \(timeAgo(latest.timestamp))", action: nil, keyEquivalent: "")
            timeItem.isEnabled = false
            menu.addItem(timeItem)

            menu.addItem(NSMenuItem.separator())
        }

        let quitItem = NSMenuItem(title: "Quit SpeedTestBar", action: #selector(menuQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Menu Actions

    @objc private func menuRunSpeedTest() {
        runSpeedTest()
    }

    @objc private func menuShowDashboard() {
        showDashboardWindow()
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }

    // MARK: - Auto Refresh

    private func startAutoRefresh() {
        scheduleNextTest()
    }

    private func scheduleNextTest() {
        // Calculate seconds to the next 5-minute boundary (e.g., :00, :05, :10)
        let calendar = Calendar.current
        let now = Date()
        let minutes = calendar.component(.minute, from: now)
        let seconds = calendar.component(.second, from: now)
        
        let minutesToNextBoundary = 5 - (minutes % 5)
        let secondsToWait = (minutesToNextBoundary * 60) - seconds
        
        // Safety check: if it's exactly on the boundary, wait 5 minutes, else wait the calculated time
        let delay = secondsToWait <= 0 ? 300 : secondsToWait
        
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(delay), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.runSpeedTest()
                // After running, schedule the next one
                self?.scheduleNextTest()
            }
        }
    }

    // MARK: - Speed Test

    private func runSpeedTest() {
        guard !isTesting else { return }
        isTesting = true

        DispatchQueue.main.async {
            if let latest = self.historyStore.results.first {
                let down = self.formatSpeed(latest.downloadMbps)
                let up = self.formatSpeed(latest.uploadMbps)
                self.statusItem.button?.title = "⏳ ↓ \(down)  ↑ \(up)"
            } else {
                self.statusItem.button?.title = "⏳ Testing..."
            }
        }

        // Fetch location first, then run speed test
        locationManager.requestLocation { [weak self] location in
            guard let self = self else { return }

            Task { @MainActor in
                do {
                    let result = try await self.speedTestManager.runTest()
                    let record = SpeedTestResult(
                        downloadMbps: result.downloadMbps,
                        uploadMbps: result.uploadMbps,
                        pingMs: result.pingMs,
                        latitude: location?.coordinate.latitude,
                        longitude: location?.coordinate.longitude
                    )

                    self.historyStore.add(record)
                    self.updateMenuBarTitle(downloadMbps: result.downloadMbps, uploadMbps: result.uploadMbps)
                    self.buildMenu() // Refresh menu with latest result
                    self.isTesting = false
                } catch {
                    print("[SpeedTest] Error: \(error.localizedDescription)")
                    self.statusItem.button?.title = "⚠️ Error"
                    self.isTesting = false
                    // We removed the 30-second retry here so it doesn't get stuck in an error loop.
                    // It will try again at the next 5-minute interval or when clicked.
                }
            }
        }
    }

    private func updateMenuBarTitle(downloadMbps: Double, uploadMbps: Double) {
        let down = formatSpeed(downloadMbps)
        let up = formatSpeed(uploadMbps)
        statusItem.button?.title = "↓ \(down)  ↑ \(up)"
    }

    private func formatSpeed(_ mbps: Double) -> String {
        if mbps >= 1000 {
            return String(format: "%.1f Gbps", mbps / 1000.0)
        } else if mbps >= 100 {
            return String(format: "%.0f Mbps", mbps)
        } else {
            return String(format: "%.1f Mbps", mbps)
        }
    }

    // MARK: - Dashboard Window

    private func showDashboardWindow() {
        if let window = dashboardWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let dashboardView = DashboardView(store: historyStore)
        let hostingView = NSHostingView(rootView: dashboardView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 750),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SpeedTestBar — Dashboard"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        self.dashboardWindow = window
    }

    // MARK: - Helpers

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
