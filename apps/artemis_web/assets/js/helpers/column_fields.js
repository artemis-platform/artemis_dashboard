const ColumnFieldsHelpers = {}

// Helpers - Phoenix LiveView

ColumnFieldsHelpers.live_view_hooks = {
  mounted() { global.vendorInitializers.columnFields() },
  updated() { global.vendorInitializers.columnFields() }
}

// Exports

export default ColumnFieldsHelpers
