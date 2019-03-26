import css from "../css/app.scss"
import hljs from "highlight.js"
import jquery from "jquery"
import "phoenix_html"

global.$ = jquery
global.jQuery = jquery
global.hljs = hljs

hljs.initHighlightingOnLoad()
