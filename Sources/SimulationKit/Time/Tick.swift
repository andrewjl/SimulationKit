//
//  Tick.swift
//  
//

import Foundation

struct Tick {
    let tickDuration: UInt32
    let time: UInt32
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

