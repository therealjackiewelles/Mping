import Foundation

enum PingVerificationState: String, Codable, Equatable, Sendable {
    case online
    case verifyingOffline
    case offline
    case verifyingOnline
}

struct PingVerificationAttempt: Sendable {
    let timestamp: Date
    let result: PingEngine.PingResult
}

struct PingVerificationBurstResult: Sendable {
    let confirmed: Bool
    let attempts: [PingVerificationAttempt]

    var failedAttempts: [PingVerificationAttempt] {
        attempts.filter { $0.result.status == .offline }
    }

    var successfulAttempt: PingVerificationAttempt? {
        attempts.first { $0.result.status != .offline }
    }
}

final class PingVerificationEngine: Sendable {
    struct Configuration: Sendable {
        var offlineVerificationCount: Int = 4
        var onlineVerificationCount: Int = 2
        var verificationIntervalMilliseconds: UInt64 = 100
    }

    private let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    func verifyOffline(
        ping: @escaping @Sendable () async -> PingEngine.PingResult
    ) async -> PingVerificationBurstResult {
        var attempts: [PingVerificationAttempt] = []

        for index in 0..<configuration.offlineVerificationCount {
            let result = await ping()
            let attempt = PingVerificationAttempt(timestamp: Date(), result: result)
            attempts.append(attempt)

            if result.status != .offline {
                return PingVerificationBurstResult(confirmed: false, attempts: attempts)
            }

            if index < configuration.offlineVerificationCount - 1 {
                try? await Task.sleep(nanoseconds: configuration.verificationIntervalMilliseconds * 1_000_000)
            }
        }

        return PingVerificationBurstResult(confirmed: true, attempts: attempts)
    }

    func verifyOnline(
        ping: @escaping @Sendable () async -> PingEngine.PingResult
    ) async -> PingVerificationBurstResult {
        var attempts: [PingVerificationAttempt] = []

        for index in 0..<configuration.onlineVerificationCount {
            let result = await ping()
            let attempt = PingVerificationAttempt(timestamp: Date(), result: result)
            attempts.append(attempt)

            guard result.status != .offline else {
                return PingVerificationBurstResult(confirmed: false, attempts: attempts)
            }

            if index < configuration.onlineVerificationCount - 1 {
                try? await Task.sleep(nanoseconds: configuration.verificationIntervalMilliseconds * 1_000_000)
            }
        }

        return PingVerificationBurstResult(confirmed: true, attempts: attempts)
    }
}
