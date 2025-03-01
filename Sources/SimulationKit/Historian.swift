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
        case .asset(transaction: let transaction, id: let id):
            return transaction.tag(id: id)
        case .liability(transaction: let transaction, id: let id):
            return transaction.tag(id: id)
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
    var startingLedger: Ledger
    var events: [Capture<[Ledger.Event]>]
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
    var ledgerPoints: [Capture<Ledger.Points>] = []
    var ledgers: [Capture<Ledger>] = []

    var events: [Capture<[Ledger.Event]>] = []

    var records: [Record] = []

    func process(
        step: Step
    ) {
        let ledger = step.ledger

        let points = ledger.asPoints(tick: Tick(tickDuration: 1, time: step.currentPeriod))
        ledgers.append(
            Capture(entity: ledger, timestamp: step.currentPeriod)
        )
        ledgerPoints.append(
            Capture(entity: points, timestamp: step.currentPeriod)
        )
        events.append(
            Capture(entity: step.events, timestamp: step.currentPeriod)
        )
        if step.currentPeriod == step.totalPeriods {
            let startingLedgerCapture = ledgers.first ?? Capture(entity: step.ledger, timestamp: step.currentPeriod)
            let record = Record(
                id: UInt(records.count),
                period: step.currentPeriod,
                startingLedger: startingLedgerCapture.entity,
                events: events
            )
            records.append(record)
            reset()
        }
    }

    func reset() {
        ledgers.removeAll()
        ledgerPoints.removeAll()
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

    func reconstructedLedger(
        at period: UInt32,
        for handle: UInt
    ) -> Ledger? {
        guard let record = record(for: handle) else {
            return nil
        }

        var ledger = record.startingLedger

        if period == Clock.startingTime {
            return ledger
        }

        let relevantEvents = record.events.filter { $0.timestamp <= period }

        for eventsCapture in relevantEvents {
            ledger = ledger.tick(events: eventsCapture.entity)
        }

        return ledger
    }
}
