// Select2
//
// The Select2 library adds enhanced functionality to the default `select` tags.
//
// To use, add the `enhanced` class to any existing `select` tag.
//
// Additional configuration options for Select2 can be configured by adding additional classes.
//
// For example, to add a search bar add the `search` class:
//
//   <%= select f, :example, [1, 2], class: "enhanced search" %> 
// 
function initializeSelect2() {

  $('select.enhanced').each(function() {
    var item = $(this)
    var classes = item.attr('class').split(' ')
    var options = {}

    // Options - Search
    var hasSearch = classes.includes('search')

    options.minimumResultsForSearch = hasSearch ? 0 : Infinity

    // Initialize
    item.select2(options)
  })
}

$(document).ready(function() {
  initializeSelect2()
})
