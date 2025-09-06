//
//  Simulation.swift
//  
//

import Foundation

class StateGenerator {
    static func generate(from model: ConceptualModel) -> Simulation.State {
        self.generate(
            from: model.initialEvents()
        )
    }

    static func generate(from initialEvents: [Simulation.Event]) -> Simulation.State {
        let bank = Bank(
            ledger: .make(at: 0),
            eventCaptures: [],
            riskFreeRate: 0,
            loanRate: 0,
            accounts: [:]
        )
        let ledgers = ledgers(from: initialEvents)

        return Simulation.State(
            ledgers: ledgers,
            banks: [bank],
            riskFreeRate: 0
        )
    }

    static func ledgers(
        from initialEvents: [Simulation.Event]
    ) -> [Ledger] {
        var ledgers = [String: Ledger]()

        for case let Simulation.Event.createEmptyLedger(ledgerID) in initialEvents {
            ledgers[ledgerID] = Ledger(id: ledgerID, generalJournal: [])
        }

        for case let Simulation.Event.ledgerEvent(event: event, ledgerID: ledgerID) in initialEvents {
            ledgers[ledgerID] = ledgers[ledgerID]?.applying(event: event, at: 0)
        }

        return Array<Ledger>(ledgers.values)
    }
}

class Simulation {
    struct State {
        var ledgers: [Ledger]
        var banks: [Bank]
        var riskFreeRate: Int

        func applying(
            event: Event,
            period: UInt32
        ) -> Self {
            switch event {
            case .createEmptyLedger(ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers + [
                        Ledger.make(
                            id: ledgerID,
                            at: period
                        )
                    ],
                    banks: banks,
                    riskFreeRate: riskFreeRate
                )
            case .ledgerEvent(event: let event, ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers.map { $0.id == ledgerID ? $0.applying(event: event, at: period) : $0 },
                    banks: banks,
                    riskFreeRate: riskFreeRate
                )
            case .createBank(startingCapital: let startingCapital, bankLedgerID: let bankLedgerID):
                return State(
                    ledgers: ledgers,
                    banks: banks + [
                        Bank(
                            riskFreeRate: riskFreeRate,
                            loanRate: riskFreeRate,
                            startingCapital: startingCapital,
                            startingPeriod: period,
                            bankLedgerID: bankLedgerID
                        )
                    ],
                    riskFreeRate: riskFreeRate
                )
            case .bankEvent(event: let bankEvent, bankLedgerID: let bankLedgerID):
                return State(
                    ledgers: ledgers,
                    banks: banks.map {
                        $0.ledger.id == bankLedgerID ? $0.applying(event: bankEvent, at: period) : $0
                    },
                    riskFreeRate: riskFreeRate
                )
            case .changeRiskFreeRate(newRiskFreeRate: let newRiskFreeRate):
                return State(
                    ledgers: ledgers,
                    banks: banks.map { $0.applying(event: .changeRiskFreeRate(rate: newRiskFreeRate), at: period) },
                    riskFreeRate: newRiskFreeRate
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
        let events = upcomingEvents(state: state, tick: tick)
        let successiveState = events.reduce(state, { $0.applying(event: $1, period: tick.time) })

        capture = Capture(
            entity: successiveState,
            timestamp: tick.time
        )

        let simulationCapture = SimulationCapture(
            entity: (
                state: state,
                events: events
            ),
            timestamp: tick.time
        )

        return Step(
            capture: simulationCapture,
            totalPeriods: totalPeriods
        )
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
        return preplannedEvents(tick: tick)
    }
}

extension Simulation.State: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.banks == rhs.banks &&
        lhs.ledgers == rhs.ledgers &&
        lhs.riskFreeRate == rhs.riskFreeRate
    }
}

extension Simulation {
    enum Event: Equatable {
        case createEmptyLedger(ledgerID: String)
        case ledgerEvent(event: Ledger.Event, ledgerID: String)
        case createBank(startingCapital: Decimal, bankLedgerID: String)
        case bankEvent(event: Bank.Event, bankLedgerID: String)
        case changeRiskFreeRate(newRiskFreeRate: Int)
    }
}

extension Simulation {
    static func make(from model: Model) -> Simulation {
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

extension Simulation {
    struct Plan {

        var ledgerIDs: [String]

        var ledgersCount: UInt32 {
            UInt32(ledgerIDs.count)
        }

        var plannedEvents: [Capture<Simulation.Event>] {
            return ledgerIDs.map { ledgerID in
                Capture(
                    entity: Event.createEmptyLedger(
                        ledgerID: ledgerID
                    ),
                    timestamp: 0
                )
            }
        }
    }

    static func makePlan(
        ledgersCount: UInt32,
        startingTime: UInt32 = Clock.startingTime
    ) -> Plan {
        let ledgerIDs = (0..<ledgersCount)
            .map { _ in UUID().uuidString }

        return Plan(
            ledgerIDs: ledgerIDs
        )
    }

    static func makePlan(
        ledgersCount: UInt32 = 1,
        assetsCountAtStart: UInt32 = 0,
        liabilitiesCountAtStart: UInt32 = 0,
        startingTime: UInt32 = Clock.startingTime
    ) -> Plan {
        let ledgerIDs = (0..<ledgersCount)
            .map { _ in UUID().uuidString }

        return Plan(
            ledgerIDs: ledgerIDs
        )
    }
}
