const DataTableHelpers = {}

// Helpers - Phoenix LiveView

DataTableHelpers.live_view_hooks = {
  mounted() { global.vendorInitializers.dataTable() },
  updated() { global.vendorInitializers.dataTable() }
}

// Exports

export default DataTableHelpers
