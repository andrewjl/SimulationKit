//
//  Historian.swift
//  
//

import Foundation

extension Asset {
    static func balanceTimeSeriesKey(id: UInt) -> String {
        return "A-Balance-\(id)"
    }

    static func rateTimeSeriesKey(id: UInt) -> String {
        return "A-Rate-\(id)"
    }

    func balanceTimeSeriesKey() -> String {
        Self.balanceTimeSeriesKey(id: id)
    }

    func rateTimeSeriesKey() -> String {
        Self.rateTimeSeriesKey(id: id)
    }
}

extension Liability {
    static func balanceTimeSeriesKey(id: UInt) -> String {
        return "L-Balance-\(id)"
    }

    static func rateTimeSeriesKey(id: UInt) -> String {
        return "L-Rate-\(id)"
    }

    func balanceTimeSeriesKey() -> String {
        Self.balanceTimeSeriesKey(id: id)
    }

    func rateTimeSeriesKey() -> String {
        Self.rateTimeSeriesKey(id: id)
    }
}

extension Asset.Transaction {
    func tag(id: UInt) -> String {
        switch self {
        case .credit:
            return "AssetCredit-\(id)"
        case .debit:
            return "AssetDebit=\(id)"
        }
    }
}

extension Liability.Transaction {
    func tag(id: UInt) -> String {
        switch self {
        case .credit:
            return "LiabilityCredit-\(id)"
        case .debit:
            return "LiabilityDebit-\(id)"
        }
    }
}

extension Ledger.Event {
    func tag() -> String {
        switch self {
        case .asset(transaction: let transaction, id: let id, ledgerID: let ledgerID):
            return "Ledger-\(ledgerID)-" + transaction.tag(id: id)
        case .liability(transaction: let transaction, id: let id, ledgerID: let ledgerID):
            return "Ledger-\(ledgerID)-" + transaction.tag(id: id)
        }
    }
}

enum TimeSeriesContainer {
    case unsignedInteger(series: TimeSeries<UInt>)
    case decimal(series: TimeSeries<Decimal>)

    var decimalSeries: TimeSeries<Decimal>? {
        switch self {
        case .decimal(series: let decimalSeries):
            return decimalSeries
        default:
            return nil
        }
    }

    var unsignedIntegerSeries: TimeSeries<UInt>? {
        switch self {
        case .unsignedInteger(series: let unsignedIntegerSeries):
            return unsignedIntegerSeries
        default:
            return nil
        }
    }

    func innerSeries<T>() -> TimeSeries<T>? {
        if T.self == Decimal.self {
            return decimalSeries as? TimeSeries<T>
        }

        if T.self == UInt.self {
            return unsignedIntegerSeries as? TimeSeries<T>
        }

        return nil
    }
}

struct Record {
    var id: UInt
    var period: UInt32
    var startingLedgers: [Ledger]
    var events: [Capture<[[Ledger.Event]]>]
}

struct Measurement {
    var quantity: Quantity
    var timestamp: UInt32

    init(decimal: Decimal, timestamp: UInt32) {
        self.quantity = .decimal(underlying: decimal)
        self.timestamp = timestamp
    }

    enum Quantity {
        case decimal(underlying: Decimal)
    }
}

class Historian {
    var captures: [Capture<(ledgers: [Ledger], events: [[Ledger.Event]])>] = []
    var records: [Record] = []

    func process(
        step: Step
    ) {
        captures.append(
            Capture(entity: (ledgers: step.ledgers, events: step.events), timestamp: step.currentPeriod)
        )

        if step.currentPeriod == step.totalPeriods {
            let startingCapture = captures.first ?? Capture(entity: (ledgers: step.ledgers, events: step.events), timestamp: step.currentPeriod)
            let allEvents = captures.map { Capture(entity: $0.entity.events, timestamp: $0.timestamp) }

            let record = Record(
                id: UInt(records.count),
                period: step.currentPeriod,
                startingLedgers: startingCapture.entity.ledgers,
                events: allEvents
            )
            records.append(record)
            reset()
        }
    }

    func reset() {
        captures.removeAll()
    }

    func record(for handle: UInt) -> Record? {
        return records.first(where: { $0.id == handle })
    }

//    func timeSeries(for tag: String, handle: UInt) -> TimeSeriesContainer? {
//        guard let record = record(for: handle) else {
//            return nil
//        }
//
//        return record.allTimeSeries[tag]
//    }
//
//    func allTags(for handle: UInt) -> [String] {
//        guard let record = record(for: handle) else {
//            return []
//        }
//
//        return Array<String>(record.allTimeSeries.keys)
//    }

    func reconstructedLedgers(
        at period: UInt32,
        for handle: UInt
    ) -> [Ledger]? {
        guard let record = record(for: handle) else {
            return nil
        }

        var ledgers = record.startingLedgers

        if period == Clock.startingTime {
            return ledgers
        }

        let relevantEvents = record.events.filter {
            $0.timestamp <= period
        }

        for eventsCapture in relevantEvents {
            let enumerated = ledgers.enumerated()
            ledgers = enumerated.map { $0.element.tick(events: eventsCapture.entity[$0.offset]) }
        }

        return ledgers
    }
}
