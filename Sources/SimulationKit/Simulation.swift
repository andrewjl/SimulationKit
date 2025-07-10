//
//  Simulation.swift
//  
//

import Foundation

struct RiskFreeRate: Equatable {
    static var `default` = 10

    var rate: Int
}

class StateGenerator {
    static func generate(from model: ConceptualModel) -> Simulation.State {
        self.generate(
            from: model.initialEvents()
        )
    }

    static func generate(from initialEvents: [Simulation.Event]) -> Simulation.State {
        let riskFreeRate = riskFreeRate(from: initialEvents)
        let ledgers = ledgers(from: initialEvents)

        return Simulation.State(
            ledgers: ledgers,
            riskFreeRate: riskFreeRate
        )
    }

    static func ledgers(
        from initialEvents: [Simulation.Event]
    ) -> [Ledger] {
        var ledgers = [UInt: Ledger]()

        for case let Simulation.Event.createEmptyLedger(ledgerID) in initialEvents {
            ledgers[ledgerID] = Ledger(id: ledgerID)
        }

        for case let Simulation.Event.createAsset(balance, ledgerID) in initialEvents {
            ledgers[ledgerID] = ledgers[ledgerID, default: Ledger(id: ledgerID)]
                .adding(Asset.make(from: balance))
        }

        for case let Simulation.Event.createLiability(balance, ledgerID) in initialEvents {
            ledgers[ledgerID] = ledgers[ledgerID, default: Ledger(id: ledgerID)]
                .adding(Liability.make(from: balance))
        }

        return Array<Ledger>(ledgers.values)
    }

    static func riskFreeRate(
        from initialEvents: [Simulation.Event]
    ) -> RiskFreeRate {
        var rate = RiskFreeRate.default
        for case let Simulation.Event.changeRiskFreeRate(newRate) in initialEvents {
            rate = newRate
        }
        return RiskFreeRate(rate: rate)
    }
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
            case .createEmptyLedger(ledgerID: let ledgerID):
                let ledger = Ledger(
                    id: ledgerID,
                    assets: [],
                    liabilities: []
                )
                return State(
                    ledgers: ledgers + [ledger],
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
        model: ConceptualModel
    ) {
        self.capture = Capture(
            entity: StateGenerator.generate(from: model),
            timestamp: Clock.startingTime
        )

        self.totalPeriods = model.duration
        self.plannedEvents = model.plannedEvents
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
        return ledger.adjustAllAssetBalances(
            by: self.state.riskFreeRate.rate
        ) + ledger.adjustAllLiabilityBalances(
            by: self.state.riskFreeRate.rate
        )
    }
}

extension Simulation {
    enum Event: Equatable {
        case changeRiskFreeRate(newRate: Int)
        case ledgerTransactions(transactions: [Ledger.Event], ledgerID: UInt)
        case createAsset(balance: Decimal, ledgerID: UInt)
        case createLiability(balance: Decimal, ledgerID: UInt)
        case createEmptyLedger(ledgerID: UInt)
    }
}

extension Simulation {
    static func make(from model: Model) -> Simulation {
        Asset.autoincrementedID = 0
        Liability.autoincrementedID = 0
        Ledger.autoincrementedID = 0

        let simulation = Simulation(
            model: model
        )

        return simulation
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
