# SimulationKit

A package for simulating economic models

# Architecture

Simulations are modeled using discrete events. Each entity has a corresponding set of events.

### Generic Simulation Entities

- Conceptual Model: specifies entities and events
- Simulation: calculates results of a simulation run
- StateGenerator: creates initial state and initial set of events based on plan in conceptual model 
- Run: results from a particular simulation calculation
- Simulator: constructs executable model, executes model logic, collects and collates results
- Period: single iteration of the simulators execution of the executable model
- Clock: source of truth for the current period of the currently executing simulation
- Tick: timestamped value of what the current time is
- Step: single iteration of a simulation
- Simulation.State : The state of the simulation at some step 
- Simulation.Event: A single event recorded at a particular time period

### Domain Specific Entities

- Ledger: consists of one or more accounts and corresponds to an economic entity
- Ledger event: a change in one or more accounts in the ledger
- Bank: an entity that can take deposits and make loans
- Bank event: a change in the bank state
- Accounts
    - Asset: something that has economic value now or in the future
    - Liability: an obligation associated with an economic cost now or in the future
    - Equity: residual value
    - Income: money received through work or investments
    - Expense: money paid out to satisfy an obligation or in exchange for something of value

### General Workflows

Simulation Lifecycle
1. Construct Conceptual Model 
2. Convert Conceptual Model into Executable Model
3. Generate a Run using Executable Model

2 is a function: ConceptualModel -> ExecutableModel
3 is a function: ExecutableModel -> Run

- A simulation is run over a fixed number of time periods. Each time period is represented by a tick on a simulator Clock.
- Each run gets its own separate clock.
- A clock is used to timestamp a point that goes onto a time series.
- The collected time series are specified by an operational historian

### TODOs
- [ ] Consistency between `Simulation` events and `Bank`/`Ledger` events
- [ ] Allow stochastic simulation results
- [ ] Make `Simulation` construction more generic
    - [ ] Generic entities and events
    - [ ] Entity identity
- [ ] Record simulation statistics
- [x] Add `CentralBank` to set policy risk-free rate
- [x] Compute bank loan interest with spread against risk-free rate
- [ ] Add `Company` economic agent
- [ ] Add `Household` economic agent
- [ ] Add utility calculations
- [ ] Add intertemporal decision-making
