// Generated by CoffeeScript 1.6.2
(function() {
  var __slice = [].slice;

  $(function() {
    var contents, control, createConnection, createSVGLine, dragFlag, fixedDraggable, path, saveClient, socket, start, test, _ref;

    path = "";
    _ref = location.pathname.split(""), start = _ref[0], contents = 2 <= _ref.length ? __slice.call(_ref, 1) : [];
    path = contents.join("");
    console.log("path", path);
    socket = io.connect();
    control = io.connect("/control");
    test = io.connect("/test");
    dragFlag = true;
    return socket.on("connect", function() {
      var blink, drawIntro, i, isHover, n, obj, objectsArray, revBlink, sensor, _i, _len;

      console.log("connect!");
      socket.emit("path", path);
      contents = $("#err");
      if (contents != null) {
        $("<input id='create' type='submit' value='create'>").appendTo(contents).click(function() {
          socket.emit("CreateMono", path);
          return location.reload();
        });
      }
      contents = $("#index");
      if (contents != null) {
        console.log("append contents");
        contents.append("<p>Create Mono</p>");
        contents.append("<input id='monoN' type='text'>");
        contents.append("<input id='mono' type='submit' value='create'>");
        $("#mono").click(function() {
          return socket.emit("CreateMono", $("#monoN").val());
        });
        contents.append("<p>Create Sensor</p>");
        contents.append("<input id='sensorN' type='text'>");
        contents.append("<input id='sensor' type='submit' value='create'>");
        $("#sensor").click(function() {
          return socket.emit("CreateSensor", $("#sensorN").val());
        });
        contents.append("<p>Add Sensor</p>");
        contents.append("<input id='add' type='submit' value='add'>");
        $("#add").click(function() {
          return socket.emit("AddSensor", [$("#monoN").val(), $("#sensorN").val()]);
        });
      }
      contents = $("#detail");
      if (contents != null) {
        socket.on("blocks", function(blocks) {
          var i, tar, _i, _len, _results;

          console.log("blocks");
          _results = [];
          for (_i = 0, _len = blocks.length; _i < _len; _i++) {
            i = blocks[_i];
            if ($("" + i).attr("id") === ("targetObj" || "svg")) {
              continue;
            }
            tar = $(i).appendTo($("#field"));
            _results.push(fixedDraggable(tar));
          }
          return _results;
        });
        if (!$("#svg").length) {
          $("#field").svg({
            onLoad: drawIntro
          });
          drawIntro = function(svg) {
            return console.log("create svg");
          };
          $("#field").attr({
            xmlns: "http://www.w3.org/2000/svg"
          });
          $("svg").attr({
            id: "svg"
          });
        }
        if ($("#targetObj").length) {
          console.log("exist");
        } else {
          console.log("not exist");
          if (path !== "") {
            $("#field").append("<div id=targetObj>" + path + "</div>");
          }
          console.log(path);
        }
        sensor = $("#sensorContents");
        obj = $("#objContents");
        $("#menu li").hover(function() {
          return $(this).children("ul").show();
        }, function() {
          return $(this).children("ul").hide();
        });
        objectsArray = ["Max", "min", "Switch", "Connection"];
        for (n = _i = 0, _len = objectsArray.length; _i < _len; n = ++_i) {
          i = objectsArray[n];
          obj.append("<li><a class='obj'>" + i + "</a></li>");
          if (n === objectsArray.length - 1) {
            $("li .obj").click(function() {
              var array, tar;

              if ($(this).html() === "Connection") {
                array = [];
                alert("select two elements");
                $(".ui-draggable").draggable("disable").click(function() {
                  array.push($(this));
                  if (array.length === 2) {
                    console.log(array);
                    createConnection(array);
                    return $(".ui-draggable-disabled").draggable("enable");
                  }
                });
              } else if ($(this).html() === "Max" || "min") {
                tar = $("<div class='obj block' name='" + ($(this).html()) + "' style='left:100px; top:100px'><input type='text' name='delta/sensor/light' value='100' class='onlynum'></div>").appendTo($("#field"));
                if ($(this).html() === "Max") {
                  tar.addClass("Max");
                }
                if ($(this).html() === "min") {
                  tar.addClass("min");
                }
                $(".onlynum").keyup(function() {
                  var s;

                  s = new Array();
                  $.each($(this).val().split(""), function(i, v) {
                    if (v.match(/[0-9]/gi)) {
                      return s.push(v);
                    }
                  });
                  if (s.length > 0) {
                    return $(this).val(s.join(''));
                  } else {
                    return $(this).val("");
                  }
                });
              } else if ($(this).html() === "Switch") {
                tar = $("<div class='obj block' name='" + ($(this).html()) + "'><select name='delta/sensor/light' id='flip-a' value='on' data-role='slider'><option value='off'>Off</option><option value='on'>On</option></div>").appendTo($("#field"));
              }
              if ($(this).html() !== "Connection") {
                return fixedDraggable(tar);
              }
            });
          }
        }
        socket.on("sensors", function(data) {
          var _j, _len1, _results;

          console.log(data);
          _results = [];
          for (n = _j = 0, _len1 = data.length; _j < _len1; n = ++_j) {
            i = data[n];
            sensor.append("<li><a class='sensor'>" + i.name + "</a></li>");
            if (n === data.length - 1) {
              _results.push($("li .sensor").click(function() {
                var line, tar;

                line = null;
                tar = $("<div class='sensor block' name='" + ($(this).html()) + "' style='left:100px; top:100px'>" + ($(this).html()) + "</div>").appendTo($("#field"));
                return fixedDraggable(tar);
              }));
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        });
      }
      isHover = false;
      socket.on("lindaData", function(data) {
        var maxSelector, minSelector, selector, switchSelector;

        selector = $(".sensor[name='" + data[0] + "']");
        socket.emit("delta/sensor/light", data[1]);
        blink(selector);
        if (isHover) {
          $("#explain").append("<p class='inspector'>" + data[1] + "</p>");
        }
        if ($(".inspector").length > 6) {
          $(".inspector:first").slideUp(function() {
            this.remove;
            return console.log(this);
          });
        }
        selector.hover(function() {
          return isHover = true;
        }, function() {
          isHover = false;
          return $(".inspector").remove();
        });
        if ($("select[name='" + data[0] + "']").length) {
          switchSelector = $("select[name='" + data[0] + "'] option:selected");
          if (switchSelector.val() === "on") {
            blink($("select[name='" + data[0] + "']").parent("div"));
          } else {
            revBlink($("select[name='" + data[0] + "']").parent("div"));
          }
        }
        if ($("input[name='" + data[0] + "']").length && $.isNumeric(data[1])) {
          maxSelector = $(".Max input[name='" + data[0] + "']");
          if (0 + data[1] < 0 + maxSelector.val()) {
            blink(maxSelector.parent("div"));
          }
          minSelector = $(".min input[name='" + data[0] + "']");
          if (0 + data[1] > 0 + minSelector.val()) {
            return blink(minSelector.parent("div"));
          }
        }
      });
      socket.on("disconnect", function() {
        return console.log("disconnect");
      });
      blink = function(selector) {
        selector.css({
          backgroundColor: "#CBD6FF"
        });
        return setTimeout(function() {
          return selector.css({
            backgroundColor: "white"
          });
        }, 500);
      };
      return revBlink = function(selector) {
        selector.css({
          backgroundColor: "white"
        });
        return setTimeout(function() {
          return selector.css({
            backgroundColor: "#CBD6FF"
          });
        }, 500);
      };
    }, fixedDraggable = function(tar) {
      tar.draggable({
        create: function() {
          console.log("create", $(this).html());
          socket.emit("saveClient", [path, saveClient()]);
          return socket.emit("sensorRequest", $(this).html());
        },
        drag: function() {
          if (typeof line !== "undefined" && line !== null) {
            line.setAttribute("x1", $(this).offset().left - ($("html").width() - $("#detail").width()) / 2);
            return line.setAttribute("y1", $(this).offset().top - 100);
          }
        },
        stop: function() {
          console.log("drag end", $(this).html());
          return socket.emit("saveClient", [path, saveClient()]);
        },
        cursor: "pointer",
        snap: true,
        grid: [10, 10]
      });
      tar.dblclick(function() {
        console.log("double click");
        $(this).remove();
        return socket.emit("saveClient", [path, saveClient()]);
      });
      if (dragFlag) {
        return tar.draggable("enable");
      } else {
        return tar.draggable("disable");
      }
    }, createSVGLine = function(x1, y1, x2, y2, name) {
      var line;

      line = document.createElementNS("http://www.w3.org/2000/svg", "line");
      line.setAttribute("x1", x1);
      line.setAttribute("y1", y1);
      line.setAttribute("x2", x2);
      line.setAttribute("y2", y2);
      line.setAttribute("class", "svgline");
      line.setAttribute("stroke", "black");
      line.setAttribute("name", name);
      console.log("create line");
      return line;
    }, createConnection = function(array) {
      var line, marginLeft, marginTop, obj, tar;

      obj = array[0];
      tar = array[1];
      marginLeft = ($("html").width() - $("#detail").width()) / 2;
      marginTop = 100;
      line = createSVGLine(obj.offset().left - marginLeft, obj.offset().top - marginTop, tar.offset().left - marginLeft, tar.offset().top - marginTop);
      $("svg").append(line);
      return line;
    }, saveClient = function() {
      var children, i, _i, _len;

      if ($("#field").html() != null) {
        children = $("#field").html().replace(/<\/div>/g, "</div>区切り").replace(/<\/svg>/g, "</svg>区切り").split("区切り");
      } else {
        return [];
      }
      contents = [];
      for (_i = 0, _len = children.length; _i < _len; _i++) {
        i = children[_i];
        console.log("child", i);
        if ($(i).hasClass("block")) {
          contents.push(i);
        }
      }
      console.log("saved: ", contents);
      return contents;
    });
  });

}).call(this);
