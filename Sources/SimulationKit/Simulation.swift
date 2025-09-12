//
//  Simulation.swift
//  
//

import Foundation

public class Simulation {
    public struct State {
        public var ledgers: [Ledger]
        public var banks: [Bank]
        public var centralBank: CentralBank

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
            case .createBank(startingCapital: let startingCapital, loanRateSpread: let loanRateSpread, bankLedgerID: let bankLedgerID):
                return State(
                    ledgers: ledgers,
                    banks: banks + [
                        Bank(
                            loanRateSpread: loanRateSpread,
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

    public enum ExecutionMode: Equatable {
        case ready
        case started(Capture<State>)
        case completed(Capture<State>)
    }

    public var executionMode: ExecutionMode

    var totalPeriods: UInt32
    var plannedEvents: [Capture<Event>]

    let model: Model

    init(
        model: Model
    ) {
        self.model = model
        self.executionMode = .ready
        self.totalPeriods = model.duration
        self.plannedEvents = model.plannedEvents
    }

    public func start(tick: Tick) throws -> Step {
        guard case .ready = executionMode else {
            throw Error(
                description:"Can only start simulation once."
            )
        }

        return successiveStep(
            currentState: Simulation.State(
                ledgers: [],
                banks: [],
                centralBank: CentralBank(
                    riskFreeRate: 0,
                    eventCaptures: []
                )
            ),
            tick: tick
        )
    }

    public func tick(_ tick: Tick) throws -> Step {
        guard case .started(let capture) = executionMode else {
            throw Error(description:"Simulation not started yet.")
        }

        guard tick.time == capture.timestamp + tick.tickDuration else {
            throw Error(description:"Simulation not synchronized.")
        }

        let step = successiveStep(
            currentState: capture.entity,
            tick: tick
        )

        if step.isFinal {
            self.executionMode = .completed(
                Capture(
                    entity: step.capture.entity.state,
                    timestamp: step.capture.timestamp
                )
            )
        }

        return step
    }

    public func successiveStep(
        currentState: State,
        tick: Tick
    ) -> Step {
        let events = upcomingEvents(tick: tick)
        let successiveState = events.reduce(currentState, { $0.applying(event: $1, period: tick.time) })

        self.executionMode = .started(
            Capture(
                entity: successiveState,
                timestamp: tick.time
            )
        )

        let simulationCapture = SimulationCapture(
            entity: (
                state: successiveState,
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
        tick: Tick
    ) -> [Simulation.Event] {
        return preplannedEvents(tick: tick)
    }

    struct Error: Swift.Error, CustomStringConvertible {
        var description: String
    }
}

extension Simulation.State: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.banks == rhs.banks &&
        lhs.ledgers == rhs.ledgers &&
        lhs.centralBank == rhs.centralBank
    }
}

extension Simulation {
    public enum Event: Equatable {
        case createEmptyLedger(ledgerID: String)
        case ledgerEvent(event: Ledger.Event, ledgerID: String)
        case createBank(startingCapital: Decimal, loanRateSpread: Int, bankLedgerID: String)
        case bankEvent(event: Bank.Event, bankLedgerID: String)
        case centralBankEvent(event: CentralBank.Event)

        public var id: String {
            switch self {
            case .createEmptyLedger(ledgerID: let ledgerID):
                return ledgerID
            case .ledgerEvent(event: let event, ledgerID: let ledgerID):
                switch event {
                case .createAsset(name: let name, accountID: let accountID):
                    return accountID
                case .createLiability(name: let name, accountID: let accountID):
                    return accountID
                case .createEquity(name: let name, accountID: let accountID):
                    return accountID
                case .createRevenue(name: let name, accountID: let accountID):
                    return accountID
                case .createExpense(name: let name, accountID: let accountID):
                    return accountID
                case .postAsset(transaction: let transaction, accountID: let accountID):
                    return transaction.id
                case .postLiability(transaction: let transaction, accountID: let accountID):
                    return transaction.id
                case .postEquity(transaction: let transaction, accountID: let accountID):
                    return transaction.id
                case .postRevenue(transaction: let transaction, accountID: let accountID):
                    return transaction.id
                case .postExpense(transaction: let transaction, accountID: let accountID):
                    return transaction.id
                }
            case .createBank(startingCapital: let startingCapital, loanRateSpread: let loanRateSpread, bankLedgerID: let bankLedgerID):
                return bankLedgerID
            case .bankEvent(event: let event, bankLedgerID: let bankLedgerID):
                return bankLedgerID
            case .centralBankEvent(event: let event):
                return event.id
            }
        }
    }
}

extension Simulation {
    public static func make(from model: Model) -> Simulation {
        let simulation = Simulation(
            model: model
        )

        return simulation
    }
}

typealias SimulationCapture = Capture<(state: Simulation.State, events: [Simulation.Event])>

public struct Step {
    var capture: SimulationCapture
    var totalPeriods: UInt32

    public var currentPeriod: UInt32 {
        capture.timestamp
    }
    public var isFinal: Bool {
        return currentPeriod == totalPeriods
    }
}
