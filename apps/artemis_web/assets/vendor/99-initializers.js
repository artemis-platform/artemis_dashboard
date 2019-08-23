// Helpers

function getQueryParams() {
  var currentQueryString = window.location.search.substring(1)
  var currentParams = qs.parse(currentQueryString) || {}

  return currentParams
}

function updateQueryParams(newParams) {
  var currentParams = getQueryParams()
  var encodingOptions = { arrayFormat: 'brackets', encodeValuesOnly: true }
  var nextParams = $.merge(newParams, currentParams)
  var nextQueryString = qs.stringify(nextParams, encodingOptions)

  window.location = window.location.pathname + '?' + nextQueryString
}

// Initializers

function initializeColumnField() {
  $('select.data-table-columns').on('change', function(event) {
    var selected = $(this).select2('data')
    var columns = []

    selected.forEach(function(element) {
      columns.push(element.id)
    })

    updateQueryParams({columns: columns})
  })
}

function initializeDropdowns() {
  $('.ui.dropdown.click').dropdown({on: 'click'})
  $('.ui.dropdown.hover').dropdown({on: 'hover'})
}

function initializeFilterFields() {
  $('.filter-form .filter-multi-select').on('change', function(event) {
    var nextParams = getQueryParams()
    var field = ($(this).attr('name') || '').replace('[]', '')
    var selected = $(this).select2('data')
    var encodingOptions = { arrayFormat: 'brackets', encodeValuesOnly: true }
    var values = []

    selected.forEach(function(element) {
      values.push(element.id)
    })

    nextParams.filters = nextParams.filters || {}
    nextParams.filters[field] = values

    updateQueryParams(nextParams)
  })
}

function initializeHighlightJs() {
  hljs.initHighlightingOnLoad()
}

function reinitializeHighlightJs() {
  hljs.initHighlighting.called = false
  hljs.initHighlighting()
}

function initializeMarkdownTextarea() {
  $('textarea.markdown').each(function() {
    var easyMDE = new EasyMDE({
      element: this,
      spellChecker: false,
      showIcons: ['strikethrough', 'code', 'table', 'redo', 'heading', 'undo', 'heading-1', 'heading-2', 'heading-3', 'heading-4', 'heading-5', 'clean-block', 'horizontal-rule'],
      status: false
    });
  })
}

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

    // Options
    var hasCreate = classes.includes('creatable') || classes.includes('tags')
    var hasSearch = classes.includes('search')

    options.minimumResultsForSearch = hasSearch ? 0 : Infinity
    options.tags = hasCreate
    options.placeholder = item.attr('placeholder') || ''

    // Initialize
    item.select2(options)
  })
}

function initializeSearchSubmit() {
  // Semantic UI supports inline icons for inputs. For search forms, make the
  // inline search icon double as a submit button.
  $('form.ui').each(function() {
    var form = $(this)
    var containers = form.find('.ui.icon.input')

    containers.each(function() {
      var container = $(this)
      var icon = container.find('i.search')

      icon.click(function(event) {
        form.submit()
      })
    })
  })
}

function initializeSidebars() {
  $('.open-sidebar-current-user').click(function(event) {
    if (event) {
      event.preventDefault()
    }

    $('#sidebar-current-user')
      .sidebar('setting', 'dimPage', false)
      .sidebar('setting', 'transition', 'overlay')
      .sidebar('toggle')
  })

  $('.close-sidebar-current-user').click(function(event) {
    if (event) {
      event.preventDefault()
    }

    $('#sidebar-current-user').sidebar('hide')
  })

  $('.open-sidebar-primary-navigation').click(function(event) {
    if (event) {
      event.preventDefault()
    }

    $('#sidebar-primary-navigation')
      .sidebar('setting', 'dimPage', false)
      .sidebar('setting', 'transition', 'overlay')
      .sidebar('toggle')
  })

  $('.close-sidebar-primary-navigation').click(function(event) {
    if (event) {
      event.preventDefault()
    }

    $('#sidebar-primary-navigation').sidebar('hide')
  })
}

function initializeTagForm() {
  $('.resource-tags .show-list-tags').click(function(event) {
    event.preventDefault()
    $('.resource-tags>div').hide()
    $('.resource-tags .list').show()
  })

  $('.resource-tags .show-edit-tags').click(function(event) {
    event.preventDefault()
    $('.resource-tags>div').hide()
    $('.resource-tags .form').show()
  })
}

function initializeWikiSidenav() {
  var links = []
  var offsets = []
  var sidenav = $('.sidenav')
  var headings = $('#wiki-page h1, #wiki-page h2, #wiki-page h3, #wiki-page h4, #wiki-page h5')

  headings.each(function(i) {
    var label = $(this).html()
    var tag = 'tag-' + this.nodeName
    var offset = $(this).offset().top
    var link = $('<li class="' + tag + '"><a href="#sidebar-link">' + label + '</a></li>')

    link.click(function(event) {
      event.preventDefault()

      $([document.documentElement, document.body]).animate({
        scrollTop: offset - 14
      }, 200);
    })

    links.push(link)
    offsets.push(offset)
  })

  var nav = links.length > 0 ? $('<ul></ul>').append(links) : null

  $('#wiki-page aside nav.page-sections').append(nav)

	$('#wiki-page .ui.sticky').sticky({
	  offset: 28,
	  bottomOffset: 0,
    context: '#wiki-page'
  })

  var highlightCurrent
  var highlightReadAheadBuffer = 16
  var highlightSections = $('#wiki-page aside nav.page-sections ul li')

  var updateHighlight = function () { 
    var windowPosition = window.pageYOffset + highlightReadAheadBuffer
    var windowIsAtBottom = (window.innerHeight + window.pageYOffset) >= document.body.scrollHeight
    var highlightNext = 0

    if (windowIsAtBottom) {
      highlightNext = offsets.length - 1
    } else {
      for (var i = 0; i < offsets.length; i++) {
        var isBefore = windowPosition <= offsets[i]

        if (isBefore) {
          break
        }

        highlightNext = i
      }
    }

    if (highlightCurrent !== highlightNext) {
      $(highlightSections).removeClass('highlight')
      $(highlightSections[highlightNext]).addClass('highlight')
    }
  }

  $(window).scroll(function() {
    updateHighlight()
  })

  updateHighlight()
}

$(document).ready(function() {
  initializeColumnField()
  initializeDropdowns()
  initializeFilterFields()
  initializeHighlightJs()
  initializeMarkdownTextarea()
  initializeSelect2()
  initializeSidebars()
  initializeSearchSubmit()
  initializeTagForm()
  initializeWikiSidenav()

  // Reinitialize after LiveView Updates

  $(document).on("phx:update", function () {
    reinitializeHighlightJs()
    // initializeDropdowns()
  })
})
