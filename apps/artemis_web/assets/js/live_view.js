import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"
import AmChartHelpers from "./am_charts"
import ApexChartHelpers from "./apex_charts"

// LiveView Browser Polyfills

import "mdn-polyfills/NodeList.prototype.forEach"
import "mdn-polyfills/Element.prototype.closest"
import "mdn-polyfills/Element.prototype.matches"
import "child-replace-with-polyfill"
import "url-search-params-polyfill"
import "formdata-polyfill"

// LiveView Configuration

const LiveViewHooks = {}

LiveViewHooks.AmCharts = AmChartHelpers.live_view_hooks
LiveViewHooks.ApexCharts = ApexChartHelpers.live_view_hooks

// LiveView Initialization

const liveSocket = new LiveSocket("/live", Socket, {hooks: LiveViewHooks})

liveSocket.connect()

export default liveSocket
