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
            ledger: .make(),
            eventCaptures: [],
            riskFreeRate: 0,
            loanRate: 0,
            accounts: [:]
        )
        let ledgers = ledgers(from: initialEvents)

        return Simulation.State(
            ledgers: ledgers,
            bank: bank
        )
    }

    static func ledgers(
        from initialEvents: [Simulation.Event]
    ) -> [Ledger] {
        var ledgers = [String: Ledger]()

        for case let Simulation.Event.createEmptyLedger(ledgerID) in initialEvents {
            ledgers[ledgerID] = Ledger(id: ledgerID)
        }

        for case let Simulation.Event.createAsset(balance, ledgerID) in initialEvents {
            ledgers[ledgerID] = ledgers[ledgerID, default: Ledger(id: ledgerID)]
                .adding(
                    Asset.make(
                        from: balance,
                        name: ""
                    )
                )
        }

        for case let Simulation.Event.createLiability(balance, ledgerID) in initialEvents {
            ledgers[ledgerID] = ledgers[ledgerID, default: Ledger(id: ledgerID)]
                .adding(Liability.make(from: balance))
        }

        return Array<Ledger>(ledgers.values)
    }
}

class Simulation {
    struct State {
        var ledgers: [Ledger]
        var bank: Bank

        func applying(event: Event) -> Self {
            switch event {
            case .ledgerTransactions(transactions: let transactions, ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers.map { $0.id == ledgerID ? $0.evented(transactions) : $0 },
                    bank: bank
                )
            case .createAsset(balance: let balance, ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers.map { $0.id == ledgerID ? $0.adding(Asset.make(
                        from: balance,
                        name: ""
                    )) : $0 },
                    bank: bank
                )
            case .createLiability(balance: let balance, ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers.map { $0.id == ledgerID ? $0.adding(Liability.make(from: balance)) : $0 },
                    bank: bank
                )
            case .createEmptyLedger(ledgerID: let ledgerID):
                let ledger = Ledger(
                    id: ledgerID,
                    assets: [],
                    liabilities: [],
                    equities: [],
                    revenues: [],
                    expenses: []
                )
                return State(
                    ledgers: ledgers + [ledger],
                    bank: bank
                )
            case .bankEvent(event: let event, period: let period):
                return State(
                    ledgers: ledgers,
                    bank: bank.applyingEvent(
                        event: event,
                        period: period
                    )
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
        let successiveState = events.reduce(state, { $0.applying(event: $1) })

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

    func computedEvents(state: State) -> [Simulation.Event] {
        return self.state.ledgers
            .map {
                Simulation.Event.ledgerTransactions(
                    transactions: $0.eventsAdjustingAllBalances(
                        by: self.capture.entity.bank.riskFreeRate
                    ),
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
}

extension Simulation.State: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.bank == rhs.bank &&
        lhs.ledgers == rhs.ledgers
    }
}

extension Simulation {
    enum Event: Equatable {
        case ledgerTransactions(transactions: [Ledger.Event], ledgerID: String)
        case createAsset(balance: Decimal, ledgerID: String)
        case createLiability(balance: Decimal, ledgerID: String)
        case createEmptyLedger(ledgerID: String)
        case bankEvent(event: Bank.Event, period: UInt32)
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
