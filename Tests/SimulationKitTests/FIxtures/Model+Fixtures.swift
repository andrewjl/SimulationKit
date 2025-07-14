//
//  Model+Fixtures.swift
//  
//

import Foundation
@testable import SimulationKit

extension Model {
    static func makeModel(
        plannedEvents: [Capture<Simulation.Event>] = []
    ) -> Model {
        return Model(
            plannedEvents: plannedEvents
        )
    }
}
