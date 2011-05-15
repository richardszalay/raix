package raix.reactive
{
	import raix.reactive.scheduling.IScheduler;
	import raix.reactive.subjects.IConnectableObservable;
	
	/**
	 * An observable (or "push"), sequence of values that often represent data or events that have not yet occured. 
	 * Sequences can be manipulated, often combining them with other sequences, and then subscribed to 
	 * to receive the output.
	 * 
	 * Chains of sequences are automatically torn down when the sequence completes, errors or is unsubscribed from.
	 */	
	public interface IObservable
	{
		/**
		 * Subscribes to this observable using the supplied functions 
		 * @param onNext Function to be called for every value. Signature is <code>function(payload : T) : void</code>
		 * @param onComplete Optional. Function to be called when the sequence completes. Signature is <code>function():void</code>
		 * @param onError Optional. Function to be called when an error occurs in the sequence. Signature is <code>function(err:Error):void</code>
		 * @return An instance of ICancelable that can be used to unsubscribe at anytime by calling <code>cancel()</code> 
		 */
		function subscribe(onNext : Function, onComplete : Function = null, 
			onError : Function = null) : ICancelable;
		
		/**
		 * Subscribes to this observable using the supplied observer
		 * @return An instance of ICancelable that can be used to unsubscribe at anytime by calling <code>cancel()</code> 
		 */
		function subscribeWith(observer : IObserver) : ICancelable;
		
		/** 
		 * Creates a pattern by combining the current source with right.
		 * 
		 * @param right The other sequence to combine with the pattern.
		 * @return A pattern representing both sequences
		 */
		function and(right : IObservable) : Pattern;
		
		/** 
		 * Runs calculation functions over every value in the source sequence and emits the final result
		 * @param accumulator A function that accumulates the aggregate value: 
		 *     function(accumulate : TAccumulate, element : TElement) : TAccumulate
		 * @param initialValue The value to start with
		 * @return An observable sequence of type TAccumulate
		 */
		function reduce(accumulator : Function, initialValue : Object = null, useInitialValue : Boolean = false) : IObservable;
		
		[Deprecated(replacement="reduce")]
		function aggregate(accumulator : Function, initialValue : Object = null, useInitialValue : Boolean = false) : IObservable;
		
		/**
		 * Determines if the source sequence contains a value that satisfies a condition
		 *  
		 * @param predicate (optional) The predicate that determines if a value in the sequence is valid. 
		 * If null, the returned sequence will emit true if the source sequence contains any values or false if it is empty.
		 * @return An observable sequence of Boolean
		 */		
		function any(predicate : Function = null) : IObservable;
		
		/**
		 * Determines if all values in the source sequence satisfy a condition
		 * @param predicate The predicate that determines if a value in the sequence is valid. 
		 * @return An observable sequence of Boolean
		 */		 
		function all(predicate : Function) : IObservable;
		
		/**
		 * Returns the average value of all the elements in the source sequence
		 * @param valueSelector (optional) The selector function that returns a numeric value from the source value  
		 * @return An observable sequence of TSource values
		 */		
		function average(valueSelector : Function = null):IObservable;
		
		/**
		 * Emits the values from a source sequence in groups of a specific size  
		 * @param count The number of values to buffer
		 * @param skip The number of values to offset after the buffer is emitted.
		 * @return An observable sequence of arrays of the the same type as the current sequence
		 */
		function bufferWithCount(count : uint, skip : uint = 0) : IObservable;
		
		/**
		 * Emits the values from a source sequence in groups of a specific size  
		 * @param count The number of values to buffer
		 * @param skip The number of values to offset after the buffer is emitted.
		 * @return An observable sequence of observable sequences with the same type as the current sequence
		 */
		function windowWithCount(count : uint, skip : uint = 0) : IObservable;
		
		/**
		 * Emits the values from a source sequence in groups of a specific size  
		 * @param timeMs The amount of time to buffer before the values are released
		 * @param timeShiftMs The amount of time to offset after the buffer is emitted
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of Arrays of the same type as the current sequence
		 */		
		function bufferWithTime(timeMs : uint, timeShiftMs : uint = 0, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Emits the values from a source sequence in groups of a specific size  
		 * @param timeMs The amount of time to buffer before the values are released
		 * @param timeShiftMs The amount of time to offset after the buffer is emitted
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of observable sequences with the same type as the current sequence
		 */		
		function windowWithTime(timeMs : uint, timeShiftMs : uint = 0, scheduler : IScheduler = null) : IObservable;

		/**
		 * Emits IObservable sequences containing values received in sized batches or within a timespan, whichever occurs first
		 * @param timeMs The maximum amount of time for a child-sequence to capture values
		 * @param count The maximum amount of values for a child-sequence to capture
		 * @return An observable sequence of observable sequences with the same type as the current sequence
		 */
		function windowWithTimeOrCount(timeMs : uint, count : uint, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Buffers values into an array, with one array for either a maximum period of time or a maximum number 
		 * of values, whichever occurs first
		 * @param timeMs The maximum amount of time to buffer values for
		 * @param count The maximum amount of values to include in a single buffer
		 * @return An observable sequence of observable sequences with the same type as the current sequence
		 */
		function bufferWithTimeOrCount(timeMs : uint, count : uint, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Forces values from a source sequence to be of a specific class
		 * @param valueClass The valueClass of the output sequence
		 * @return An observable sequence of valueClass 
		 */
		function cast(valueClass : Class) : IObservable;
		
		/**
		 * Runs a specific sequence when an error occurs
		 * @param second The sequence to subscribe to when an error occurs
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function catchError(second : IObservable) : IObservable;
		
		/**
		 * Runs a specific sequence, determined at runtime, when an error occurs
		 * @param errorClass The class (and superclass) of error to act on
		 * @param deferFunc The function to execute in the event of an error. 
		 * Signature is <code>function(e : Error) : IObservable</code>
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function catchErrorDefer(errorClass : Class, deferFunc : Function) : IObservable;
		
		/**
		 * Chains together sequences, starting with the current sequence, using selector functions that 
		 * return a sequence for values of the previous.
		 * @param functions An array of functions that accept a value from the previous sequence and 
		 *        return a new sequence:
		 *        function (value : T) : IObservable
		 * @return An observable sequence of the values returned by the sequence returned by the last 
		 * selector in the chain
		 */
		function chain(functions : Array) : IObservable;
		
		/**
		 * Merges two sequences through a mapping function, using the latest value from either source 
		 * @param right The sequence to combine with
		 * @param selector The function that combines values from the two sources. Signature is <code>function(left : this.valueClass, right : right.valueClass) : returnType</code>
		 * @return An observable sequence of returnType 
		 */		
		function combineLatest(right:IObservable, selector:Function):IObservable;
		
		/**
		 * Concatonates multiple sequences by running each sequence as the previous one finishes
		 * @param sources The sequences to concatonate after the current sequence 
		 * @return An observable sequence of the same valueClass as the current sequence
		 */		
		function concat(source:IObservable):IObservable;
		
		/**
		 * Evaluates a new sequence for each value using a selector function and waits for the returned 
		 * sequence to complete before resolving the next sequence 
		 * @param selector Accept a value of the source and returns the IObservable sequence to concatonate:
		 *     function(value:T) : IObservable
		 * @return An IObservable sequence containing the values returned
		 */
		function concatMany(selector : Function) : IObservable
		
		/**
		 * Determines if the source sequence contains a specific value 
		 * @param value The value to check against the sequence
		 * @param comparer The function used to compare values. Default equality will be used if comparer is null.
		 * @return An observable sequence of Boolean
		 */		
		function contains(value : Object, comparer : Function = null) : IObservable
		
		/**
		 * Returns the number of elements in the source sequence 
		 * @return An observable sequence of int
		 */		
		function count() : IObservable;
		
		/**
		 * Delays all values in a sequences by a specified time 
		 * @param delayMs The amount of time, in milliseconds, to delay
		 * @param scheduler The scheduler used to delay the values
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function delay(delayMs : uint, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Converts materialized values back into messages  
		 * @return An observable sequence of valueClass
		 */		
		function dematerialize():IObservable;
		
		/**
		 * Allows custom code to be run when messages arrive without affecting the observer  
		 * @param next The function to execute in the event of a value (onNext)
		 * @param complete The function to execute in the event the sequence completes (onComplete)
		 * @param error The function to execute in the event of an error (onError)
		 * @return An observable sequence of the same type as the current sequence
		 */
		function peek(next:Function, complete:Function = null, error:Function = null):IObservable;
		
		/**
		 * Allows custom code to be run when messages arrive without affecting the observer
		 * @param observer The observer that will receive messages
		 */
		function peekWith(observer : IObserver) : IObservable;
		
		/**
		 * Recursively expands the values in the sequence using a selector function 
		 * @param selector Accepts values and returns an expanded sequence for them:
		 *     function (value : T) : IObservable
		 * @return An observable sequence of all values emitted by any of the sequences
		 */
		function expand(selector : Function) : IObservable;
		
		/**
		 * Executes a function when the sequence completes, errors or is unsubscribed from
		 * @param finallyAction The function to execute in the event the sequence completes or errors
		 * @return An observable sequence of the same type as the current sequence
		 */
		function finallyAction(finallyAction : Function) : IObservable;
		
		/**
		 * Emits the first value in the sequence, or an error if the sequence completes with no values 
		 * @return An observable sequence of the same type as the current sequence 
		 */
		function first() : IObservable;
		
		/**
		 * Emits the first value in the sequence, or a default value if the sequence completes with no values
		 * @return An observable sequence of the same type as the current sequence 
		 */		
		function firstOrDefault() : IObservable;
		
		/**
		 * Combines the current sequence with another, emitting the last values of both after both have completed 
		 * @param right The sequence to subscribe to, along with the current sequence
		 * @param selector The function that accepts the last values of both sequences and returns the output value:
		 *     function(left : TLeft, right : TRight) : TResult 
		 * @return An observable sequence of TResult
		 */		
		function forkJoin(right : IObservable, selector : Function):IObservable;
		
		/**
		 * Combines values from two streams based on the "lifetime" of each value, represented by an IObservable 
		 * selected for each value. All combinations of values from both streams that occur during this "lifetime" window 
		 * are sent to a selector to be combined. The output of this selector is emitted to the output stream  
		 * @param right The right hand side of the join
		 * @param leftWindowSelector A function that will be called for each value from the left ("this") and will 
		 *     return the IObservable that represents the lifetime window of that value:
		 *     function(left:TLeft):IObservable
		 * @param rightWindowSelector A function that will be called for each value from right and will 
		 *     return the IObservable that represents the lifetime window of that value:
		 *     function(right:TRight):IObservable
		 * @param joinSelector A function that will accept "live" left/right value combinations and return a new value. 
		 *     The output of this function will be received by any subscribers:
		 *     function(left : TLeft, right : TRight) : TResult
		 * @return An observable sequence of valueClass resultClass
		 */
		function join(right : IObservable, leftWindowSelector : Function, rightWindowSelector : Function, joinSelector : Function) : IObservable;
		
		/**
		 * Combines values from two streams based on the "lifetime" of each value, represented by an IObservable 
		 * selected for each value. An IObervable set of "right" values are sent with its matching "left" value
		 * to a selector to be combined. The output of this selector is emitted to the output stream  
		 * @param right The right hand side of the join
		 * @param leftWindowSelector A function that will be called for each value from the left ("this") and will 
		 *     return the IObservable that represents the lifetime window of that value:
		 *     function(left:TLeft):IObservable
		 * @param rightWindowSelector A function that will be called for each value from right and will 
		 *     return the IObservable that represents the lifetime window of that value:
		 *     function(right:TRight):IObservable
		 * @param joinSelector A function that will accept "live" left/right value combinations and return a new value. 
		 *     The output of this function will be received by any subscribers:
		 *     function(left : TLeft, rights : IObservable.<TRight>) : TResult
		 * @return An observable sequence of TResult values
		 */
		function groupJoin(right : IObservable, leftWindowSelector : Function, rightWindowSelector : Function, joinSelector : Function) : IObservable;
		
		/**
		 * Groups values by a key
		 * @param keySelector A selector that maps the key from a source value:
		 *     function(value:TValue):TKey
		 * @param elementSelector (optional) A selector that maps the source value to the element value that 
		 *     will be added to the grouped items: function(value:TValue):TElement
		 * @param keyComparer A equality comparer that compares two keys
		 * @return An observable sequence of IGroupedObservable
		 * @see raix.reactive.IGroupedObservable
		 */		
		function groupBy(keySelector : Function, elementSelector : Function = null, keyComparer : Function = null) : IObservable;
		
		/**
		 * Groups values by a key and also provides a lifetime for a grouping
		 * @param keySelector A selector that maps the key from a source value:
		 *     function(value:TValue):TKey
		 * @param durationSelector A selector that returns an observable sequence that will signal 
		 *     the end of the life of a group by emitting a value or completing:
		 *     function(group:IGroupedObservable) : IObservable
		 * @param elementSelector (optional) A selector that maps the source value to the element value that 
		 *     will be added to the grouped items: function(value:TValue):TElement
		 * @param keyComparer A equality comparer that compares two keys
		 * @return An observable sequence of IGroupedObservable
		 * @see raix.reactive.IGroupedObservable
		 */	
		function groupByUntil(keySelector : Function, durationSelector : Function, elementSelector : Function = null,  keyComparer : Function = null) : IObservable;
		
		/**
		 * Hides the source sequence so it cannot be cast back to it’s concrete implementation  
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function asObservable() : IObservable;
		
		/**
		 * Excludes values (calls to IObserver.onNext), emitting only onCompleted and onError 
		 * @return An observable sequence
		 */		
		function ignoreValues() : IObservable;
		
		/**
		 * Filters out consecutive duplicates from a source sequence  
		 * @param comparer (optional) The function used to compare values. Default equality will be used if comparer is null.
		 * function(x:TValue, y:TValue) : Boolean
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function distinctUntilChanged(comparer : Function = null) : IObservable;
		
		/**
		 * Emits the last value in the sequence, or an error if the sequence completes with no values 
		 * @return An observable sequence of the same type as the current sequence 
		 */
		function last() : IObservable;
		
		/**
		 * Emits the last value in the sequence, or the default value if the sequence completes with no values 
		 * @return An observable sequence of the same type as the current sequence
		 */
		function lastOrDefault() : IObservable;
		
		/**
		 * Pipes a composed sequence to be mapped through a function so it can be used multiple times 
		 * @param func The function to send the current sequence through, and return a new sequence 
		 * @return The observable sequence returned by func 
		 */		
		function let(func : Function) : IObservable;
		
		/**
		 * Writes sequence activity out to the trace log with a message describing the sequence 
		 * @param message 
		 */		
		function log(message : String) : IObservable;
		
		/**
		 * Converts all messages (next, complete, error) into values 
		 * @return An observable sequence of rx.Notification
		 */		
		function materialize() : IObservable;
		
		/**
		 * Emits the values from multiple sources in the order that they arrive 
		 * @param sources The other sequences from which the values will be merged with the current sequence
		 * @param scheduler The scheduler to use 
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function merge(source : IObservable):IObservable;
		
		/**
		 * Evaluates a new sequence for each value using a selector function and merges the results 
		 * of the sequence returned by the returned sequence, optionally constraining the number of 
		 * concurrent sequencing.
		 * @param selector Accept a value of the source and returns the IObservable sequence to merge:
		 *     function(value:T) : IObservable
		 * @return An IObservable sequence containing the values returned
		 */
		function mergeMany(selector : Function, concurrent : int = 0) : IObservable
		
		/**
		 * Filters out values from a source sequence that are not of a specific type 
		 * @param valueClass The class (or subsclass) of all values to emit 
		 * @return An observable sequence of valueClass
		 */		
		function ofClass(valueClass : Class) : IObservable;

		/**
		 * Defers messages to subscribers through a scheduler  
		 * @param scheduler The subscriber to send messages to subscribers through
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function observeOn(scheduler : IScheduler) : IObservable;
		
		/**
		 * Defers subscriptions to the source through a scheduler  
		 * @param scheduler The subscriber to schedule subscriptions through
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function subscribeOn(scheduler : IScheduler) : IObservable;
		
		/**
		 * Subscribes down a list of sequence as each one errors or complete 
		 * @param second The sequence to run after the current sequence completes or errors
		 * @param scheduler The scheduler to use to subscribe to the new sequence
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function onErrorResumeNext(second:IObservable, scheduler:IScheduler=null):IObservable; 
		 
		/**
		 * Creates a shared sequence that emits the last value of the source sequence 
		 * @param scheduler The scheduler to use
		 * @return A connectable observable sequence of the same type as the current sequence
		 */
		function prune(scheduler : IScheduler = null) : IConnectableObservable;
		
		/**
		 * Creates a shared sequence that emits the last value of the source sequence, the shared 
		 * sequence will be passed to the selector function when the sequence is subscribed to. 
		 * @param selector The function to map the connected sequence through
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same type as the current sequence
		 */
		function pruneDefer(selector : Function, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Creates a connectable sequence that can be shared by multiple observers  
		 * @return A connectable observable sequence of the same type as the current sequence 
		 */
		function publish() : IConnectableObservable;
		
		/**
		 * Creates a shared sequence that can be used by multiple subscribers, the shared 
		 * sequence will be passed to the selector function when the sequence is subscribed to.
		 * @param selector The function to map the connected sequence through
		 * @return An observable sequence of the same type as the current sequence
		 */		
		function publishDefer(selector : Function) : IObservable;
		
		/**
		 * Creates a connectable sequence that can be shared by multiple observers, using a specific 
		 * subject implementation. 
		 * @param subject The subject that will messages and subscriptions
		 * @return A connectable observable
		 */		
		function multicast(subject : ISubject) : IConnectableObservable;
		
		/**
		 * Creates a connectable sequence that can be shared by multiple observers, using a specific 
		 * subject implementation (determined at subscribe-time. The shared sequence will be passed 
		 * to a selector function when the sequence is subscribed to.
		 * @param subjectSelector Determines the subject to be used when the sequence is subscribed to
		 * @param selector Accepts the yet-to-be-connected connectable sequence and returns the sequence 
		 * that will supply values to the subject
		 * @return An observable sequence that contains messages from the selector-returned sequence, piped 
		 * through the subject supplied by subjectSelector
		 */		
		function multicastDefer(subjectSelector : Function, selector : Function) : IObservable
		
		/**
		 * Removes time interval information added with timeInterval  
		 * @return An observable sequence of the original values (without being wrapped in TimeInterval)
		 */		
		function removeTimeInterval() : IObservable;
		
		/**
		 * Removes timestamp information added with timestamp  
		 * @return An observable sequence of the original values (without being wrapped in TimeStamp)
		 */
		function removeTimestamp() : IObservable;
		
		/**
		 * Records the output of the source sequence and replays it to future subscribers 
		 * @param bufferSize The number of values at the end of the sequence to replay, or 0 for all.
		 * @param windowMs The window of time, in milliseconds, in which to replay values from the end of the sequence, or 0 for all.
		 * @param scheduler The scheduler to use
		 * @return A connectable observable sequence of the same valueClass as the current sequence 
		 */
		function replay(bufferSize : uint = 0, windowMs : uint = 0, scheduler : IScheduler = null) : IConnectableObservable;
		
		/**
		 * Creates a shared sequence that replays values to future subscrubers, the shared 
		 * sequence will be passed to the selector function when the sequence is subscribed to
		 * @param selector The function to map the connected sequence through 
		 * @param bufferSize The number of values at the end of the sequence to replay, or 0 for all.
		 * @param windowMs The window of time, in milliseconds, in which to replay values from the end of the sequence, or 0 for all.
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same type as the current sequence 
		 */
		function replayDefer(selector : Function, bufferSize : uint = 0, windowMs : uint = 0, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Repeats the source sequence a specific number of times 
		 * @param repeatCount The number of times to repeat the sequence or 0 to repeat indefinitely
		 * @return An observable sequence of the same type as the current sequence
		 */
		function repeat(repeatCount : uint = 0) : IObservable;
		
		/**
		 * Repeats the source sequence when an error occurs 
		 * @param retryCount The number of times to retry the sequence in the event of an error, 
		 * or 0 to retry indefinitely
		 * @return An observable sequence of the same type as the current sequence 
		 */
		function retry(retryCount : uint = 0) : IObservable;
		
		/**
		 * Emits the latest value on a time interval from a source sequence 
		 * @param intervalMs The interval of time, in milliseconds, to sample the current value after
		 * @param scheduler The scheduler to use
		 * @return An observable sequence of the same type as the current sequence
		 */
		function sample(intervalMs : uint, scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Runs calculation functions over every value in the source sequence and emits the value as it is calculated 
		 * @param accumulator The function that accumulates values
		 * @param initialValue The value to start with
		 * @return An observable sequence of valueClass
		 */
		function scan(accumulator : Function, initialValue : Object = null, useInitialValue : Boolean = false) : IObservable;
		
		/**
		 * Maps the values from a source sequence through a function to change their value  
		 * @param selector The function to be executed with each value
		 * @return An observable sequence of valueClass result
		 */
		function map(selector:Function):IObservable;
		
		/**
		 * Starts a new sequence, returned by selector, for every value in the source sequence and merges their values
		 * @param valueClass The valueClass of the sequences returned by selector
		 * @param selector The function that maps values to new observable sequences that will 
		 * be merged in the result set: function(value:TValue):IObservable
		 * @return An observable sequence containing the values emitted from the child observable sequences
		 */		
		function mapMany(selector : Function) : IObservable;
		
		[Deprecated(replacement="mapMany")]
		/**
		 * Starts a new sequence, returned by selector, for every value in the source sequence and merges their values
		 * @param selector The function to be executed with each value
		 * @return An observable sequence of valueClass result
		 */
		function selectMany(selector : Function) : IObservable;
		
		/**
		 * Determines whether two observable sequences are equal 
		 * @param other The observable sequence to compare to
		 * @param valueComparer The equality comparer to compare values between sequences:
		 * function(value : TValue, otherValue : TOther) : Boolean
		 * @return An observable sequence that will emit a single boolean value once equality has been determined
		 */		
		function sequenceEqual(other : IObservable, valueComparer : Function = null) : IObservable;
		
		/**
		 * Emits the only item from a source sequence, or an error if any other number of values are emitted. 
		 * @return An observable sequence
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
		 * @param value That value, converted to an IObservable using toObservable, that will 
		 * be emitted at the start of the current sequence
		 * @return An observable sequence of the same valueClass as the current sequence
		 * @see raix.reactive.toObservable 
		 */
		function startWith(value : *) : IObservable;
		
		/**
		 * Like selectMany, starts a new sequence for every value in the source 
		 * sequence but cancels the previous sequence each time.
		 * @return An observable sequence of valueClass
		 */
		function switchMany(selector : Function) : IObservable;
		
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
		 * Creates a Plan from this sequence, by supplying a 
		 * valueClass and a mappingFunction for the values from each 
		 * sequence in this Pattern 
		 * @param thenFunction The function that will accept this sequence as an argument
		 * @return A Plan that can be used with Observable.join
		 */		
		function then(thenFunction : Function) : Plan;
		
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
		 * Raises an error (or subscribes a specified sequence) after a certain period of inactivity 
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
		function filter(predicate : Function) : IObservable;
		
		/**
		 * Delivers all the results as a single array when the source completes 
		 * @return An observable sequence of Array that will contain the same valueClass as the current sequence
		 */
		function toArray():IObservable;
		
		/**
		 * Splits values into child-observable windows which are closed by the caller
		 * @param windowClosingSelector Returns an IObservable that will emit a value or complete to indicate that the active 
		 * 		  window has closed. Called on subscription and immediately after each window closes. 
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function window(windowClosingSelector : Function) : IObservable;
		
		/**
		 * Emits values into child "window" observable sequences, which are opened and closed by the caller.
		 * @param windowOpenings Signals the start of a new window by emitting a value
		 * @param windowClosingSelector Returns an observable sequence that will signal the close of a window:
		 * function (window : IObservable) : IObservable 
		 * @return An observable sequence of the same valueClass as the current sequence
		 */
		function multiWindow(windowOpenings : IObservable, windowClosingSelector : Function) : IObservable
		
		/**
		 * Merges two sequences through a mapping function while only ever using each value once 
		 * @param rightSource The sequence to combine with the current
		 * @param selector The function to be executed when values are received from both sequences. The return value will be included in the output
		 * @return An observable sequence of valueClass
		 */
		function zip(rightSource : IObservable, selector : Function) : IObservable;
	}
}