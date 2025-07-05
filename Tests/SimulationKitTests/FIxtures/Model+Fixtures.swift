//
//  Model+Fixtures.swift
//  
//

import Foundation
@testable import SimulationKit

extension Model {
    static func makeModel(plannedEvents: [Capture<Simulation.Event>] = []) -> Model {
        let model =

        Model(
            rate: 5,
            initialAssetBalance: 300,
            initialLiabilityBalance: 100,
            ledgersCount: 1,
            plannedEvents: plannedEvents
        )
        return model
    }
}
