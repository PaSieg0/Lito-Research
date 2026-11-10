// Personal research extension to FreeFCC. See LICENSE and NOTICE.md.
// Protocol facts referenced in docs/LITO-RESEARCH.md; no Android code copied.
import Foundation

enum LitoAltitudeParameter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case shortName = "flying_limit.max_height_0"
    case prefixedName = "g_config.flying_limit.max_height_0"
    var id: String { rawValue }
    var hash: UInt32 { ParamHash.of(rawValue) }
    var hashBytes: [UInt8] {
        (0..<4).map { UInt8(truncatingIfNeeded: hash >> ($0 * 8)) }
    }
}

enum LitoCommandIdentity: String, CaseIterable, Identifiable, Hashable, Sendable {
    case app4 = "App index 4"
    case app0 = "App index 0"
    var id: String { rawValue }
    var sender: Int { self == .app4 ? 0x82 : 0x02 }
    var commandType: Int { self == .app4 ? 0x20 : 0x40 }
}

enum LitoAltitudeReply: Equatable, Sendable {
    case value(UInt16)
    case rejected(UInt8)
    case incomplete
    case wrongParameter
}

struct LitoAltitudeRequest: Sendable {
    let parameter: LitoAltitudeParameter
    let identity: LitoCommandIdentity
    let command: Int = 0xF8
    let sequence: Int

    func matchesHeader(_ response: DumplResponse) -> Bool {
        response.isResponse && response.sender == 0x03
            && response.dst == identity.sender && response.seq == sequence
            && response.cmdSet == 0x03 && response.cmdId == command
    }

    func decode(_ response: DumplResponse) -> LitoAltitudeReply? {
        guard matchesHeader(response), let status = response.payload.first else { return nil }
        guard status == 0 else { return .rejected(status) }
        guard response.payload.count >= 5 else { return .incomplete }
        guard Array(response.payload[1..<5]) == parameter.hashBytes else { return .wrongParameter }
        // The reported altitude transaction uses uint16. Do not guess a width
        // or decode unrelated telemetry / a bare ACK as a stored value.
        guard response.payload.count == 7 else { return .incomplete }
        return .value(UInt16(response.payload[5]) | (UInt16(response.payload[6]) << 8))
    }

    var frame: DumplFrame {
        DumplFrame(sender: identity.sender, cmdType: identity.commandType,
                   cmdSet: 0x03, cmdId: command, dst: 0x03,
                   payload: parameter.hashBytes)
    }
}

struct LitoAltitudeReading: Identifiable, Sendable {
    let id: UUID
    let session: UUID
    let parameter: LitoAltitudeParameter
    let identity: LitoCommandIdentity
    let framing: Framing
    let value: UInt16
    let receivedAt: Date


}

/// Captures only a response to the exact request, independently of the old
/// FCC sweep's command-set-only ACK counter. Bounded and thread safe.
final class LitoReplyInbox: @unchecked Sendable {
    private let condition = NSCondition()
    private var request: LitoAltitudeRequest?
    private var result: LitoAltitudeReply?
    private var cancelled = false

    func begin(_ request: LitoAltitudeRequest) {
        condition.lock(); defer { condition.unlock() }
        self.request = request
        result = nil
        cancelled = false
    }

    func receive(_ response: DumplResponse) {
        condition.lock(); defer { condition.unlock() }
        guard result == nil, let decoded = request?.decode(response) else { return }
        result = decoded
        condition.signal()
    }

    func wait(seconds: TimeInterval) -> LitoAltitudeReply? {
        condition.lock(); defer { condition.unlock() }
        let deadline = Date().addingTimeInterval(seconds)
        while !cancelled, result == nil, condition.wait(until: deadline) {}
        request = nil
        return result
    }

    func cancel() {
        condition.lock(); defer { condition.unlock() }
        request = nil
        result = nil
        cancelled = true
        condition.broadcast()
    }
}
