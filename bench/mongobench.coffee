NanoTimer = require 'nanotimer'
async = require 'async'

retrievePeople = (collection, n, done) ->
    async.each [1..n], (i, done) ->
        collection.find({_id: i}).toArray (err, array) ->
            console.log err if err?
            obj = array[0]
            if obj._id == i
                done null, obj
            else
                done err, obj
    , (err) ->
        done err

createPeople = (collection, n, done) ->
    async.each [1..n], (i, done) ->
        obj = 
            _id: i
            test: "val"
            sports: ['baseball', 'softball', 'dodgeball']
            numba: 7.334
            nullo: null
            something: "8.3"
            addr:
                street: '1 Memorial Dr'
                city: 'Cambridge'
            bool: true
        collection.insert obj, done
    , done

timeFunction = (func, collection, num, done) ->
    timer = new NanoTimer()
    timer.time func, [collection, num], 's', (time) ->
        console.log time
        done null


test = (Client, done) ->
    Client.connect 'mongodb://127.0.0.1:27017/test', (err, db) ->
        throw err if err?
        collection = db.collection 'x'
        collection.remove {}, (err) ->
            async.series [
               (done) -> timeFunction createPeople, collection, 10000, done
               (done) -> timeFunction retrievePeople, collection, 10000, done
            ] , (err) ->
                db.close done

async.series [
    (callback) ->
        MundoClient = require('../mundo').MundoClient
        console.log "GlobalsDB:"
        test MundoClient, callback
    ,
    (callback) ->
        MongoClient = require('mongodb').MongoClient
        console.log "MongoDB:"
        test MongoClient, callback
]

    # createPerson db.x, 100, (err) ->
    #   print(err) if err?