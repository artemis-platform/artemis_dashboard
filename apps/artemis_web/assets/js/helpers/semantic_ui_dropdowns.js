const SemanticUIDropdownHelpers = {}

// Helpers - Phoenix LiveView

SemanticUIDropdownHelpers.live_view_hooks = {
  mounted() { global.vendorInitializers.semanticUIDropdowns() },
  updated() { global.vendorInitializers.semanticUIDropdowns() }
}

// Exports

export default SemanticUIDropdownHelpers
