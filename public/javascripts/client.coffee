$ ->
  #------------path---------------
  path = ""
  [start, contents...] = location.pathname.split("")
  path = contents.join("")
  console.log "path", path

  socket  = io.connect()
  control = io.connect("/control")
  test = io.connect "/test"

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
        for i in blocks
          if $("#{i}").attr("id") is ("targetObj" or "svg") then continue
          tar = ($(i).appendTo $("#field"))
          fixedDraggable tar

      #----------------SVG-----------------
      if !$("#svg").length
        $("#field").svg({onLoad: drawIntro})
        drawIntro = (svg)->
          console.log "create svg"
        $("#field").attr(xmlns: "http://www.w3.org/2000/svg")
        $("svg").attr(id: "svg")
        
        #ここまでテンプレ
      #----------------SVG-----------------
      if $("#targetObj").length
        console.log "exist"
      else
        console.log "not exist"
        $("#field").append "<div id=targetObj>#{path}</div>" if path isnt ""
        console.log path


      sensor = $("#sensorContents")
      obj = $("#objContents")
      
      #---------------Menu-----------------
      $("#menu li").hover ->
        $(this).children("ul").show()
      , ->
        $(this).children("ul").hide()
      
      #--------------ObjContents--------------
      objectsArray = ["Max", "min", "Switch", "Connection"]
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

                  

            else if $(this).html() is "Max" or "min"
              tar = ($("<div class='obj block' name='#{$(this).html()}' style='left:100px; top:100px'><input type='text' name='delta/sensor/light' value='100' class='onlynum'></div>").appendTo $("#field"))
              if $(this).html() is "Max"
                tar.addClass "Max"
              if $(this).html() is "min"
                tar.addClass "min"
              $(".onlynum").keyup ->
                s = new Array()
                $.each($(this).val().split(""), (i,v)->
                  if v.match(/[0-9]/gi) then s.push(v)
                )
                if s.length > 0
                  $(this).val(s.join(''))
                else
                  $(this).val("")
            else if $(this).html() is "Switch"
              tar = ($("<div class='obj block' name='#{$(this).html()}'><select name='delta/sensor/light' id='flip-a' value='on' data-role='slider'><option value='off'>Off</option><option value='on'>On</option></div>").appendTo $("#field"))
            if $(this).html() isnt "Connection"
              fixedDraggable tar
      #--------------SensorContents--------------
      socket.on "sensors", (data)->
        console.log data
        for i, n in data
          sensor.append "<li><a class='sensor'>#{i.name}</a></li>"
      
          #--------------SensorAction--------------
          if n is data.length-1
            $("li .sensor").click ->
              #tar = ($("<div class='sensor block' style='left: #{$(this)}; top] #{}'>#{$(this).html()}</div>").appendTo $("#field"))
              line = null
              tar = ($("<div class='sensor block' name='#{$(this).html()}' style='left:100px; top:100px'>#{$(this).html()}</div>").appendTo $("#field"))
              fixedDraggable tar
    
    isHover = false
    socket.on "lindaData", (data)->
      selector = $(".sensor[name='#{data[0]}']")
      socket.emit "delta/sensor/light", data[1]
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
      #select box
      if $("select[name='#{data[0]}']").length
        switchSelector = $("select[name='#{data[0]}'] option:selected")
        if switchSelector.val() is "on"
          #console.log "on"
          blink $("select[name='#{data[0]}']").parent("div")
        else
          #console.log "off"
          revBlink $("select[name='#{data[0]}']").parent("div")
          
      #max and min
      if $("input[name='#{data[0]}']").length and $.isNumeric(data[1])
        maxSelector = $(".Max input[name='#{data[0]}']")
        if 0+data[1] < 0+maxSelector.val()
          blink maxSelector.parent("div")
        minSelector = $(".min input[name='#{data[0]}']")
        if 0+data[1] > 0+minSelector.val()
          blink minSelector.parent("div")


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
  
  fixedDraggable = (tar)->
    tar.draggable
      create: ->
        console.log "create", $(this).html()
        socket.emit "saveClient", [path, saveClient()]
        socket.emit "sensorRequest", $(this).html()
      drag: ->
        if line?
          line.setAttribute("x1", $(this).offset().left-($("html").width()-$("#detail").width())/2)
          line.setAttribute("y1", $(this).offset().top-100)
      stop: ->
        console.log "drag end", $(this).html()
        socket.emit "saveClient", [path, saveClient()]
      cursor: "pointer"
      snap:   true
      grid:   [10, 10]
    tar.dblclick ->
      console.log "double click"
      $(this).remove()
      socket.emit "saveClient", [path, saveClient()]
    if dragFlag
      tar.draggable("enable")
    else
      tar.draggable("disable")
    



  createSVGLine = (x1, y1, x2, y2, name)->
    line = document.createElementNS("http://www.w3.org/2000/svg", "line")
    line.setAttribute("x1", x1)
    line.setAttribute("y1", y1)
    line.setAttribute("x2", x2)
    line.setAttribute("y2", y2)
    line.setAttribute("class", "svgline")
    line.setAttribute("stroke", "black")
    line.setAttribute("name", name)
    console.log "create line"
    #$("svg").append line
    line
  
  createConnection = (array)->
    obj = array[0]
    tar = array[1]
    marginLeft = ($("html").width()-$("#detail").width())/2
    marginTop  = 100
    line = createSVGLine obj.offset().left-marginLeft, obj.offset().top-marginTop, tar.offset().left-marginLeft, tar.offset().top-marginTop
    $("svg").append line
    line
    


  saveClient = ->
    if $("#field").html()?
      children = $("#field").html().replace(/<\/div>/g, "</div>区切り").replace(/<\/svg>/g, "</svg>区切り").split("区切り")
    else
      return []
    #children = $("#field").children()
    contents = []
    for i in children
      console.log "child", i
      if $(i).hasClass("block")
        contents.push i
    console.log "saved: ", contents
    contents
    

  )
