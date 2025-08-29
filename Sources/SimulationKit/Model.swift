//
//  Model.swift
//  
//

import Foundation

class ConceptualModel {
    var duration: UInt32 = 7
    var plannedEvents: [Capture<Simulation.Event>]

    init(
        plannedEvents: [Capture<Simulation.Event>] = []
    ) {
        self.plannedEvents = plannedEvents
    }

    func initialEvents() -> [Simulation.Event] {
        events(at: Clock.startingTime)
    }

    func events(at time: UInt32) -> [Simulation.Event] {
        return plannedEvents
            .filter({ $0.timestamp == time })
            .map { $0.entity }
    }
}

typealias Model = ConceptualModel

