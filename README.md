Reactive And Interactive eXtensions (raix) is a functional, composable, API for AS3 that simplifies working with data, regardless of whether its interactive (arrays) or reactive (events).

## raix.reactive

_raix.reactive_ brings a more familiar API pattern to asynchronous data, like events. The center of raix.reactive is IObservable, which can be created by using one of the Observable static methods or by using the global toObservable function. It can then by subscribed to by calling subscribe and passing in a function to call when it receives a value. You can also provide a function to call when the sequence completes or when an error occurs.

Let's look at a quick example:

    var doubleClicks : IObservable = Observable.fromEvent(stage, MouseEvent.CLICK)
        .timeInterval()
        .filter(function(ti:TimeInterval):Boolean { return ti.interval < 300; })
        .removeTimeInterval();
    
    var subscription : ICancelable = doubleClicks.subscribe(function(me:MouseEvent):void
    {
        trace("Double click");
    });

    // Unsubscribe (removing all event listeners)
    subscription.cancel();

The above code accomplishes quite a bit, including managing event subscriptions and that state requires to determine the time difference between events, in a very small amount of code.

IObservable has many operators for filtering and merging asynchronous data streams, but also includes even more operators that relate to time. Check out the [Reactive Operators](https://github.com/richardszalay/raix/wiki/Reactive-Operators) reference or the [raix.reactive livedocs](http://richardszalay.github.com/raix/livedocs/raix/reactive/package-detail.html)

### Getting Started

* [Introduction to raix.reactive](https://github.com/richardszalay/raix/wiki/Introduction-to-raix.reactive)
* [Download raix](http://github.com/richardszalay/raix/downloads)
* [Reactive Operators](https://github.com/richardszalay/raix/wiki/Reactive-Operators)
* [livedocs](http://richardszalay.github.com/raix/livedocs/index.html) (though the [Reactive Operators](https://github.com/richardszalay/raix/wiki/Reactive-Operators) is more detailed)
    * The livedocs are embedded in the swc for Flash Builder 4 users
* [Background](https://github.com/richardszalay/raix/wiki/Background)
* [API differences from Rx.NET](https://github.com/richardszalay/raix/wiki/Changes-from-Rx)

### More

* [Unit Tests](http://richardszalay.github.com/raix/tests/index.htm)
* [Feedback](https://github.com/richardszalay/raix/wiki/Feedback)

## raix.interactive

_raix.interactive_ abstracts away data structures like arrays and focuses on a forward-only "stream" of values. The center of raix.interactive is IEnumerable, which can be created using one of the Enumerable static methods or by using the global [toEnumerable](https://github.com/richardszalay/raix/wiki/toEnumerable) function. It can then be enumerating by using the built in <code>for each</code> keyword in actionscript.

Let's look at a quick example:

    var filteredAndMapped : IEnumerable = toEnumerable([1, 2, 3, 4, 5, 6, 7, 8, 9])
        .filter(function(i:int):Boolean { return (i % 2) == 0); })
        .map(function(i:int):String { return "It's value " + i; });
    
    for each(var value : String in filteredAndMapped)
    {
        trace(value);
    }

    // Output:
    // It's value 2
    // It's value 4
    // It's value 6
    // It's value 8

Enumerable sequences have common operations like map and reduce, but can also be combined with other sequences through join or zip. Have a look at the [Interactive Operations](http://github.com/richardszalay/raix/wiki/Interactive-Operations) reference or the [raix.interactive livedocs](http://richardszalay.github.com/raix/livedocs/raix/interactive/package-detail.html).

