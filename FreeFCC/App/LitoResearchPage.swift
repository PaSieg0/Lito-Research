// Personal research extension to FreeFCC. See LICENSE and NOTICE.md.
import SwiftUI

struct LitoResearchPage: View {
    @Environment(FccController.self) private var controller
    @State private var parameter = LitoAltitudeParameter.prefixedName
    @State private var identity = LitoCommandIdentity.app4
    @State private var framing = Framing.rclink
    @State private var confirmedLito = false
    @State private var confirmedGrounded = false

    private var selectedReading: LitoAltitudeReading? {
        guard let reading = controller.litoAltitudeReading,
              reading.parameter == parameter, reading.identity == identity,
              reading.framing == framing else { return nil }
        return reading
    }

    var body: some View {
        PageBackground {
            PageTitle(title: "Lito Research", symbol: "magnifyingglass")
            GlowCard {
                Text("UNOFFICIAL EXPERIMENTAL BUILD")
                    .font(.caption.bold()).foregroundStyle(Palette.amber)
                BodyText("Read-only parameter diagnostics for Lito X1 + RC-N3. RC 2 research uses a different transport. This variant cannot change altitude settings.")
                    .padding(.top, 8)
                InfoRow(label: "Version", value: AppInfo.versionAndBuild)
                    .padding(.top, 12)
            }

            GlowCard {
                Text(controller.isConnected ? "Controller connected" : "Controller disconnected")
                    .foregroundStyle(Palette.textWhite).font(.headline)
                BodyText(controller.aircraftLinked ? "Aircraft telemetry received. This does not verify parameter access." : "No aircraft telemetry received.")
                    .padding(.vertical, 10)
                if controller.isConnected {
                    GlowButton(title: "Release connection", filled: false,
                               enabled: !controller.isBusy) { controller.releaseSession() }
                } else {
                    BodyText("Connect the iPhone to the RC-N3 phone port. Open DJI Fly until the camera feed appears, then close DJI Fly and connect here. Keep the motors stopped.")
                        .padding(.bottom, 12)
                    GlowButton(title: "Connect", enabled: !controller.isBusy) { controller.connect() }
                }
            }

            GlowCard {
                Toggle("My aircraft is a Lito X1 with RC-N3", isOn: $confirmedLito)
                    .foregroundStyle(Palette.textWhite)
                Toggle("Aircraft grounded, motors stopped", isOn: $confirmedGrounded)
                    .foregroundStyle(Palette.textWhite)
                Text("Parameter name").foregroundStyle(Palette.textWhite).padding(.top, 14)
                Picker("Parameter name", selection: $parameter) {
                    ForEach(LitoAltitudeParameter.allCases) { item in Text(item.rawValue).tag(item) }
                }
                Text("Command identity").foregroundStyle(Palette.textWhite)
                Picker("Command identity", selection: $identity) {
                    ForEach(LitoCommandIdentity.allCases) { item in Text(item.rawValue).tag(item) }
                }
                Text("MFi framing").foregroundStyle(Palette.textWhite)
                Picker("MFi framing", selection: $framing) {
                    ForEach(Framing.allCases) { item in Text(item.label).tag(item) }
                }
                BodyText("Select one name and path per test. The short name is a hypothesis; no parameter writes are available. No RC 2 localhost ports are used.")
                    .padding(.vertical, 10)
                GlowButton(title: "Read current altitude parameter", tint: Palette.cyan,
                           enabled: confirmedLito && confirmedGrounded && controller.isConnected && controller.aircraftLinked && !controller.isBusy) {
                    controller.readLitoAltitude(parameter: parameter, identity: identity, framing: framing)
                }
            }

            GlowCard {
                Text("Diagnostic result").foregroundStyle(Palette.textWhite).font(.headline)
                BodyText(controller.litoAltitudeMessage, color: Palette.amber).padding(.vertical, 12)
                if let reading = selectedReading {
                    InfoRow(label: "Parameter read", value: "\(reading.value) m")
                    BodyText("A parameter value does not prove DJI Fly accepts it or that a flight ceiling changed.")
                        .padding(.vertical, 10)
                }
                BodyText("A missing reply leaves the stored value unknown. This diagnostic does not modify drone settings.")

            }

            GlowCard {
                BodyText("Derived from Andrea Piani's FreeFCC 1.8.2. Personal research extension; not an official release. PolyForm Noncommercial 1.0.0.")
                Link("Research notes: lmdegreeds/dji_fcc_gpsoff", destination: URL(string: "https://github.com/lmdegreeds/dji_fcc_gpsoff")!)
                    .padding(.top, 8)
                Link("Upstream application", destination: URL(string: "https://github.com/andreapianidev/DJI-FCC-Unlock-iOS")!)
                    .padding(.top, 8)
            }
        }
        .disabled(controller.isBusy)
    }
}
