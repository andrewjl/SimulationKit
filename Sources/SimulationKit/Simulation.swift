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
            case .createAsset(balance: let balance, ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers.map { $0.id == ledgerID ? $0.adding(Asset.make(from: balance)) : $0 },
                    riskFreeRate: riskFreeRate
                )
            case .createLiability(balance: let balance, ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers.map { $0.id == ledgerID ? $0.adding(Liability.make(from: balance)) : $0 },
                    riskFreeRate: riskFreeRate
                )
            }
        }
    }
    private var capture: Capture<State>
    var state: State {
        capture.entity
    }
    var currentTime: UInt32 {
        capture.timestamp + 1
    }

    var totalPeriods: UInt32
    var plannedEvents: [Capture<Event>]

    init(
        ledgers: [Ledger],
        rate: RiskFreeRate,
        totalPeriods: UInt32,
        plannedEvents: [Capture<Event>] = []
    ) {
        self.capture = Capture(
            entity: State(ledgers: ledgers, riskFreeRate: rate),
            timestamp: Clock.startingTime
        )
        self.totalPeriods = totalPeriods
        self.plannedEvents = plannedEvents
    }

    func start(tick: Tick) -> Step {
        guard tick.time == Clock.startingTime else {
            fatalError("Can only start simulation once.")
        }

        let events: [Simulation.Event] = []
        let capture = SimulationCapture(entity: (state: state, events: events), timestamp: tick.time)

        return Step(
            capture: capture,
            totalPeriods: totalPeriods
        )
    }

    func tick(_ tick: Tick) -> Step {
        guard tick.time > Clock.startingTime else {
            fatalError("Simulation not started yet.")
        }

        guard tick.time == currentTime else {
            fatalError("Simulation not synchronized.")
        }

        return successiveStep(tick: tick)
    }

    func successiveStep(tick: Tick) -> Step {
        let relevantPlannedEvents = plannedEvents.filter({ $0.timestamp == tick.time }).map { $0.entity }

        for event in relevantPlannedEvents {
            capture = Capture(
                entity: state.apply(event: event),
                timestamp: tick.time
            )
        }
        let computedEvents = self.computedEvents(state: state)

        for computedEvent in computedEvents {
            capture = Capture(
                entity: state.apply(event: computedEvent),
                timestamp: tick.time
            )
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
    enum Event: Equatable {
        case changeRiskFreeRate(newRate: Int)
        case ledgerTransactions(transactions: [Ledger.Event], ledgerID: UInt)
        case createAsset(balance: Decimal, ledgerID: UInt)
        case createLiability(balance: Decimal, ledgerID: UInt)
    }
}

extension Simulation {
    static func make(from model: Model) -> Simulation {
        Asset.autoincrementedID = 0
        Liability.autoincrementedID = 0
        Ledger.autoincrementedID = 0

        let assets = (1...model.assetsCount).map { (_: Int) in
            Asset.make(from: model.initialAssetBalance)
        }

        let liabilities = (1...model.liabilitiesCount).map { (_: Int) in
            Liability.make(from: model.initialLiabilityBalance)
        }

        let ledgers = (1...model.ledgersCount).map { (_: Int) in
            return Ledger.make(
                assets: assets,
                liabilities: liabilities
            )
        }

        let riskFreeRate = RiskFreeRate(rate: Int(model.rate))

        let execModel = Simulation(
            ledgers: ledgers,
            rate: riskFreeRate,
            totalPeriods: model.duration,
            plannedEvents: model.plannedEvents
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
