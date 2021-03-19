const Select2Helpers = {}

// Helpers - Phoenix LiveView

Select2Helpers.live_view_hooks = {
  mounted() { global.vendorInitializers.select2() },
  updated() { global.vendorInitializers.select2() }
}

// Exports

export default Select2Helpers
