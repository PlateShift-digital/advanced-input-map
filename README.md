# Advanced Input Map (AIM)

This addon aims to enhance the input map by adding input-groups and cascaded resolution of input.

## Thoughts behind

When mapping keys in the regular input map, all matching bindings will be executed. This results in actions being 
triggered that should not be triggered.

By default, triggering an event with `ctrl+shift+A` will trigger all actions bound to `ctrl+shift+A`, `ctrl+A`, 
`shift+A` and `A`. This is not the behaviour I needed in my projects.

## Features

- replace `Input Map`-tab in project settings window
- group input mappings and enable/disable groups on the fly
- cascading key-binds
  - pressing `A` will trigger actions bound to `A`
  - pressing `shift+A` will trigger actions bound to `shift+A` (ignoring actions listening to `A`)
  - if no actions are found for `shift+A`, AIM will trigger actions bound to `A` instead

## Additional notes

- even though it delivers a new service inside the runtime (`AdvancedInput`) you will still use
`Input.is_action_pressed` etc.
- auto-complete for functions like `is_action_pressed` will still autocomplete for actions defined within the advanced
input map

## Installation

- clone this repository and copy the `addons/advanced_input_map` directory to your project
- go to `Project -> Project Settings... -> Plugins` and enable `Advanced Input Map`
- when the `Input Map`-tab in that window is replaced with the `Advanced Input Map`-tab, you are done

## Usage

TBD
