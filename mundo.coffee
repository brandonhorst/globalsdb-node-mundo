driver = require 'cache'
async = require 'async'

module.exports.MundoClient =
    connect: (url, done) ->
        cacheDriver = require 'cache'
        cache = new driver.Cache()
        cache.open
            path: '/globals/mgr'
        , (err, res) ->
            if err
                done res
            else
                mundo = new DB cache
                done null, mundo

class DB
    constructor: (@cache) ->

    collection: (name) ->
        new Global @cache, name

    close: (done) ->
        @cache.close (err, res) ->
            error = if err then res else null
            done(err)

class Cursor
    constructor: (@global, @obj) ->

    toArray: (done) ->
        subscripts = [@obj._id]
        @global._retrieve subscripts, (err, result) =>
            result._id = @obj._id
            done err, [result]

class Global
    constructor: (@db, @name) ->
        @node =
            global: @name

    insert: (obj, done) ->
        _id = obj._id
        delete obj._id
        subscripts = [_id]
        @_set subscripts, 'o', => # DOES THIS NEED TO BE INDEPENDENT?
            @_insert obj, subscripts, (err) =>
                done(err)

    find: (obj, done) ->
        new Cursor @, obj

    remove: (obj, done) ->
        @_kill [], done

    _insert: (obj, subscripts, done) ->
        value = switch typeof obj
            when 'string' then "s#{obj}"
            when 'number' then "n#{obj}"
            when 'boolean' then "b#{if obj then 1 else 0}"
            when 'object'
                if obj == null then 'u'
                else if Array.isArray(obj) then 'a'
                else 'o'

        @_set subscripts, value, (err) => #DOES THIS NEED TO BE INDEPENDENT?
            if value == 'a'
                async.each [0...obj.length], (item, done) =>
                    newSubscripts = subscripts.concat [item] # try with this as a string?
                    value = @_insert obj[item], newSubscripts, done
                , done

            else if value == 'o'
                async.each Object.keys(obj) , (key, done) =>
                    newSubscripts = subscripts.concat [key]
                    value = @_insert obj[key], newSubscripts, done
                , done
            else
                done err

    _retrieve: (subscripts, done) ->
        @_get subscripts, (err, value) =>
            switch value[0]
                when 's' then done null, value[1..]
                when 'n' then done null, Number(value[1..])
                when 'b' then done null, (if value[1] == '1' then true else false)
                when 'u' then done null, null
                when 'o'
                    result = {}
                    handleNext = (prevSubscripts, done) =>
                        @_next prevSubscripts, (err, nextSubscripts) =>
                            if nextSubscripts[nextSubscripts.length - 1] == ""
                                done null, result
                                return
                            else
                                @_retrieve nextSubscripts, (err, nextJSValue) =>
                                    result[nextSubscripts[nextSubscripts.length-1]] = nextJSValue
                                    handleNext nextSubscripts, done
                    newSubscripts = subscripts.concat ['']
                    handleNext newSubscripts, (err, res) =>
                        done err, res
                when 'a'
                    result = []
                    handleNext = (nextSubscripts, done) =>
                        @_next nextSubscripts, (err, nextSubscripts) =>
                            if nextSubscripts[nextSubscripts.length - 1] == ""
                                done null, result
                                return
                            else
                                @_retrieve nextSubscripts, (err, nextJSValue) =>
                                    result[result.length] = nextJSValue
                                    handleNext nextSubscripts, done
                    newSubscripts = subscripts.concat ['']
                    handleNext newSubscripts, (err, res) =>
                        done err, res
                else console.log "SOMETHING IS WEIRD: #{value}"

    _set: (subscripts, value, done) ->
        @node.subscripts = subscripts
        @node.data = value

        @db.set @node, ->
            done null

    _get: (subscripts, done) ->
        @node.subscripts = subscripts
        @db.get @node, (err, res) ->
            done null, res.data

    _next: (subscripts, done) ->
        @node.subscripts = subscripts
        @db.order @node, (err, res) ->
            done null, res.subscripts

    _kill: (subscripts, done) ->
        @node.subscripts = subscripts
        @db.kill @node, (err, res) ->
            done null

