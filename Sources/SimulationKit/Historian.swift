//
//  Historian.swift
//  
//

import Foundation

extension Asset {
    func balanceTimeSeriesKey() -> String {
        id
    }

    func rateTimeSeriesKey() -> String {
        id
    }
}

extension Liability {
    func balanceTimeSeriesKey() -> String {
        id
    }

    func rateTimeSeriesKey() -> String {
        id
    }
}

extension Ledger.Event {
    func tag() -> String {
        switch self {
        case .asset(transaction: _, accountID: let accountID):
            return accountID
        case .liability(transaction: _, accountID: let accountID):
            return accountID
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
    var startingState: Simulation.State
    var events: [Capture<[Simulation.Event]>]
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
    var captures: [SimulationCapture] = []
    var records: [Record] = []

    func prepare(
        simulation: Simulation,
        startingTick: Tick
    ) {
        process(
            step: simulation.start(
                tick: startingTick
            )
        )
    }

    func process(
        step: Step
    ) {
        captures.append(
            step.capture
        )

        if step.isFinal {
            let startingCapture = captures.first ?? step.capture

            let record = Record(
                id: UInt(records.count),
                period: step.currentPeriod,
                startingState: startingCapture.entity.state,
                events: captures.map { Capture(entity: $0.entity.events, timestamp: $0.timestamp) }
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
    ) -> Simulation.State? {
        guard let record = record(for: handle) else {
            return nil
        }

        var state = record.startingState

        if period == Clock.startingTime {
            return state
        }

        let relevantEvents = record.events.filter {
            $0.timestamp <= period
        }

        for eventsCapture in relevantEvents {
            for event in eventsCapture.entity {
                state = state.apply(event: event)
            }
        }

        return state
    }
}
