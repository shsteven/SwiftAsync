//
//  async.swift
//  Async
//
//  Created by Ross Penman on 07/06/2014.
//  Copyright (c) 2014 Ross Penman. All rights reserved.
//

class Async<T> {
    let value: T[]
    
    @required init(_ contents: T[]) {
        value = contents
    }
    
    class func map<Result>(array: T[], limit: Int, iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> T[] {
        return self(array).map(limit: limit, iterator: iterator, callback: callback).value
    }
    
    func map<Result>(#limit: Int, iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> Async<T> {
        let totalCount = value.count
        var results = Dictionary<Int, Result>(minimumCapacity: totalCount)
        var runningCount = 0
        var completeCount = 0
        var i = 0
        
        var runNextFix: () -> () = {}
        func runNext() {
            let index = i++
            let next = value[index]
            
            runningCount++
            iterator(next) { (result) in
                runningCount--
                completeCount++
                
                results[index] = result
                
                if completeCount == totalCount {
                    // all tasks complete
                    var resultsArray = Result[]()
                    for var j = 0; j < results.count; j++ {
                        resultsArray.append(results[j]!)
                    }
                    
                    callback?(resultsArray)
                } else if i < totalCount {
                    runNextFix()
                }
            }
            
            if runningCount < limit {
                runNextFix()
            }
        }
        runNextFix = runNext
        runNext()
        
        return self
    }
    
    class func mapSeries<Result>(array: T[], iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> T[] {
        return self(array).mapSeries(iterator, callback: callback).value
    }
    
    func mapSeries<Result>(iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> Async<T> {
        return map(limit: 1, iterator: iterator, callback: callback)
    }
    
    class func eachSeries(array: T[], iterator: (T, () -> ()) -> (), callback: (() -> ()) = {}) -> T[] {
        return self(array).eachSeries(iterator, callback: callback).value
    }
    
    func eachSeries(iterator: (T, () -> ()) -> (), callback: (() -> ()) = {}) -> Async<T> {
        return mapSeries({ (elem, callback) in
            iterator(elem) { callback(nil) }
        }, callback: { (results) in callback() })
    }
    
    class func map<Result>(array: T[], iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> T[] {
        return self(array).map(iterator, callback: callback).value
    }
    
    func map<Result>(iterator: (T, (Result) -> ()) -> (), callback: ((Result[]) -> ())?) -> Async<T> {
        return map(limit: value.count, iterator: iterator, callback: callback)
    }
    
    class func each(array: T[], iterator: (T, () -> ()) -> (), callback: () -> () = {}) -> T[] {
        return self(array).each(iterator, callback: callback).value
    }
    
    func each(iterator: (T, () -> ()) -> (), callback: () -> () = {}) -> Async<T> {
        return map({ (elem, callback) in
            iterator(elem) { callback(nil) }
        }, callback: { (results) in callback() })
    }
}