//
//  Clock.swift
//  
//

import Foundation

class Clock {
    static let startingTime: UInt32 = 1

    var time: UInt32 = Clock.startingTime

    func next() -> Tick {
        defer {
            time = time + 1
        }
        return Tick(tickDuration: 1, time: time)
    }

    func current() -> Tick {
        return Tick(tickDuration: 1, time: time)
    }

    func reset() {
        time = Self.startingTime
    }
}
