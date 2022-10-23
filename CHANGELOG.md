# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2022-10-23

### Fixed

* Mix file module name referenced `Statechart`, the library that `MPTree` was extracted from.

## [0.1.0] - 2022-10-21

### Added

* `MPTree.from_node/1`
* `MPTree.insert/3`
* `MPTree.insert!/3`
* `MPTree.update_nodes/2`
* `MPTree.update_nodes/3`
* `MPTree.fetch_children/2`
* `MPTree.fetch_children!/2`
* `MPTree.fetch_descendents/2`
* `MPTree.fetch_descendents!/2`
* `MPTree.fetch_parent/2`
* `MPTree.fetch_parent!/2`
* `MPTree.nodes/1`

[0.1.1]: https://github.com/jonathanchukinas/modified_preorder_tree/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/jonathanchukinas/modified_preorder_tree/releases/tag/v0.1.0
