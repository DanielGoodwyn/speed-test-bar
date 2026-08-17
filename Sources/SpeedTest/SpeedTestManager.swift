import Foundation

class SpeedTestManager {
    struct TestResult {
        let downloadMbps: Double
        let uploadMbps: Double
        let pingMs: Double
    }

    func runTest(duration: Int) async throws -> TestResult {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/networkQuality")
            process.arguments = ["-M", "\(duration)", "-c"]

            let pipe = Pipe()
            process.standardOutput = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dlThroughputBps = json["dl_throughput"] as? Double ?? 0.0
                    let ulThroughputBps = json["ul_throughput"] as? Double ?? 0.0
                    let baseRtt = json["base_rtt"] as? Double ?? 0.0

                    let downloadMbps = dlThroughputBps / 1_000_000.0
                    let uploadMbps = ulThroughputBps / 1_000_000.0

                    let result = TestResult(downloadMbps: downloadMbps, uploadMbps: uploadMbps, pingMs: baseRtt)
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(domain: "SpeedTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"]))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
