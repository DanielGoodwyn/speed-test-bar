import Foundation

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

Task {
    do {
        print("Starting ping...")
        var times: [Double] = []
        for _ in 0..<3 {
            let start = CFAbsoluteTimeGetCurrent()
            var request = URLRequest(url: pingURL)
            request.httpMethod = "HEAD"
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let _ = try await session.data(for: request)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0 // ms
            times.append(elapsed)
        }
        print("Ping: \(times)")
        
        print("Starting download...")
        var requestDown = URLRequest(url: downloadURL)
        requestDown.cachePolicy = .reloadIgnoringLocalCacheData
        let startDown = CFAbsoluteTimeGetCurrent()
        let (data, _) = try await session.data(for: requestDown)
        let elapsedDown = CFAbsoluteTimeGetCurrent() - startDown
        let bytes = Double(data.count)
        let megabits = (bytes * 8.0) / 1_000_000.0
        let mbps = megabits / elapsedDown
        print("Download: \(mbps)")
        
        print("Starting upload...")
        let size = 5_000_000
        let payload = Data((0..<size).map { _ in UInt8.random(in: 0...255) })
        var requestUp = URLRequest(url: uploadURL)
        requestUp.httpMethod = "POST"
        requestUp.cachePolicy = .reloadIgnoringLocalCacheData
        requestUp.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let startUp = CFAbsoluteTimeGetCurrent()
        let (_, _) = try await session.upload(for: requestUp, from: payload)
        let elapsedUp = CFAbsoluteTimeGetCurrent() - startUp
        let megabitsUp = (Double(size) * 8.0) / 1_000_000.0
        let mbpsUp = megabitsUp / elapsedUp
        print("Upload: \(mbpsUp)")
        
    } catch {
        print("ERROR: \(error)")
    }
    exit(0)
}

RunLoop.main.run()
