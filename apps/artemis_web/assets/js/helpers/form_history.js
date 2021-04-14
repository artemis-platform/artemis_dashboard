const FormHistoryHelpers = {}

// Helpers - Phoenix LiveView

FormHistoryHelpers.live_view_hooks = {
  mounted() { global.vendorInitializers.formHistory() },
  updated() { global.vendorInitializers.formHistory() }
}

// Exports

export default FormHistoryHelpers
