//
//  Simulator.swift
//  
//

import Foundation

class Simulator {
    var historian: Historian

    init(historian: Historian) {
        self.historian = historian
    }

    init() {
        self.historian = Historian()
    }

    @discardableResult func execute(
        model: Model,
        runsCount: UInt = 1
    ) -> [Run] {
        var runs: [Run] = []

        for _ in 1...runsCount {
            let run = self.run(model: model)
            runs.append(run)
        }

        return runs
    }

    private func run(
        model: Model
    ) -> Run {
        let execModel = Simulation.make(from: model)
        let clock = Clock()

        var steps: [Step] = []

        let tick = clock.next()

        historian.prepare(
            simulation: execModel,
            startingTick: tick
        )

        for _ in 0..<model.duration {
            let step = execModel.tick(clock.next())
            steps.append(step)
            historian.process(step: step)
        }

        let handle = historian.records.last?.id ?? 0

        let run = Run(
            finalState: execModel.state,
            totalPeriods: model.duration,
            handle: handle
        )

        return run
    }
}

struct Run {
    var finalState: Simulation.State
    var totalPeriods: UInt32
    var handle: UInt
}
