//
//  Model+Fixtures.swift
//  
//

import Foundation
@testable import SimulationKit

extension Model {
    static func makeModel(
        duration: UInt32,
        plannedEvents: [Capture<Simulation.Event>] = []
    ) -> Model {
        return Model(
            duration: duration,
            plannedEvents: plannedEvents
        )
    }
}
