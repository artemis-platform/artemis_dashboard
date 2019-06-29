import LiveSocket from "phoenix_live_view"

// Polyfills for Phoenix LiveView
import "mdn-polyfills/NodeList.prototype.forEach"
import "mdn-polyfills/Element.prototype.closest"
import "mdn-polyfills/Element.prototype.matches"
import "child-replace-with-polyfill"
import "url-search-params-polyfill"
import "formdata-polyfill"

const liveSocket = new LiveSocket("/live")

liveSocket.connect()

export default liveSocket
