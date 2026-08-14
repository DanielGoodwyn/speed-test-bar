import Foundation

class SpeedTestManager {
    // Cloudflare speed test endpoints (free, no API key, globally distributed)
    private let downloadURL = URL(string: "https://speed.cloudflare.com/__down?bytes=25000000")! // 25 MB
    private let uploadURL = URL(string: "https://speed.cloudflare.com/__up")!
    private let pingURL = URL(string: "https://speed.cloudflare.com/__down?bytes=0")!
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 20.0
        config.timeoutIntervalForResource = 30.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    struct TestResult {
        let downloadMbps: Double
        let uploadMbps: Double
        let pingMs: Double
    }

    func runTest() async throws -> TestResult {
        // 1. Ping test (average of 3 tries)
        let ping = await measurePing(attempts: 3)

        // 2. Download test
        let download = try await measureDownload()

        // 3. Upload test
        let upload = try await measureUpload()

        return TestResult(downloadMbps: download, uploadMbps: upload, pingMs: ping)
    }

    // MARK: - Ping

    private func measurePing(attempts: Int) async -> Double {
        var times: [Double] = []

        for _ in 0..<attempts {
            let start = CFAbsoluteTimeGetCurrent()
            var request = URLRequest(url: pingURL)
            request.httpMethod = "HEAD"
            request.cachePolicy = .reloadIgnoringLocalCacheData

            do {
                let _ = try await self.session.data(for: request)
                let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0 // ms
                times.append(elapsed)
            } catch {
                continue
            }
        }

        guard !times.isEmpty else { return -1 }
        return times.reduce(0, +) / Double(times.count)
    }

    // MARK: - Download

    private func measureDownload() async throws -> Double {
        var request = URLRequest(url: downloadURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let start = CFAbsoluteTimeGetCurrent()
        let (data, _) = try await self.session.data(for: request)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        let bytes = Double(data.count)
        let megabits = (bytes * 8.0) / 1_000_000.0
        let mbps = megabits / elapsed

        return mbps
    }

    // MARK: - Upload

    private func measureUpload() async throws -> Double {
        // Generate 5 MB of random-ish data
        let size = 5_000_000
        let payload = Data((0..<size).map { _ in UInt8.random(in: 0...255) })

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let start = CFAbsoluteTimeGetCurrent()
        let (_, _) = try await self.session.upload(for: request, from: payload)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        let megabits = (Double(size) * 8.0) / 1_000_000.0
        let mbps = megabits / elapsed

        return mbps
    }
}
