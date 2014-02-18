class Loader
  @show: ->
    @_instance().show()
  @hide: ->
    @_instance().hide()
  @_instance: ->
    unless @__instance
      @__instance = new Loader()
    @__instance
  constructor: ->
    @loader = $('body > div#lazy-loader')
    if @loader.length == 0
      @loader = $('<div>')
        .attr('id', 'lazy-loader')
        .css(display: 'none')
        .appendTo 'body'
  show: ->
    @loader.fadeIn()
  hide: ->
    @loader.fadeOut()


class Sortable
  constructor: (options = {})->
    return if $('ul.items-list.sortable').length == 0

    url = '' + $('ul.items-list.sortable').first().data('url')

    if url.length == 0
      throw "Element ul.sortable must have data-url."

    if url.indexOf(':id') < 0 || url.indexOf(':target_id') < 0
      throw "Url '#{url}' has to have :id and :target_id placeholders."

    $("ul.items-list.sortable li:not(.header)").draggable appendTo: 'body',
      revert: 'invalid',
      cursor: 'move'
    
    $("ul.items-list.sortable li:not(.header)").droppable hoverClass: 'ui-state-hover',
      greedy: true,
      drop: (event, ui) ->

        object = $(ui.draggable)
        id = object.find('input[type=checkbox]').val()

        target = $(this)
        target_id = target.find('input[type=checkbox]').val()

        action_url = url
          .replace(':id', id)
          .replace(':target_id', target_id)

        Loader.show()

        $.post(action_url, (data) ->
          object.insertAfter(target)
        )
        .fail( (jqXHR, textStatus) ->
          text = if jqXHR.responseJSON?
            jqXHR.responseJSON.join('. ')
          else
            "Network error"

          $('#notice')
            .html(text)
            .show()
          setTimeout ->
            $('#notice').fadeOut(3000);
          , 3000
        )
        .always( ->
          object.css(top: '', left: '')
          Loader.hide()
        )

class LazyAdmin
  constructor: ->
    @_context_menu()
    @_sortable_list()
    @_selection_actions()
    @_custom_select()
    @_custom_file_input()
    @_locales_tabs()
    @_fileupload()

  loader: ->
    Loader

  action_on_selected: (url, options = {}) ->
    console.log("Not used any more")
    return

  close_all_context_menus: (except = null) ->
    $('[data-context-target]:visible')
      .not(except)
      .hide()
      .removeClass('from-mouse')

  open_context_menu_for: (element, x, y) ->
    @close_all_context_menus()
    menu = $(element).find('[data-context-target]')

    scrollTop = $(document).scrollTop()
    menu
      .addClass('from-mouse')
      .css(top: scrollTop + y, left: x)
      .show()

  _context_menu: ->
    $(document).on 'contextmenu', '.group[data-context]', (event) =>
      event.preventDefault()
      return if $(event.target).closest('[data-context-target]').length > 0

      offset = $(event.currentTarget).offset()
      @open_context_menu_for(event.currentTarget, event.clientX - offset.left, event.clientY - offset.top)

    $(document).on 'click', (event) =>
      return if $(event.target).closest('[data-context-target]').length > 0
      return if $(event.target).closest('[data-context-button]').length > 0
      @close_all_context_menus()

    $(document).on 'click', 'a[data-context-button]', (event) =>
      event.preventDefault()

      menu = $(event.currentTarget)
        .siblings('[data-context-target]')
      
      @close_all_context_menus(menu[0])

      menu
        .removeClass('from-mouse')
        .css(top: '', left: '')
        .toggle()
      false

  _selection_actions: ->
    $('form select#selection_action').on 'change', (event) ->
      ids = []
      for obj in $(this.form).serializeArray()
        if obj.name == 'selection[ids][]'
          ids.push obj.value
      if ids.length > 0 and $(this).val().length > 0
        $(this.form).submit()
      else
        $(this).val('')

  _sortable_list: ->
    @_sortable = new Sortable()

  _locales_tabs: ->
    $('.tabs_container').each ->
      if $(this).children('ul').first().children('li').length == 1
        $(this).children('ul').first().hide()
      else
        $(this).tabs()

  _custom_select: ->
    $('select').customSelect();

  _custom_file_input: ->
    $("input[type=file].custom-file-input.fileupload").customFileInput({path: false});
    $("input[type=file].custom-file-input").customFileInput();

  _fileupload: ->
    if Object.prototype.toString.call(window.HTMLElement).indexOf('Constructor') > 0
      $("input[type=file].fileupload").each ->
        $(this).prop('multiple', false)


    $("input[type=file].fileupload").fileupload sequentialUploads: true,
      singleFileUploads: true,
      add: (e, data) ->
        queue = data.fileInput.data('queue');
        
        if queue
          file = data.files[0];

          remove = $('<a>')
            .attr('href', '#')
            .html('&times;')
            .addClass('close')
            .click (event) ->
              event.preventDefault();
              data.jqXHR.abort();

          name = $('<p>').html file.name 

          progress = $('<div>')
            .addClass('progress')
            .progressbar();

          context = data.context = $('<div>')
            .append( remove )
            .append( name )
            .append( progress )
            .addClass('queue-item')
            .appendTo "##{queue}"

        data.submit()
      , progress: (e, data) ->
        
        if data.context
          progress = parseInt(data.loaded / data.total * 100, 10)
          data.context
            .find('.progress')
            .progressbar 'value', progress
      , always: (e, data) ->
        if data.context
          setTimeout( ->
            data.context
              .fadeOut('slow', ->
                $(this).remove()
              )
          , 3000)

jQuery ->
  window.lazy = new LazyAdmin()
