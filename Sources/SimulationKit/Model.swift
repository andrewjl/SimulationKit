//
//  Model.swift
//  
//

import Foundation

public class ConceptualModel {
    public var duration: UInt32 = 7
    public var plannedEvents: [Capture<Simulation.Event>]

    public init(
        duration: UInt32,
        plannedEvents: [Capture<Simulation.Event>] = []
    ) {
        self.duration = duration
        self.plannedEvents = plannedEvents
    }

    public func initialEvents() -> [Simulation.Event] {
        events(at: Clock.startingTime)
    }

    public func events(at time: UInt32) -> [Simulation.Event] {
        return plannedEvents
            .filter({ $0.timestamp == time })
            .map { $0.entity }
    }
}

public typealias Model = ConceptualModel

