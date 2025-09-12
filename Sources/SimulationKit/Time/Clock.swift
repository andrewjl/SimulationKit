//
//  Clock.swift
//  
//

import Foundation

public class Clock {
    public static let startingTime: UInt32 = 0

    public var time: UInt32 = Clock.startingTime

    public init(
        time: UInt32 = Clock.startingTime
    ) {
        self.time = time
    }

    public func next() -> Tick {
        defer {
            time = time + 1
        }
        return Tick(tickDuration: 1, time: time)
    }

    public func current() -> Tick {
        return Tick(tickDuration: 1, time: time)
    }

    public func reset() {
        time = Self.startingTime
    }
}
