const AmChartHelpers = {}

// Helpers - Instances

AmChartHelpers.instances = {}

AmChartHelpers.get_instance = function (id) {
  return AmChartHelpers.instances[id]
}

AmChartHelpers.register_instance = function (id, instance) {
  AmChartHelpers.instances[id] = instance
}

// Helpers - Phoenix LiveView

AmChartHelpers.live_view_hooks = {
  mounted() {
    var id = this.el.attributes["chart-id"].value
    var instance = AmChartHelpers.get_instance(id)

    // instance.chart.validateData()
  },
  updated() {
    var id = this.el.attributes["chart-id"].value
    var instance = AmChartHelpers.get_instance(id)
    var data = JSON.parse(this.el.attributes["chart-data"].value)

    instance.data.data = data

    instance.chart.validateData()
  }
}

// Global Assignments

global.AmChartHelpers = AmChartHelpers

// Exports

export default AmChartHelpers
