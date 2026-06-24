import Foundation

// Uses /sbin/ping but keeps timeout handling Swift-6-safe.
// No NSLock, no captured mutable state in @Sendable closures.
enum PingEngine {
    struct PingResult: Sendable {
        let status: DeviceStatus
        let rtt: Double?
        let rawOutput: String
    }

    static func ping(
        ipAddress: String,
        timeoutMilliseconds: Int = 1000,
        sourceIPAddress: String? = nil,
        sourceInterfaceName: String? = nil,
        deviceID: UUID? = nil,
        deviceLabel: String = "Ping Device"
    ) async -> PingResult {
        await Task.detached(priority: .utility) {
            let trimmedIP = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSourceIP = sourceIPAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedInterfaceName = sourceInterfaceName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let safeTimeout = max(100, min(5000, timeoutMilliseconds))

            guard !trimmedIP.isEmpty else {
                ConsoleOutputStore.log(
                    subsystem: "Ping",
                    direction: .error,
                    deviceID: deviceID,
                    deviceLabel: deviceLabel,
                    ipAddress: nil,
                    message: "Empty IP address"
                )
                return PingResult(status: .offline, rtt: nil, rawOutput: "Empty IP address")
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/sbin/ping")

            var arguments = [
                "-n",
                "-c", "1",
                "-W", String(safeTimeout)
            ]

            // On macOS, -S only selects the source address. That is not enough when
            // two NICs advertise the same subnet. -b binds the socket to the BSD
            // interface name, e.g. en7/en8, so the probe leaves the selected NIC.
            if let trimmedInterfaceName, !trimmedInterfaceName.isEmpty {
                arguments += ["-b", trimmedInterfaceName]
            }

            if let trimmedSourceIP, !trimmedSourceIP.isEmpty {
                arguments += ["-S", trimmedSourceIP]
            }

            arguments.append(trimmedIP)
            process.arguments = arguments

            ConsoleOutputStore.log(
                subsystem: "Ping",
                direction: .command,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: trimmedIP,
                message: (["/sbin/ping"] + arguments).joined(separator: " ")
            )

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()

                let timer = DispatchSource.makeTimerSource(
                    queue: DispatchQueue.global(qos: .utility)
                )

                timer.schedule(deadline: .now() + .milliseconds(safeTimeout))

                timer.setEventHandler {
                    if process.isRunning {
                        process.terminate()

                        DispatchQueue.global(qos: .utility).asyncAfter(
                            deadline: .now() + .milliseconds(80)
                        ) {
                            if process.isRunning {
                                kill(process.processIdentifier, SIGKILL)
                            }
                        }
                    }
                }

                timer.resume()

                process.waitUntilExit()
                timer.cancel()

                let stdoutData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                let combinedOutput = stdout + "\n" + stderr
                let rtt = extractRTT(from: combinedOutput)

                ConsoleOutputStore.log(
                    subsystem: "Ping",
                    direction: process.terminationStatus == 0 ? .output : .error,
                    deviceID: deviceID,
                    deviceLabel: deviceLabel,
                    ipAddress: trimmedIP,
                    message: combinedOutput
                )

                if process.terminationStatus == 0 {
                    if let rtt {
                        return PingResult(
                            status: rtt <= Double(safeTimeout) ? .healthy : .slow,
                            rtt: rtt,
                            rawOutput: combinedOutput
                        )
                    }

                    return PingResult(status: .healthy, rtt: nil, rawOutput: combinedOutput)
                }

                return PingResult(status: .offline, rtt: nil, rawOutput: combinedOutput)
            } catch {
                let message = """
                Failed to launch /sbin/ping: \(error.localizedDescription)

                If this says Operation not permitted, disable App Sandbox for the Mping target.
                """
                ConsoleOutputStore.log(
                    subsystem: "Ping",
                    direction: .error,
                    deviceID: deviceID,
                    deviceLabel: deviceLabel,
                    ipAddress: trimmedIP,
                    message: message
                )
                return PingResult(status: .offline, rtt: nil, rawOutput: message)
            }
        }.value
    }

    private nonisolated static func extractRTT(from output: String) -> Double? {
        if let range = output.range(of: #"time[=<]([0-9.]+)\s*ms"#, options: .regularExpression) {
            let match = String(output[range])
            let cleaned = match
                .replacingOccurrences(of: "time=", with: "")
                .replacingOccurrences(of: "time<", with: "")
                .replacingOccurrences(of: "ms", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(cleaned)
        }

        if let range = output.range(of: #"=\s*([0-9.]+)/([0-9.]+)/([0-9.]+)/([0-9.]+)\s*ms"#, options: .regularExpression) {
            let match = String(output[range])
            let cleaned = match
                .replacingOccurrences(of: "=", with: "")
                .replacingOccurrences(of: "ms", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = cleaned.split(separator: "/")
            if parts.count >= 2 {
                return Double(parts[1])
            }
        }

        return nil
    }
}
