# StateChart

This library is a pure-Elixir implementation of statecharts.

See Hariman's (sp?) paper: <insert link here>

## Installation

This package can be installed by adding `state_chart` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:statechart, "~> 0.1.0"}
  ]
end
```

<!--- StateChart moduledoc start -->

## Usage

Statecharts are souped-up finite-state machines (FSMs), so let's take a look at those first.

### Finite State Machine (FSM)

Let's model a switch that toggles from `on` to `off` and back again:

```
defmodule ToggleStatechart do
  use Statechart

  statechart do
    state :on, default: true, do: :TOGGLE >>> :off
    state :off, do: :TOGGLE >>> :on
  end
end
```

The above "machine" starts in the `:off` state.
When it receives a `:TOGGLE` event, it transitions to the `:on` state.
Send it another `:TOGGLE` event, and it transitions back to `:off`.
We can repeat this infinitely many times.

This simple DSL highlights the first advantage of this library over existing statechart / state machine libraries:
a small, clear, powerful DSL.

Here is how we use the machine:

```
alias Statechart.Machine

%Machine{} = machine = Machine.new(ToggleStatechart)

# As expected, it begins in the `:off` state:
:off = Machine.state(machine)

# We can then transition to `:on` by passing a `:TOGGLE` event:
machine = Machine.transition(machine, :TOGGLE)
:on = Machine.state(machine)
```

### Error-checking

The second advantage this library has over its competitors is its robust compile-time checking.
Imagine we try to compile this statechart:

```
defmodule ToggleStatechart do
  use Statechart

  statechart do
    # Whoops! We've misspelled "off":
    state :on, default: true, do: :TOGGLE >>> :of
    state :off, do: :TOGGLE >>> :on
  end
end
```

This module will fail at compile time with this error:

TODO show error

## Conventions

- A module declaring a statechart has "Statechart" in its name, e.g.:
  - `ToggleStatechart`
  - `Toggle.Statechart`

## Glossary

- **node** - a point in the data structure definition.
  Contract with `state`
- **state** - a **machine** is in one **state** at any instant of time.
  Contrast with **node** (which is more of a definition).
- **context** - supplementary state.
  Think of this as a data bucket.
  It is kinda like the assigns on `Plug.Conn`
- **statechart** - the template
- **machine** - (as in, "state machine") a stateful thing patterned off a **statechart** and has **state** and **context**.
- **event** - something you send to a machine that might cause it to move from one **state** to another and also might cause its **context** to change.
- **transition** - defines "When you receive this **event** while in this **state**, move to this other **state**"

<!--- StateChart moduledoc end -->

## Roadmap

Some of these roadmap items are future features.
If they are already partially or fully implemented,
It will
1) be hidden from the docs
2) marked with a `# FutureFeature` comment

- [x] Basic state machine
- [ ] Statechart.on/1 w/ arity-0 actions
- [ ] 1-arity actions
- [ ] Statechart.subchart/2
- [ ] Orthogonal states (TODO: add reference to Harriman paper)
- [ ] Extract library 'mptt (Modified Preorder Tree Traversal)'

## TODOs for 0.1.0 release

### Statechart.machine/1
  - add function
  - add function docs
  - section: 4
  - add type for machine

### Statechart
  - Statechart moduledoc
  - add an image for the basic on/off toggle
  - can the do-block TOGGLE be made inline?
  - look up a good definition for FSM
  - Add the compile-time warning to the above failing `:of` line
  - get link to harriman paper, check spelling of his name
  - add type to a chart and its machine
  - add final state
  - add a note about events being all caps
  - add doctests for Statechart.on/1
  - Statechart.on/1 can accept only ONE kv pair. Must declare multiple "on"s to declare multiple actions
  - Add to docs: all the compile time checks (e.g. 'on exit' when there's no final state)
  - ensure 0-arity actions work
  - add action fn type
  - Make sure all Statechart functions/macros have a one-liner summary
  - remove the "Step 1 ...3" headings

### Glossary
  - node
  - leaf node
  - default

### README (outside of the moduledoc block)
  - Add an explanation of "Why another state machine library?"

### Other
  - remove all other modules from docs
  - Remove "Pages" tab from docs
  - add a "Conventions" section
  - make sure that macros that inject functions or attributes all have standardized names, e.g. `__statechart_<do a thing>__`
  - tool versions (asdf)

## Notes
can I add an elixir formatting to my README code blocks?
add a TERMS section to docs that includes statechart, fsm, state, context
post init release - add options to save transition info
add opaque t type a la LimitedQueue
PR for limited_queue to better link types
rename my gh acct to chukinas
refactor tests into init release features and then by future features

can a Statechart.machine macro be piped into?
