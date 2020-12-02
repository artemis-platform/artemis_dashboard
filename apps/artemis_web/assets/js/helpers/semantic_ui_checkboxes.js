const SemanticUICheckboxHelpers = {}

// Helpers - Phoenix LiveView

SemanticUICheckboxHelpers.live_view_hooks = {
  mounted() { global.vendorInitializers.semanticUICheckboxes() },
  updated() { global.vendorInitializers.semanticUICheckboxes() }
}

// Exports

export default SemanticUICheckboxHelpers
