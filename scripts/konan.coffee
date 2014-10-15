# what is best in life
module.exports = (robot) ->
  robot.respond /what.(i)?s best in life/i, (msg) ->
    msg.reply "To crush your enemies -- See them driven before you, and to hear the lamentation of their women!"
