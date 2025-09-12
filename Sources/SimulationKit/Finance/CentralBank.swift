//
//  CentralBank.swift
//  SimulationKit
//

import Foundation

public struct CentralBank: Equatable {
    var eventCaptures: [Capture<Event>] = []

    public var riskFreeRate: Int

    public enum Event: Equatable {
        case changeRiskFreeRate(id: String, rate: Int)

        var id: String {
            switch self {
            case .changeRiskFreeRate(id: let id, rate: _):
                return id
            }
        }
    }

    public init(
        riskFreeRate: Int,
        eventCaptures: [Capture<Event>]
    ) {
        self.riskFreeRate = riskFreeRate
        self.eventCaptures = eventCaptures
    }

    func changeRiskFreeRate(
        rate: Int,
        at period: UInt32
    ) -> Self {
        return Self(
            riskFreeRate: rate,
            eventCaptures: eventCaptures + [
                Capture(
                    entity: .changeRiskFreeRate(
                        id: UUID().uuidString,
                        rate: rate
                    ),
                    timestamp: period
                )
            ]
        )
    }

    public func apply(
        event: Event,
        at period: UInt32
    ) -> Self {
        switch event {
        case .changeRiskFreeRate(id: _, rate: let rate):
            return changeRiskFreeRate(
                rate: rate,
                at: period
            )
        }
    }
}
