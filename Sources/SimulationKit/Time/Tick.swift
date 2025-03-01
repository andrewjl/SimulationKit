//
//  Tick.swift
//  
//

import Foundation

struct Tick {
    let tickDuration: UInt32
    let time: UInt32

    func tick() -> Tick {
        let next = time + tickDuration
        return Tick(tickDuration: tickDuration, time: next)
    }
}

extension Tick {
    static func standard(time: UInt32 = 0) -> Self {
        return Tick(tickDuration: 1, time: time)
    }
}

extension Tick {
    func timestampedPoint<Quantity>(amount: Quantity) -> Point<Quantity> {
        return Point(amount: amount, timestamp: time)
    }
}

struct Point<Quantity> {
    let amount: Quantity
    let timestamp: UInt32
}

extension Point {
    init(
        amount: Quantity,
        tick: Tick
    ) {
        self.amount = amount
        self.timestamp = tick.time
    }
}

extension Decimal {
    func computeAdjustment(percentage: UInt) -> Self {
        let decimalized = Decimal(percentage)/Decimal(100)
        return (Decimal(1) + decimalized) * self
    }

    func decimalizedAdjustment(percentage: UInt) -> Self {
        return (Decimal(percentage)/Decimal(100))*self
    }
}

struct TimeSeries<Quantity> {
    var points: [Point<Quantity>] = []

    func tick(
        amount: Quantity,
        tick: Tick
    ) -> Self {
        let point = Point(amount: amount, tick: tick)
        return TimeSeries(
            points: points + [point]
        )
    }

    func quantity(at timetamp: UInt32) -> Quantity? {
        return points.first(where: { $0.timestamp == timetamp })?.amount
    }
}

