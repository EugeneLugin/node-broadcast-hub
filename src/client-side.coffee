root = @ # In the browser, this will be window

io = root.io
if !io && typeof require != 'undefined'
    io = require 'socket.io-client'

throw Error('No Socket.IO found, be sure to include it!') if !io

class BroadcastHubClient
    constructor: (@options = {}) ->
        @listeners = {}

        @client = io.connect(options.server, {
            'force new connection': true
        })
        @client.on 'hubMessage', @_processMessage
        @client.on 'hubSubscribed', () => @emit('connected')
        @client.on 'disconnect', @_onDisconnected

    on: (event, cb) ->
        @listeners[event] = [] if !@listeners[event]
        @listeners[event].push(cb)

    once: (event, cb) ->
        wrapper = () ->
            cb.apply(@, arguments)
            @off(event, wrapper)
        @on(event, wrapper)

    off: (event, cb) ->
        return if !@listeners[event] or cb not in @listeners[event]
        @listeners[event].splice(@listeners[event].indexOf(cb), 1)

    emit: (event, args...) ->
        return if !@listeners[event]
        for listener in @listeners[event]
            listener.apply(@, args)

    _processMessage: (message) =>
        @emit('message', message.channel, message.message)
        @emit("message:#{message.channel}", message.message)

    _onDisconnected: (reason) =>
        @emit('disconnected')
        if reason != 'booted'
            # TODO: Trigger reconnect
            console.log arguments

    disconnect: (cb) ->
        if cb
            @client.once 'disconnected', () ->
                console.log arguments
                cb()
        @client.disconnect()

if typeof module != 'undefined'
    # Node.js
    module.exports = BroadcastHubClient
else
    # Browsers
    root.BroadcastHubClient = BroadcastHubClient
