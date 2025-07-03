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
    var captures: [Capture<Quantity>] = []

    func tick(
        quantity: Quantity,
        tick: Tick
    ) -> Self {
        let capture = Capture(entity: quantity, timestamp: tick.time)
        return TimeSeries(
            captures: captures + [capture]
        )
    }

    func quantity(at timetamp: UInt32) -> Quantity? {
        return captures.first(where: { $0.timestamp == timetamp })?.entity
    }
}

