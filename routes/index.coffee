exports.index = (req,res) ->
  res.render('index',{title:'Express'})

exports.detail = (req, res)->
  res.render("detail")
