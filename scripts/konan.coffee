module.exports = (robot) ->
  robot.respond /what is best thing in life/i, (msg) ->
    msg.send "To crush your enemies -- See them driven before you, and to hear the lamentation of their women!"
