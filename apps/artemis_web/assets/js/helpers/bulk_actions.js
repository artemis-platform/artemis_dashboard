const BulkActionHelpers = {}

// Helpers - Phoenix LiveView

BulkActionHelpers.live_view_hooks = {
  mounted() { global.vendorInitializers.bulkActions() },
  updated() { global.vendorInitializers.bulkActions() }
}

// Exports

export default BulkActionHelpers
