//
//  Simulation.swift
//  
//

import Foundation

class Simulation {
    struct State {
        var ledgers: [Ledger]
        var banks: [Bank]
        var centralBank: CentralBank

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
                    centralBank: centralBank
                )
            case .ledgerEvent(event: let event, ledgerID: let ledgerID):
                return State(
                    ledgers: ledgers.map { $0.id == ledgerID ? $0.applying(event: event, at: period) : $0 },
                    banks: banks,
                    centralBank: centralBank
                )
            case .createBank(startingCapital: let startingCapital, bankLedgerID: let bankLedgerID):
                return State(
                    ledgers: ledgers,
                    banks: banks + [
                        Bank(
                            loanRateSpread: centralBank.riskFreeRate,
                            startingCapital: startingCapital,
                            startingPeriod: period,
                            bankLedgerID: bankLedgerID
                        )
                    ],
                    centralBank: centralBank
                )
            case .bankEvent(event: let bankEvent, bankLedgerID: let bankLedgerID):
                return State(
                    ledgers: ledgers,
                    banks: banks.map {
                        $0.ledger.id == bankLedgerID ? $0.applying(event: bankEvent, at: period) : $0
                    },
                    centralBank: centralBank
                )
            case .centralBankEvent(event: let centralBankEvent):
                return State(
                    ledgers: ledgers,
                    banks: banks,
                    centralBank: centralBank.apply(
                        event: centralBankEvent,
                        at: period
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
        var state = Simulation.State(
            ledgers: [],
            banks: [],
            centralBank: CentralBank(
                riskFreeRate: 0,
                eventCaptures: []
            )
        )

        for event in model.initialEvents() {
            state = state.applying(
                event: event,
                period: 0
            )
        }

        self.capture = Capture(
            entity: state,
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
        lhs.centralBank == rhs.centralBank
    }
}

extension Simulation {
    enum Event: Equatable {
        case createEmptyLedger(ledgerID: String)
        case ledgerEvent(event: Ledger.Event, ledgerID: String)
        case createBank(startingCapital: Decimal, bankLedgerID: String)
        case bankEvent(event: Bank.Event, bankLedgerID: String)
        case centralBankEvent(event: CentralBank.Event)
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
