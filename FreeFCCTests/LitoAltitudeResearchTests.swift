// Personal research extension to FreeFCC. See LICENSE and NOTICE.md.
import Foundation
import Testing
@testable import FreeFCC

struct LitoAltitudeResearchTests {
    private func request() -> LitoAltitudeRequest {
        LitoAltitudeRequest(parameter: .prefixedName, identity: .app4, sequence: 421)
    }

    private func response(_ request: LitoAltitudeRequest, value: UInt16 = 120,
                          hash: [UInt8]? = nil, sequence: Int? = nil,
                          status: UInt8 = 0) throws -> DumplResponse {
        let payload = [status] + (hash ?? request.parameter.hashBytes)
            + [UInt8(truncatingIfNeeded: value), UInt8(truncatingIfNeeded: value >> 8)]
        return try #require(DumplResponse(frame: DumplBuilder.buildFrame(
            DumplFrame(sender: 0x03, cmdType: 0x80, cmdSet: 0x03,
                       cmdId: request.command, dst: request.identity.sender, payload: payload),
            seq: sequence ?? request.sequence)))
    }

    @Test func staleOrUnrelatedRepliesCannotBecomeAReading() throws {
        let request = request()
        #expect(request.decode(try response(request, sequence: 420)) == nil)
        #expect(request.decode(try response(request, hash: [0, 0, 0, 0])) == .wrongParameter)
        var wrongDestination = try response(request)
        wrongDestination.dst = 0x02
        #expect(request.decode(wrongDestination) == nil)
        var unsolicited = try response(request)
        unsolicited.cmdType = 0x00
        #expect(request.decode(unsolicited) == nil)
    }

    @Test func bareAckCannotBecomeAStoredValue() throws {
        let request = request()
        var reply = try response(request)
        reply.payload = [0]
        #expect(request.decode(reply) == .incomplete)
        #expect(request.decode(try response(request, status: 1)) == .rejected(1))
        reply.payload = [0] + request.parameter.hashBytes + [0xF4, 0x01, 0, 0]
        #expect(request.decode(reply) == .incomplete)
    }

    @Test func requestIsAlwaysReadOnly() {
        let read = request()
        #expect(read.frame.cmdId == 0xF8)
        #expect(read.frame.payload == read.parameter.hashBytes)
    }

    @Test func legacyHashMatchesPublishedCaptureAndNamesDiffer() {
        #expect(LitoAltitudeParameter.prefixedName.hash == 0x0371238A)
        #expect(LitoAltitudeParameter.shortName.hash != LitoAltitudeParameter.prefixedName.hash)
    }
}
