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
        let simulation = Simulation.make(from: model)
        let clock = Clock()

        var steps: [Step] = []

        let tick = clock.next()

        do {
            try historian.prepare(
                simulation: simulation,
                startingTick: tick
            )
        } catch {
            print("Unable to start simulation")
        }

        for _ in 0..<model.duration {
            do {
                let step = try simulation.tick(clock.next())
                steps.append(step)
                historian.process(step: step)
            } catch {
                print("Unable to start simulation")
            }
        }

        let handle = historian.records.last?.id ?? 0

        let finalState = steps[Int(model.duration)-1].capture.entity.state

        let run = Run(
            finalState: finalState,
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
