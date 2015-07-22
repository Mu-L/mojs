h            = require '../h'
t            = require './tweener'
easing       = require '../easing/easing'

class Tween
  defaults:
    duration:         600
    delay:            0
    repeat:           0
    yoyo:             false
    easing:           'Linear.None'
    onStart:          null
    onComplete:       null
    isChained:        false
  constructor:(@o={})-> @extendDefaults(); @vars(); @
  vars:->
    @h = h; @props = {}; @progress = 0; @prevTime = 0
    @props.easing = easing.parseEasing @o.easing
    @calcDimentions()
  calcDimentions:->
    @props.totalTime     = (@o.repeat+1)*(@o.duration+@o.delay)
    @props.totalDuration = @props.totalTime - @o.delay
  extendDefaults:-> h.extend(@o, @defaults); @onUpdate = @o.onUpdate
  start:(time)->
    @isCompleted = false; @isStarted = false
    time ?= performance.now()
    @props.startTime = time + @o.delay
    @props.endTime   = @props.startTime + @props.totalDuration
    @
  update:(time)->
    if (time >= @props.startTime) and (time < @props.endTime)
      @isOnReverseComplete = false; @isCompleted = false
      if !@isFirstUpdate then @o.onFirstUpdate?.apply(@); @isFirstUpdate = true
      if !@isStarted then @o.onStart?.apply(@); @isStarted = true
      
      elapsed = time - @props.startTime
      # in the first repeat or without any repeats
      if elapsed <= @o.duration then @setProc elapsed/@o.duration
      # far in the repeats
      else
        start = @props.startTime
        isDuration = false; cnt = 0
        # get the last time point before time
        # by increasing the startTime by the
        # duration or delay in series
        # get the latest just before the time
        while(start <= time)
          isDuration = !isDuration
          start += if isDuration then cnt++; @o.duration else @o.delay
        # if have we stopped in start point + duration
        if isDuration
          # get the start point
          start = start - @o.duration
          elapsed = time - start
          @setProc elapsed/@o.duration
          # yoyo
          if @o.yoyo and @o.repeat
            @setProc if cnt % 2 is 1 then @progress
            # when reversed progress of 1 should be 0
            else 1-if @progress is 0 then 1 else @progress
        # we have stopped in start point + delay
        # set proc to 1 if previous time is smaller
        # then the current one, otherwise set to 0
        else @setProc if @prevTime < time then 1 else 0
      if time < @prevTime and !@isFirstUpdateBackward
        @o.onFirstUpdateBackward?.apply(@); @isFirstUpdateBackward = true
      # @onUpdate? @easedProgress
    else
      if time >= @props.endTime and !@isCompleted
        @setProc 1#; @onUpdate? @easedProgress
        @o.onComplete?.apply(@); @isCompleted = true
        @isOnReverseComplete = false
      if time > @props.endTime or time < @props.startTime
        @isFirstUpdate = false
      # reset isFirstUpdateBackward flag if progress went further the end time
      @isFirstUpdateBackward = false if time > @props.endTime
    if time < @prevTime and time <= @props.startTime
      if !@isFirstUpdateBackward
        @o.onFirstUpdateBackward?.apply(@); @isFirstUpdateBackward = true
      if !@isOnReverseComplete
        @isOnReverseComplete = true
        @setProc(0, !@o.isChained)#; !@o.isChained and @onUpdate? @easedProgress
        @o.onReverseComplete?.apply(@)
    @prevTime = time

    @isCompleted

  setProc:(p, isCallback=true)->
    @progress = p; @easedProgress = @props.easing @progress
    if @props.prevEasedProgress isnt @easedProgress and isCallback
      @onUpdate?(@easedProgress, @progress)
    @props.prevEasedProgress = @easedProgress

  setProp:(obj, value)->
    if typeof obj is 'object'
      for key, val of obj
        @o[key] = val
    else if typeof obj is 'string' then @o[obj] = value
    @calcDimentions()
  # ---

  # Method to run the Tween
  # @param  {Number} Start time
  # @return {Object} Self
  run:(time)->
    @start(time); !time and (t.add(@); ###@state = 'play'###)
    @
  # ---

  # Method to stop the Tween.
  stop:-> @pause(); @setProc(0); @
  # ---

  # Method to pause Tween.
  pause:-> @_removeFromTweener(); @

  # ---
  # 
  # Method to remove the Tween from the tweener.
  _removeFromTweener:-> t.remove(@); @


module.exports = Tween


