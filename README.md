node-globalsdb-remote
=====================

An experiment replicating MongoDB-esque functionality in GlobalsDB/Cache.

###Storage Structure

    {
        _id: 1,
        test: "val",
        sports: ['baseball', 'softball', 'dodgeball'],
        numba: 7.334,
        nullo: null,
        something: "8.3",
        addr: {
            street: '1 Memorial Dr',
            city: 'Cambridge'
        },
        bool: true
    }

is stored as 

    ^x(1)="o"
    ^x(1,"addr")="o"
    ^x(1,"addr","city")="sCambridge"
    ^x(1,"addr","street")="s1 Memorial Dr"
    ^x(1,"bool")="b1"
    ^x(1,"nullo")="u"
    ^x(1,"numba")="n7.334"
    ^x(1,"something")="s8.3"
    ^x(1,"sports")="a"
    ^x(1,"sports",0)="sbaseball"
    ^x(1,"sports",1)="ssoftball"
    ^x(1,"sports",2)="sdodgeball"
    ^x(1,"test")="sval"

###Benchmarking

    * 100000 Insertions of the above object:
        - Globals: 3.269745131s
        - MongoDB: 1.410825992s
    * 100000 Retrievals of those objects, by _id:
        - Globals: 4.642820684s
        - MongoDB: 1.166664768s