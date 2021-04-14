const SemanticUIPopupHelpers = {}

// Helpers - Phoenix LiveView

SemanticUIPopupHelpers.live_view_hooks = {
  mounted() { global.vendorInitializers.semanticUIPopups() },
  updated() { global.vendorInitializers.semanticUIPopups() }
}

// Exports

export default SemanticUIPopupHelpers
