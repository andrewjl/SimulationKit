//
//  Simulation.swift
//  
//

import Foundation

struct RiskFreeRate: Equatable {
    var rate: Int
}

class Simulation {
    struct State: Equatable {
        var ledgers: [Ledger]
        var riskFreeRate: RiskFreeRate

        func apply(event: Event) -> Self {
            switch event {
            case .changeRiskFreeRate(newRate: let rate):
                return State(ledgers: ledgers, riskFreeRate: RiskFreeRate(rate: rate))
            case .ledgerTransactions(transactions: let transactions, ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers.map { $0.id == ledgerID ? $0.tick(events: transactions) : $0 },
                    riskFreeRate: self.riskFreeRate
                )
            }
        }
    }

    var state: State
    var totalPeriods: UInt32
    var plannedEvents: [Capture<Event>]

    init(
        ledgers: [Ledger],
        rate: RiskFreeRate,
        totalPeriods: UInt32,
        plannedEvents: [Capture<Event>] = []
    ) {
        self.state = State(ledgers: ledgers, riskFreeRate: rate)
        self.totalPeriods = totalPeriods
        self.plannedEvents = plannedEvents
    }

    func start(clock: Clock) -> Step {
        guard clock.time == Clock.startingTime else {
            fatalError("Can only start simulation once.")
        }

        let events: [Simulation.Event] = []
        let capture = SimulationCapture(entity: (state: state, events: events), timestamp: clock.time)

        let _ = clock.next()

        return Step(
            capture: capture,
            totalPeriods: totalPeriods
        )
    }

    func tick(clock: Clock) -> Step {
        guard clock.time > Clock.startingTime else {
            fatalError("Simulation not started yet.")
        }

        let tick = clock.current()
        let step = successiveStep(tick: tick)
        let _ = clock.next()
        return step
    }

    func successiveStep(tick: Tick) -> Step {
        let relevantPlannedEvents = plannedEvents.filter({ $0.timestamp == tick.time }).map { $0.entity }

        for event in relevantPlannedEvents {
            state = state.apply(event: event)
        }
        let computedEvents = self.computedEvents(state: state)

        for computedEvent in computedEvents {
            state = state.apply(event: computedEvent)
        }

        let capture = SimulationCapture(
            entity: (
                state: state,
                events: relevantPlannedEvents + computedEvents
            ),
            timestamp: tick.time
        )

        return Step(
            capture: capture,
            totalPeriods: totalPeriods
        )
    }

    func computedEvents(state: State) -> [Simulation.Event] {
        return self.state.ledgers
            .map {
                Simulation.Event.ledgerTransactions(
                    transactions: self.computeEvents(ledger: $0),
                    ledgerID: $0.id
                )
            }
    }

    func preplannedEvents(tick: Tick) -> [Simulation.Event] {
        return plannedEvents
            .filter({ $0.timestamp == tick.time })
            .map { $0.entity }
    }

    func upcomingEvents(
        state: State,
        tick: Tick
    ) -> [Simulation.Event] {
        return computedEvents(state: state) + preplannedEvents(tick: tick)
    }

    func computeEvents(ledger: Ledger) -> [Ledger.Event] {
        let increaseAssetLedgerEvents = ledger.assets.map {
            Ledger.Event.asset(
                transaction: $0.increaseTransaction(by: UInt(self.state.riskFreeRate.rate)),
                id: $0.id
            )
        }
        let increaseLiabilityLedgerEvents = ledger.liabilities.map {
            Ledger.Event.liability(
                transaction: $0.increaseTransaction(by: UInt(self.state.riskFreeRate.rate)),
                id: $0.id
            )
        }

        return increaseAssetLedgerEvents + increaseLiabilityLedgerEvents
    }
}

extension Simulation {
    enum Event {
        case changeRiskFreeRate(newRate: Int)
        case ledgerTransactions(transactions: [Ledger.Event], ledgerID: UInt)
    }
}

extension Simulation {
    static func make(from model: Model) -> Simulation {
        let assets = (1...model.assetsCount).map {
            Asset(id: UInt($0), balance: model.initialAssetBalance)
        }

        let liabilities = (1...model.liabilitiesCount).map {
            Liability(id: UInt($0), balance: model.initialLiabilityBalance)
        }

        let ledgers = (1...model.ledgersCount).map {
            return Ledger(
                id: UInt($0),
                assets: assets,
                liabilities: liabilities
            )
        }

        let riskFreeRate = RiskFreeRate(rate: Int(model.rate))

        let execModel = Simulation(
            ledgers: ledgers,
            rate: riskFreeRate,
            totalPeriods: model.duration
        )

        return execModel
    }
}

typealias SimulationCapture = Capture<(state: Simulation.State, events: [Simulation.Event])>

struct Step {
    var capture: SimulationCapture
    var totalPeriods: UInt32

    var currentPeriod: UInt32 {
        capture.timestamp
    }
    var isFinal: Bool {
        return currentPeriod == totalPeriods
    }
}
