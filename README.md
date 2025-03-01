# SimulationKit

A package for simulating economic models

## WIP

This package is **WIP**

# Package Design Document

## Conceptual Design

### General Objects

Conceptual Model: Specification of entities and events

Executable Model: A representation of the model used to calculate results of a simulation run

Run: Results from a particular simulation calculation

Simulator: Calculation engine for a given model over a given time period. Constructs an executable model representation from a conceptual representation and then perform a simulation run which then gets output.

Period: Single iteration of the simulators execution of the executable model

Clock: Source of truth for the current period of the currently executing simulation

Tick: Timestamped value of what the current time is

Point: Timestamped value of a temporal variable

Time Series: Chronologically ordered grouping of successive points of a particular value

### General Workflows

Simulation Lifecycle
1. Construct Conceptual Model 
2. Convert Conceptual Model into Executable Model
3. Generate a Run using Executable Model

2 is a function: ConceptualModel -> ExecutableModel
3 is a function: ExecutableModel -> Run

A simulation is run over a fixed number of time periods. Each time period is represented by a tick on a simulator Clock.

Each run gets its own separate clock.

A clock is used to timestamp a point that goes onto a time series.

The collected time series are specified by an operational historian

Model -> Simulation

Simulation -> Run

### Domain Objects

Simulation: Logical and mathematical representation of entities and operations

Asset: A financial instrument whose balance increases over time at a fixed rate

Liability: A financial instrument whose balance increases over time at a fixed rate

Ledger: A grouping of any number of assets and liabilities that are related

Balance: A timestamped quantity that indicates the monetary value of an asset or liability

### Domain Workflows

N/A

### Current Questions

Does the executable representation get modified?

Concepts that are TBD:
- Operational historian: collects time series data
- Currentness: Temporal relation among points in a time series

Example: time based ledger model

Model specifies
- Starting balances for assets and liabilities
- Rate of return

Simulation
- Calculates the asset and liability balances for each period, records results in a run

Run records:
- Balance of each asset and liability over the simulation run
