$ ->
  #------------path---------------
  path = ""
  [start, contents...] = location.pathname.split("")
  path = contents.join("")
  console.log "path", path

  socket  = io.connect()
  control = io.connect("/control")
  test = io.connect "/test"

  #------------EventEmitter---------------
  UserEvent = ->
    new EventEmitter().apply(this)
    this.name = ""
  event = new UserEvent()
  #event.name = "dataChain"

  #それぞれのオブジェクトがもつpolyline
  hasStartpolylines = {}
  hasEndpolylines  = {}
  connections = [] #形式: [[id, id], [id, id], ...]

  dragFlag = true
  socket.on("connect", ()->
    console.log "connect!"

    socket.emit("path",path)

    #------------err---------------
    contents = $("#err")
    if contents?
      $("<input id='create' type='submit' value='create'>").appendTo(contents).click ->
        socket.emit("CreateMono", path)
        location.reload()

    #------------output---------------
    contents = $("#output")
    if contents?
      socket.on "outputURL", (url)->
        $("#textarea").val(url)
      $("<input id='outputData' type='submit' value='submit'>").appendTo(contents).click ->
        base = path.split "/"
        console.log base[0]
        alert "save output"
        socket.emit "saveOutput", [base[0], [$("#textarea").val(), $("#formData").val()]]

    #------------index---------------
    contents = $("#index")
    if contents?
      console.log "append contents"
      contents.append("<p>Create Mono</p>")
      contents.append("<input id='monoN' type='text'>")
      contents.append("<input id='mono' type='submit' value='create'>")
      $("#mono").click(()->
        socket.emit("CreateMono", $("#monoN").val())
      )

      contents.append("<p>Create Sensor</p>")
      contents.append("<input id='sensorN' type='text'>")
      contents.append("<input id='sensor' type='submit' value='create'>")
      $("#sensor").click(()->
        socket.emit("CreateSensor", $("#sensorN").val())
      )
      contents.append("<p>Add Sensor</p>")
      contents.append("<input id='add' type='submit' value='add'>")
      $("#add").click(()->
        socket.emit("AddSensor", [$("#monoN").val(), $("#sensorN").val()])
      )

    #----------------detail-----------------
    contents = $("#detail")
    if contents?

      socket.on "blocks", (blocks)->
        console.log "blocks"
        for i, n in blocks
          #if $("#{i}").attr("id") is ("targetObj" or "svg") then continue
          tar = ($(i).appendTo $("#field"))
          console.log i
          fixedDraggable tar, true
          createURLRequest tar

        socket.on "restoreConnections", (_connections)->
          connections = _connections
          for i in _connections
            if i[0]? and i[1]?
              array = [$("##{i[0]}"), $("##{i[1]}")]
              console.log array
              createConnection array, true

      #----------------SVG-----------------
      if !$("#svg").length
        $("#field").svg({onLoad: drawIntro})
        drawIntro = (svg)->
          console.log "create svg"
        $("#field").attr(xmlns: "http://www.w3.org/2000/svg")
        $("svg").attr(id: "svg")
        marker = document.createElementNS("http://www.w3.org/2000/svg", "marker")
        marker.setAttribute("id", "mu_us")
        marker.setAttribute("markerUnits", "userSpaceOnUse")
        marker.setAttribute("markerWidth", "30")
        marker.setAttribute("markerHeight", "30")
        marker.setAttribute("viewBox", "0 0 10 10")
        marker.setAttribute("refX", "5")
        marker.setAttribute("refY", "5")
        $("svg").append marker
        polygon = document.createElementNS("http://www.w3.org/2000/svg", "polygon")
        polygon.setAttribute("points", "0,0 5,5 0,10 10,5")
        polygon.setAttribute("fill", "red")
        $("marker").append polygon

      #----------------SVG-----------------
      if $("#targetObj").length
        console.log "exist"
      else
        console.log "not exist"
        $("#field").append "<div id=targetObj></div>" if path isnt ""
        $("#targetObj").append "<div id=dropPosition>output</div>"
        $("#targetObj").append "<div id=output><a href='#{path}/output'>#{path}</a></div>"
        $("#dropPosition").droppable
          accept: ".block"
          drop: (ev, ui)->
            alert("output")
            tar = ui.draggable
            tar.addClass "dropped"
            socket.emit "saveClient", [path, saveClient()]
            createURLRequest(tar)
          out: (ev, ui)->
            tar = ui.draggable
            tar.removeClass "dropped"
            socket.emit "saveClient", [path, saveClient()]

        $("svg").append (createSVGpolyline 550, 145, 600, 145, "outputLine")
        console.log path


      sensor = $("#sensorContents")
      obj = $("#objContents")

      #---------------Menu-----------------
      $("#menu li").hover ->
        $(this).children("ul").show()
      , ->
        $(this).children("ul").hide()

      #--------------ObjContents--------------
      objectsArray = ["Max", "min", "Switch", "Connection", "and", "or"]
      for i, n in objectsArray
        obj.append "<li><a class='obj'>#{i}</a></li>"
        if n is objectsArray.length-1
          $("li .obj").click ->
            if $(this).html() is "Connection"
              array = []
              alert "select two elements"
              $(".ui-draggable").draggable("disable").click ->
                array.push $(this)
                if array.length is 2
                  console.log array
                  createConnection array
                  $(".ui-draggable-disabled").draggable("enable")
            else if $(this).html() is "Switch"
              tar = ($("<div class='obj block' name='#{$(this).html()}' style='left:100px; top:100px'><select name='' id='flip-a' value='on' data-role='slider'><option value='off'>Off</option><option value='on'>On</option></div>").appendTo $("#field"))
            else if ($(this).html() is "Max") or ($(this).html() is "min")
              console.log "max, min", $(this).html()
              tar = ($("<div class='obj block' name='#{$(this).html()}' style='left:100px; top:100px'><input type='text' name='' value='100' class='onlynum'></div>").appendTo $("#field"))
              if $(this).html() is "Max"
                tar.addClass "Max"
              if $(this).html() is "min"
                tar.addClass "min"
            else if ($(this).html() is "and") or ($(this).html() is "or")
              tar = ($("<div class='obj block' name='#{$(this).html()}' style='left:100px; top:100px'>#{$(this).html()}</div>").appendTo $("#field"))
            if $(this).html() isnt "Connection"
              fixedDraggable tar

            $(".onlynum").keyup ->
              if $.isNumeric($(this).val())
                $(this).attr("value":$(this).val())
              else
                $(this).val("")
              $(this).attr("value": $(this).val())
      #--------------SensorContents--------------
      socket.on "sensors", (data)->
        console.log data
        for i, n in data
          sensor.append "<li><a class='sensor'>#{i.name}</a></li>"

          #--------------SensorAction--------------
          if n is data.length-1
            $("li .sensor").click ->
              #tar = ($("<div class='sensor block' style='left: #{$(this)}; top] #{}'>#{$(this).html()}</div>").appendTo $("#field"))
              polyline = null
              tar = ($("<div class='sensor block' name='#{$(this).html()}' style='left:100px; top:100px'>#{$(this).html()}</div>").appendTo $("#field"))
              fixedDraggable tar

    isHover = false
    socket.on "lindaData", (data)->
      selector = $(".sensor[name='#{data[0]}']")
      #event.emit "#{selector.attr("id")}", data
      event.emit "#{selector.attr('id')}", data
      blink selector
      $("#explain").append "<p class='inspector'>#{data[1]}</p>" if isHover
      if $(".inspector").length > 6
        $(".inspector:first").slideUp(->
          this.remove
          console.log this
        )
      selector.hover ->
        isHover = true
      , ->
        isHover = false
        $(".inspector").remove()

    socket.on("disconnect", ()->
      console.log "disconnect"
    )

  #user functions
  blink = (selector)->
    selector.css {backgroundColor:"#CBD6FF"}
    setTimeout ->
      selector.css {backgroundColor:"white"}
    , 500

  revBlink = (selector)->
    selector.css {backgroundColor:"white"}
    setTimeout ->
      selector.css {backgroundColor:"#CBD6FF"}
    , 500

  fixedDraggable = (tar, reload)->
    #uid設定
    uid = ""
    socket.emit "uidRequest"
    socket.on "uidResponse", (_uid)->
      uid = _uid
      if typeof tar.attr("id") is 'undefined'
        console.log "create id"
        tar.attr("id":uid)

    tar.draggable
      create: ->
        console.log "create", $(this).html()
        socket.emit "saveClient", [path, saveClient()] if !reload
        socket.emit "sensorRequest", $(this).html()
      drag: ->
        if hasStartpolylines["#{tar.attr('id')}"]?
          for polyline in hasStartpolylines["#{tar.attr('id')}"]
            if polyline?
              results = []
              points = $(polyline).attr("points").split(" ")
              for point in points
                results.push point.split(",")
              x1 = $(this).offset().left-50
              y1 = $(this).offset().top-100
              mx = (results[2][0]-x1)/2+x1
              my = (results[2][1]-y1)/2+y1
              polylineMove polyline, "x1", x1
              polylineMove polyline, "y1", y1
              polylineMove polyline, "mx", mx
              polylineMove polyline, "my", my
        if hasEndpolylines["#{tar.attr('id')}"]?
          for polyline in hasEndpolylines["#{tar.attr('id')}"]
            if polyline?
              results = []
              points = $(polyline).attr("points").split(" ")
              for point in points
                results.push point.split(",")
              x2 = $(this).offset().left-50
              y2 = $(this).offset().top-100
              x1 = parseFloat results[0][0]
              y1 = parseFloat results[0][1]
              mx = (x2-x1)/2+x1
              my = (y2-y1)/2+y1
              polylineMove polyline, "x2", x2
              polylineMove polyline, "y2", y2
              polylineMove polyline, "mx", mx
              polylineMove polyline, "my", my


      stop: ->
        console.log "drag end", $(this).html()
        socket.emit "saveClient", [path, saveClient()]
      cursor: "pointer"
      connectToSortable: "#dropPosition"
      snap:   true
      grid:   [10, 10]
    tar.dblclick ->
      id = $(this).attr("id")
      console.log "double click"
      removeObj = []
      for i, n in connections
        if i[0] is id or i[1] is id
          removeObj.push n
          polylineId = i[0] + i[1]
          $("##{polylineId}").remove()
      for i, n in removeObj
        connections.splice i, 1
        socket.emit "saveConnections", [path, connections] if n is removeObj.length-1
      $(this).remove()
      socket.emit "saveClient", [path, saveClient()] if reload
    if dragFlag
      tar.draggable("enable")
    else
      tar.draggable("disable")

  createSVGpolyline = (x1, y1, x2, y2, id)->
    polyline = document.createElementNS("http://www.w3.org/2000/svg", "polyline")
    mx = (x2-x1)/2+x1
    my = (y2-y1)/2+y1

    polyline.setAttribute("points", "#{x1},#{y1} #{mx},#{my} #{x2},#{y2}")
    polyline.setAttribute("class", "svgpolyline")
    polyline.setAttribute("stroke", "black")
    polyline.setAttribute("stroke-width", "6")
    polyline.setAttribute("marker-mid", "url(#mu_us)")
    polyline.setAttribute("id", id)
    console.log "create polyline"
    $(polyline).dblclick ->
      removeObj = null
      for i, n in connections
        if $(this).attr("id") is i[0]+i[1]
          removeObj = n
          $(this).remove()
      connections.splice removeObj, 1
      socket.emit "saveConnections", [path, connections]
    polyline

  polylineMove = (polyline, name, num)->
    results = []
    res = []
    points = $(polyline).attr("points").split(" ")
    for point in points
      results.push point.split(",")
    switch name
      when "x1"
        results[0][0] = "#{num}"
      when "y1"
        results[0][1] = "#{num}"
      when "mx"
        results[1][0] = "#{num}"
      when "my"
        results[1][1] = "#{num}"
      when "x2"
        results[2][0] = "#{num}"
      when "y2"
        results[2][1] = "#{num}"
    for i in results
      res.push i.join(",")
    polyline.setAttribute("points", "#{res.join(" ")}")

  createConnection = (array, reload)->
    obj = array[0]
    tar = array[1]
    if obj is tar
      alert "select other object"
      return
    if !reload
      for i in connections
        if (i[0] == obj.attr('id') and i[1] == tar.attr('id')) or (i[1] == obj.attr('id') and i[2] == tar.attr('id'))
          alert "this connection already exist"
          return
    marginLeft = 50
    marginTop  = 100
    id = obj.attr("id") + tar.attr("id")
    polyline = createSVGpolyline obj.offset().left-marginLeft, obj.offset().top-marginTop, tar.offset().left-marginLeft, tar.offset().top-marginTop, id
    $("svg").append polyline
    if hasStartpolylines["#{obj.attr('id')}"]?
      hasStartpolylines["#{obj.attr('id')}"].push polyline
    else
      hasStartpolylines["#{obj.attr('id')}"] = []
      hasStartpolylines["#{obj.attr('id')}"].push polyline
    if hasEndpolylines["#{tar.attr('id')}"]?
      hasEndpolylines["#{tar.attr('id')}"].push polyline
    else
      hasEndpolylines["#{tar.attr('id')}"] = []
      hasEndpolylines["#{tar.attr('id')}"].push polyline
    connections.push ["#{obj.attr('id')}", "#{tar.attr('id')}"] if !reload
    socket.emit "saveConnections", [path, connections]
    console.log "saved", connections
    createUserEvent ["#{obj.attr('id')}", "#{tar.attr('id')}"]
    polyline

  saveClient = ->
    if $("#field").html()?
      children = $("#field").html().replace(/<\/div>/g, "</div>区切り").replace(/<\/svg>/g, "</svg>区切り").split("区切り")
    else
      return []
    contents = []
    for i in children
      if $(i).hasClass("block")
        contents.push i
    console.log "saved: ", contents
    contents

  #----------------Event control-----------------
  #connectionsを全部みる
  createUserEvent = (connection)->
    event.on "#{connection[0]}", (data)->
      tar = $("##{connection[1]}")
      switch $("##{connection[1]}").attr("name")
        when "Switch"
          console.log "create Swicth event"
          switchSelector = tar.children("select[name=select]")
          if switchSelector.val() is "on"
            blink tar
            event.emit ("#{connection[1]}"), data
          else
            revBlink tar
            setInterval ->
              event.emit ("#{connection[1]}"), false if !data?
            ,1000

        when "Max"
          console.log "create Max event"
          if $.isNumeric(data[1]) and (parseFloat(data[1]) <= parseFloat(tar.children("input").val()))
            blink tar
            event.emit ("#{connection[1]}"), data
        when "min"
          console.log "create min event"
          if $.isNumeric(data[1]) and (parseFloat(data[1]) >= parseFloat(tar.children("input").val()))
            blink tar
            event.emit ("#{connection[1]}"), data
        when "and"
          console.log "create and event"
          flag = 0
          for connection, n in connections
            event.on connection[0], (data)->
              flag++
            if n is connections.length-1
              if flag is n-1
                event.emit ("#{connection[1]}"), true

        when "or"
          console.log "create or event"
          blink tar
          event.emit ("#{connection[1]}"), data
  )
  #output
  createURLRequest = (tar)->
    if $(".dropped").length
      event.on tar.attr("id"), (data)->
        if tar.hasClass("dropped") and $(".dropped").length
          console.log "url request"
          socket.emit "urlRequest", path
