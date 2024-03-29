# Description:
#   Forgetful? Add reminders
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot remind me in <time> to <action> - Set a reminder in <time> to do an <action> <time> is in the format 1 day, 2 hours, 5 minutes etc. Time segments are optional, as are commas
#
# Author:
#   whitman

class Reminder
  constructor: (@msg_envelope, @time, @action, @repeat) ->
    @time.replace(/^\s+|\s+$/g, '')
    periods =
      weeks:
        value: 0
        regex: "weeks?"
      days:
        value: 0
        regex: "days?"
      hours:
        value: 0
        regex: "hours?|hrs?"
      minutes:
        value: 0
        regex: "minutes?|mins?"
      seconds:
        value: 0
        regex: "seconds?|secs?"

    for period of periods
      pattern = new RegExp('^.*?([\\d\\.]+)\\s*(?:(?:' + periods[period].regex + ')).*$', 'i')
      matches = pattern.exec(@time)
      periods[period].value = parseInt(matches[1]) if matches

    @due = new Date().getTime()
    @due += ((periods.weeks.value * 604800) + (periods.days.value * 86400) + (periods.hours.value * 3600) + (periods.minutes.value * 60) + periods.seconds.value) * 1000
    @repeat = repeat

  dueDate: ->
    dueDate = new Date @due
    dueDate.toLocaleString()

class Reminders
  constructor: (@robot) ->
    @cache = []
    @current_timeout = null

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.reminders
        #@cache = @robot.brain.data.reminders
        @queue()
  _add: (reminder) ->
    @cache.push reminder
    @cache.sort (a, b) -> a.due - b.due
  add: (reminder) ->
    @_add(reminder)
    @robot.brain.data.reminders = @cache
    @queue()

  removeFirst: ->
    reminder = @cache.shift()
    @robot.brain.data.reminders = @cache
    return reminder

  queue: ->
    clearTimeout @current_timeout if @current_timeout
    if @cache.length > 0
      now = new Date().getTime()
      @removeFirst() until @cache.length is 0 or @cache[0].due > now
      if @cache.length > 0
        trigger = =>
          reminder = @removeFirst()
          next_msg = ''
          if reminder.repeat is true
            new_reminder = new Reminder reminder.msg_envelope, reminder.time, reminder.action, reminder.repeat
            @_add new_reminder
            next_msg = ' (next alert at '+new_reminder.dueDate()+')'
          @robot.reply reminder.msg_envelope, 'you asked me to remind you to ' + reminder.action + next_msg
          @queue()
        # setTimeout uses a 32-bit INT
        extendTimeout = (timeout, callback) ->
          if timeout > 0x7FFFFFFF
            @current_timeout = setTimeout ->
              extendTimeout (timeout - 0x7FFFFFFF), callback
            , 0x7FFFFFFF
          else
            @current_timeout = setTimeout callback, timeout
        extendTimeout @cache[0].due - now, trigger

module.exports = (robot) ->

  reminders = new Reminders robot

  robot.respond /remind me (in|every) ((?:(?:\d+) (?:weeks?|days?|hours?|hrs?|minutes?|mins?|seconds?|secs?)[ ,]*(?:and)? +)+)to (.*)/i, (msg) ->
    repeat = msg.match[1] is 'every'
    time = msg.match[2]
    action = msg.match[3]
    reminder = new Reminder msg.envelope, time, action, repeat
    reminders.add reminder
    msg.send 'I\'ll remind you to ' + action + ' on ' + reminder.dueDate()

