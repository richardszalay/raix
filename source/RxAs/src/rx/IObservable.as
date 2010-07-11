package rx
{
	import rx.scheduling.IScheduler;
	import rx.subjects.IConnectableObservable;
	
	/**
	 * An observable sequence of values
	 */	
	public interface IObservable
	{
		/**
		 * The class of the values emitted by this observable sequence 
		 * @return Class
		 */
		function get valueClass() : Class;
		
		/**
		 * Subscribes to this observable using the supplied functions
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/subscribe">Online Documentation</a></p> 
		 * @param onNext Function to be called for every payload. Signature is <code>function(payload : T) : void</code>
		 * @param onComplete Optional. Function to be called when the sequence completes. Signature is <code>function():void</code>
		 * @param onError Optional. Function to be called when an error occurs in the sequence. Signature is <code>function(err:Error):void</code>
		 * @return An instance of ISubscription that can be used to unsubscribe at anytime by calling <code>unsubscribe()</code> 
		 */
		function subscribe(onNext : Function, onComplete : Function = null, 
			onError : Function = null) : ICancelable;
		
		/**
		 * Subscribes to this observable using the supplied observer
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/subscribeWith">Online Documentation</a></p> 
		 * @return An instance of ISubscription that can be used to unsubscribe at anytime by calling unsubscribe() 
		 */
		function subscribeWith(observer : IObserver) : ICancelable;
		
		/** 
		 * Creates a pattern by combining the current source with right.
		 * 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/and">Online Documentation</a></p>
		 * @param right The other sequence to combine with the pattern.
		 * @return A pattern representing both sequences
		 */
		function and(right : IObservable) : Pattern;
		
		/** 
		 * Runs calculation functions over every value in the source sequence and emits the final result
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/aggregate">Online Documentation</a></p> 
		 * @param accumulator A function that accumulates the aggregate value
		 * @param outputType The class of the values returned by accumulator
		 * @param initialValue The value to start with
		 * @return An observable sequence of outputType (or this instance's valueClass if outputType is null)
		 */		 
		function aggregate(accumulator : Function, outputType : Class = null, initialValue : Object = null) : IObservable;
		
		/**
		 * Determines if the source sequence contains a value that satisfies a condition
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/any">Online Documentation</a></p>
		 *  
		 * @param predicate The predicate that determines if a value in the sequence is valid. If null, the value will be evaulated to boolean. 
		 * @return An observable sequence of Boolean
		 */		
		function any(predicate : Function = null) : IObservable;
		
		/**
		 * Determines if all values in the source sequence satisfy a condition
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/all">Online Documentation</a></p>
		 * @param predicate The predicate that determines if a value in the sequence is valid. If null, the value will be evaulated to boolean. 
		 * @return An observable sequence of Boolean
		 */		 
		function all(predicate : Function) : IObservable;
		
		/**
		 * Returns the average value of all the elements in the source sequence  
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/average">Online Documentation</a></p>
		 * @return An observable sequence of the same valueClass as the current sequence (which should be numeric)
		 */		
		function average():IObservable;
		
		/**
		 * Emits the values from a source sequence in groups of a specific size  
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/bufferWithCount">Online Documentation</a></p>
		 * @param count The number of values to buffer
		 * @param skip The number of values to offset after the buffer is emitted.
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function bufferWithCount(count : uint, skip : uint = 0) : IObservable;
		
		/**
		 * Emits the values from a source sequence in groups of a specific size  
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/bufferWithTime">Online Documentation</a></p>
		 * @param timeMs The amount of time to buffer before the values are released
		 * @param timeShiftMs The amount of time to offset after the buffer is emitted
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function bufferWithTime(timeMs : uint, timeShiftMs : uint = 0, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Forces values from a source sequence to be of a specific valueClass
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/cast">Online Documentation</a></p>
		 * @param valueClass The valueClass of the output sequence
		 * @return An observable sequence of valueClass 
		 */
		function cast(valueClass : Class) : IObservable;
		
		/**
		 * Runs a specific sequence when an error occurs
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/catchError">Online Documentation</a></p>
		 * @param second The sequence to subscribe to when an error occurs
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function catchError(second : IObservable) : IObservable;
		
		/**
		 * Runs a specific sequence, determined at runtime, when an error occurs
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/catchErrorDefer">Online Documentation</a></p>
		 * @param errorType The class (and superclass) of error to act on
		 * @param deferFunc The function to execute in the event of an error. Signature is <code>function(e : Error) : IObservable</code>
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function catchErrorDefer(errorType : Class, deferFunc : Function) : IObservable;
		
		/**
		 * Merges two sequences through a mapping function, using the latest value from either source 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/combineLatest">Online Documentation</a></p>
		 * @param returnType The valueClass of the values returned by selector
		 * @param right The sequence to combine with
		 * @param selector The function that combines values from the two sources. Signature is <code>function(left : this.valueClass, right : right.valueClass) : returnType</code>
		 * @return An observable sequence of returnType 
		 */		
		function combineLatest(returnType : Class, right:IObservable, selector:Function):IObservable;
		
		/**
		 * Concatonates multiple sequences by running each sequence as the previous one finishes
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/concat">Online Documentation</a></p>
		 * @param sources The sequences to concatonate after the current sequence 
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function concat(sources : Array/*.<IObservable>*/) : IObservable;
		
		/**
		 * Determines if the source sequence contains a specific value 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/contains">Online Documentation</a></p>
		 * @param value The value to check against the sequence
		 * @param comparer The function used to compare values. Default equality will be used if comparer is null.
		 * @return An observable sequence of Boolean
		 */		
		function contains(value : Object, comparer : Function = null) : IObservable
		
		/**
		 * Returns the number of elements in the source sequence 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/count">Online Documentation</a></p>
		 * @return An observable sequence of int
		 */		
		function count() : IObservable;
		
		/**
		 * Delays all values in a sequences by a specified time 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/delay">Online Documentation</a></p>
		 * @param delayMs The amount of time, in milliseconds, to delay
		 * @param scheduler The scheduler used to delay the values
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function delay(delayMs : uint, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Converts materialized values back into messages  
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/dematerialize">Online Documentation</a></p>
		 * @param valueClass The class of the original values 
		 * @return An observable sequence of valueClass
		 */		
		function dematerialize(valueClass : Class):IObservable;
		
		/**
		 * Allows custom code to be run when messages arrive without affecting the observer  
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/doAction">Online Documentation</a></p>
		 * @param next The function to execute in the event of a value (onNext)
		 * @param complete The function to execute in the event the sequence completes (onComplete)
		 * @param error The function to execute in the event of an error (onError)
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function doAction(next:Function, complete:Function = null, error:Function = null):IObservable;
		
		/**
		 * Executes a function when the sequence completes or errors
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/finallyAction">Online Documentation</a></p>
		 * @param finallyAction The function to execute in the event the sequence completes or errors
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function finallyAction(finallyAction : Function) : IObservable;
		
		/**
		 * Emits the first value in the sequence, or an error if the sequence completes with no values 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/first">Online Documentation</a></p>
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */
		function first() : IObservable;
		
		/**
		 * Emits the first value in the sequence, or a default value if the sequence completes with no values
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/firstOrDefault">Online Documentation</a></p> 
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */		
		function firstOrDefault() : IObservable;
		
		/**
		 * Combines the current sequence with another, emitting the last values of both after both have completed 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/forkJoin">Online Documentation</a></p> 
		 * @param resultType The class of the valueClass returned by selector
		 * @param right The sequence to subscribe to, along with the current sequence
		 * @param selector The function that accepts the last values of both sequences and returns the output value 
		 * @return An observable sequence of valueClass resultType
		 */		
		function forkJoin(resultType : Class, right : IObservable, selector : Function):IObservable;
		
		/**
		 * Hides the source sequence so it cannot be cast back to it’s concrete implementation  
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function asObservable() : IObservable;
		
		/**
		 * Filters out consecutive duplicates from a source sequence  
		 * @param comparer The function used to compare values. Default equality will be used if comparer is null.
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function distinctUntilChanged(comparer : Function = null) : IObservable;
		
		/**
		 * Emits the last value in the sequence, or an error if the sequence completes with no values 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/last">Online Documentation</a></p>
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */
		function last() : IObservable;
		
		/**
		 * Emits the last value in the sequence, or the default value if the sequence completes with no values 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/lastOrDefault">Online Documentation</a></p>
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function lastOrDefault() : IObservable;
		
		/**
		 * Pipes a composed sequence to be mapped through a function so it can be used multiple times 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/let">Online Documentation</a></p>
		 * @param func The function to send the current sequence through, and return a new sequence 
		 * @return The observable sequence returned by func 
		 */		
		function let(func : Function) : IObservable;
		
		/**
		 * Converts all messages (next, complete, error) into values 
		 * <p><a href="http://wiki.github.com/richardszalay/rxas/materialize">Online Documentation</a></p>
		 * @return An observable sequence of rx.Notification
		 */		
		function materialize() : IObservable;
		
		/**
		 * Emits the values from multiple sources in the order that they arrive 
		 * @param sources The other sequences from which the values will be merged with the current sequence
		 * @param scheduler The scheduler to use 
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function merge(sources : IObservable, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Filters out values from a source sequence that are not of a specific valueClass 
		 * @param valueClass The class (or subsclass) of all values to emit 
		 * @return An observable sequence of valueClass
		 */		
		function ofType(valueClass : Class) : IObservable;

		/**
		 * Defers messages to subscribers through a scheduler  
		 * @param scheduler The subscriber to send messages to subscribers through
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function observeOn(scheduler : IScheduler) : IObservable;
		
		/**
		 * Defers subscriptions to the source through a scheduler  
		 * @param scheduler The subscriber to schedule subscriptions through
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function subscribeOn(scheduler : IScheduler) : IObservable;
		
		/**
		 * Subscribes down a list of sequence as each one errors or complete 
		 * @param second The sequence to run after the current sequence completes or errors
		 * @param scheduler The scheduler to use to subscribe to the new sequence
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function onErrorResumeNext(second:IObservable, scheduler:IScheduler=null):IObservable; 
		 
		/**
		 * Creates a shared sequence that emits the last value of the source sequence 
		 * @param scheduler The scheduler to use
		 * @return A connectable observable sequence of the same valueClass as the current sequence
		 */
		function prune(scheduler : IScheduler = null) : IConnectableObservable;
		
		/**
		 * Creates, and immediately connects to, a shared sequence that emits the last value of the source sequence 
		 * @param selector The function to map the connected sequence through
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function pruneAndConnect(selector : Function, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Creates a connectable sequence that can be shared by multiple observers  
		 * @return A connectable observable sequence of the same valueClass as the current sequence 
		 */
		function publish() : IConnectableObservable;
		
		/**
		 * Creates, and immediately connects to, a connectable sequence that can be shared by multiple observers
		 * @param selector The function to map the connected sequence through
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function publishAndConnect(selector : Function) : IObservable;
		
		/**
		 * Removes time interval information added with timeInterval  
		 * @param valueClass The class of the original values
		 * @return An observable sequence of valueClass
		 */		
		function removeTimeInterval(valueClass : Class) : IObservable;
		
		/**
		 * Removes timestamp information added with timestamp  
		 * @param valueClass The class of the original values
		 * @return An observable sequence of valueClass
		 */
		function removeTimestamp(valueClass : Class) : IObservable;
		
		/**
		 * Records the output of the source sequence and replays it to future subscribers 
		 * @param bufferSize The number of values at the end of the sequence to replay, or 0 for all.
		 * @param window The window of time, in milliseconds, in which to replay values from the end of the sequence, or 0 for all.
		 * @param scheduler The scheduler to use
		 * @return A connectable observable sequence of the same valueClass as the current sequence 
		 */
		function replay(bufferSize : uint = 0, window : uint = 0, scheduler : IScheduler = null) : IConnectableObservable;
		
		/**
		 * Records the output of the source sequence and replays it to future subscribers
		 * @param selector The function to map the connected sequence through 
		 * @param bufferSize The number of values at the end of the sequence to replay, or 0 for all.
		 * @param window The window of time, in milliseconds, in which to replay values from the end of the sequence, or 0 for all.
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */
		function replayAndConnect(selector : Function, bufferSize : uint = 0, window : uint = 0, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Repeats the source sequence a specific number of times 
		 * @param repeatCount The number of times to repeat the sequence
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function repeat(repeatCount : uint = 0) : IObservable;
		
		/**
		 * Repeats the source sequence when an error occurs 
		 * @param retryCount The number of times to retry the sequence in the event of an error
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */
		function retry(retryCount : uint = 0) : IObservable;
		
		/**
		 * Emits the latest value on a time interval from a source sequence 
		 * @param intervalMs The interval of time, in milliseconds, to sample the current value after
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function sample(intervalMs : uint, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Runs calculation functions over every value in the source sequence and emits the value as it is calculated 
		 * @param accumulator The function that accumulates values
		 * @param outputType The class of the returned sequence and return value of accumulator
		 * @param initialValue The value to start with
		 * @return An observable sequence of outputType
		 */
		function scan(accumulator : Function, outputType : Class = null, initialValue : Object = null) : IObservable;
		
		/**
		 * Maps the values from a source sequence through a function to change their value 
		 * @param result The class of the returned sequence and return value of accumulator 
		 * @param selector The function to be executed with each value
		 * @return An observable sequence of valueClass result
		 */
		function select(result : Class, selector:Function):IObservable;
		
		/**
		 * Starts a new sequence for every value in the source sequence and merges their values
		 * @param valueClass The valueClass of the sequences returned by selector
		 * @param selector The function to be executed with each value
		 * @return An observable sequence of valueClass result
		 */		
		function selectMany(valueClass : Class, selector : Function) : IObservable;
		
		/**
		 * Emits the only item from a source sequence, or an error if any other number of values are emitted. 
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function single() : IObservable;
		
		/**
		 * Emits the only item from a source sequence, the default value if no values are emitted, or
		 * an error if more than one value is emitted.  
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function singleOrDefault() : IObservable;
		
		/**
		 * Ignores a set number of values from the start of the source sequence 
		 * @param count The number of values to skip from the start of the sequence
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */
		function skip(count : uint) : IObservable;
		
		/**
		 * Ignores a set number of values from the end of the source sequence 
		 * @param count The number of values to skip from the end of the sequence
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */		
		function skipLast(count : uint) : IObservable;
		
		/**
		 * Ignores values from a source sequence until a value is received from a specified sequence 
		 * @param other The other sequence that will mark the start of values being used from the current sequence 
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */		
		function skipUntil(other : IObservable) : IObservable;
		
		/**
		 * Ignores values from a source sequence until a condition is no longer met
		 * @param predicate The function to be executed as each value is emitted. When this function returns false, values will be used from the current sequence.
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function skipWhile(predicate : Function) : IObservable;
		
		/**
		 * Emits the specified values at the start of a sequence 
		 * @param value The value to emit at the start of the sequence
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */
		function startWith(value : Array, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Returns the summed value of all the elements in the source sequence 
		 * @return An observable sequence of Number
		 */
		function sum() : IObservable;
		
		/**
		 * Takes only the last set number of values from a source sequence 
		 * @param count The number of values to use from the end of the sequence
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */		
		function takeLast(count : uint) : IObservable;
		
		/**
		 * Takes only the first set number of values from a source sequenc
		 * @param count The number of values to use from the start of the sequence
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function take(count : uint) : IObservable;
		
		/**
		 * Takes values from a source sequence until a value is received from a specified sequence  
		 * @param other The other sequence that will mark the end of values being used from the current sequence
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */		
		function takeUntil(other : IObservable) : IObservable;
		
		/**
		 * Takes values from a source sequence until a condition is no longer met 
		 * @param predicate The function to be executed as each value is emitted. When this function returns false, values will no longer be used from the current sequence.
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function takeWhile(predicate : Function) : IObservable;
		
		/**
		 * Limits how often values from a source sequence will be accepted from a source
		 * @param intervalMs The interval of time, in milliseconds, during which only one value from the source sequence will be accepted
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function throttle(dueTimeMs : uint, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Includes, with every value emitted, the amount of time passed since the previous value 
		 * @param scheduler The scheduler to use to determine time
		 * @return An observable sequence of TimeInterval
		 */		
		function timeInterval(scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Raises an error (or a specified sequence) after a certain period of inactivity 
		 * @param timeoutMs The amount of time, in milliseconds, after which to raise an error (or subscribe to other)
		 * @param other The sequence to subscribe to in the event of a timeout. If null, a TimeoutError will be emitted.
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same valueClass as the current sequence 
		 */		
		function timeout(timeoutMs : uint, other : IObservable = null, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Includes, with every value emitted, the timestamp of when the value was emitted from the source 
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of Timestamped 
		 */
		function timestamp(scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Filters out values from a source sequence 
		 * @param predicate The predicate function to execute for each value to determine if it will be include in the output
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function where(predicate : Function) : IObservable;
		
		/**
		 * Merges two sequences through a mapping function while only ever using each value once 
		 * @param resultType The class of the returned sequence and return value of selector
		 * @param rightSource The sequence to combine with the current
		 * @param selector The function to be executed when values are received from both sequences. The return value will be included in the output
		 * @return An observable sequence of resultType
		 */		
		function zip(resultType : Class, rightSource : IObservable, selector : Function) : IObservable;
	}
}