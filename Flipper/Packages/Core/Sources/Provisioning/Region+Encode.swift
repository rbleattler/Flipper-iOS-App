import Peripheral
import Foundation
import SwiftProtobuf

extension Provisioning.Region {
    func encode() throws -> [UInt8] {
        try .init(_encode())
    }

    private func _encode() throws -> Data {
        try PB_Region
            .with {
                $0.countryCode = .init((country ?? "").utf8)
                $0.bands = .init(bands)
            }
            .serializedData()
    }
}

extension Array where Element == PB_Region.Band {
    init(_ bands: [Provisioning.Band]) {
        self = bands.map { band in
            PB_Region.Band.with {
                $0.start = UInt32(band.start)
                $0.end = UInt32(band.end)
                $0.powerLimit = Int32(band.maxPower)
                $0.dutyCycle = UInt32(band.dutyCycle)
            }
        }
    }
}
