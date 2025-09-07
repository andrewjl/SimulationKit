//
//  CentralBank.swift
//  SimulationKit
//

struct CentralBank: Equatable {
    var eventCaptures: [Capture<Event>] = []

    var riskFreeRate: Int

    enum Event: Equatable {
        case changeRiskFreeRate(rate: Int)
    }

    init(
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
                        rate: rate
                    ),
                    timestamp: period
                )
            ]
        )
    }

    func apply(
        event: Event,
        at period: UInt32
    ) -> Self {
        switch event {
        case .changeRiskFreeRate(rate: let rate):
            return changeRiskFreeRate(
                rate: rate,
                at: period
            )
        }
    }
}
