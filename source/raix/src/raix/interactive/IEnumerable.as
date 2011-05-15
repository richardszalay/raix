package raix.interactive
{
	import flash.utils.Dictionary;
	
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.scheduling.IScheduler;
	
	/**
	 * Represents a collection of values which can be enumerated using foreach, but 
	 * does not support random access
	 */	
	public interface IEnumerable extends ICancelable
	{
		/**
		 * Returns an object that can be used to enumerate through this sequence. Access to this method 
		 * is not generally required as IEnumerable sequence 
		 * @return An IEnumerator 
		 */		
		function getEnumerator() : IEnumerator;
		
		/**
		 * Determines if the predicate argument function returns true for any 
		 * item in the sequence. If no function is supplied, true will be returned 
		 * if the sequence contains any values 
		 * 
		 * Uses immediate execution and stops enumerating when a match is found. 
		 * @param predicate (optional) A function in the format: function(element : TElement) : Boolean 
		 * @return true if a matching value is found or if predicate is null and the
		 *              sequence contains any values; false otherwise
		 */		
		function any(predicate : Function = null) : Boolean;
		
		/**
		 * Determines if the every value in the source sequence matches a predicate 
		 * function.
		 * 
		 * Uses immediate execution and stops enumerating when a negative match is found.
		 * @param predicate (optional) A function in the format: function(element : TElement) : Boolean
		 * @return true if the sequence is empty or all the values in the sequence match the predicate; 
		 *         false otherwise
		 */		
		function all(predicate : Function) : Boolean;
		
		/**
		 * Determines if the source sequence contains a specific value, optionally 
		 * using an equalityComparer function.
		 * 
		 * Uses immediate execution and stops enumerating when a match is found
		 * @param value The value to be compared
		 * @param equalityComparer (optional) A function to compare two 
		 *        values: function(x : TElement, y : TValue) : Boolean 
		 * @return true if a match was found; false otherwise
		 */		
		function contains(value : Object, equalityComparer : Function = null) : Boolean;
		
		/**
		 * Returns a new sequence that will return the given defaultValue 
		 * 
		 * Uses deferred execution
		 * @param defaultValue (optional) The default value to use if the sequence is empty. 
		 *        If not supplied, the value will be converted from null (int = 0, boolean = false, etc)
		 * @return A new IEnumerable sequence
		 */				
		function defaultIfEmpty(defaultValue : Object = null) : IEnumerable;
		
		/**
		 * Returns the element at the given index or throws an IllegalOperationError if 
		 * the sequence does not contain that many elements. 
		 * @param index The zero-based index of the value to return
		 * @return The value at index
		 */
		function elementAt(index : int) : Object;
		
		/**
		 * Returns the element at the given index or a default value if 
		 * the sequence does not contain that many elements. 
		 * @param index The zero-based index of the value to return
		 * @defaultValue The value to return if the sequence does not contain (index+1) elements
		 * @return The value at index
		 */
		function elementAtOrDefault(index : int, defaultValue : Object = null) : Object;
		
		/**
		 * Returns the first element in the sequence or throws an IllegalOperationError 
		 * if the sequence is empty. If predicate is supplied, the first value to match the 
		 * predicate will be returned with an IllegalOperationError being thrown if no 
		 * values match the predicate
		 * @param predicate (optional) A predicate used to match values: function(element : TElement) : Boolean
		 * @return The first value in the sequence or the first value in the sequence that matches predicate
		 */
		function first(predicate : Function = null) : Object;
		
		/**
		 * Returns the first element in the sequence or returns a default value 
		 * if the sequence is empty. If predicate is supplied, the first value to match the 
		 * predicate will be returned with the default value being returned if no 
		 * values match the predicate
		 * @param predicate (optional) A predicate used to match values: function(element : TElement) : Boolean
		 * @return The first matching value in the sequence or defaultValue
		 */
		function firstOrDefault(defaultValue : Object = null, predicate : Function = null) : Object;
		
		/**
		 * Returns the first element in the sequence or throws an IllegalOperationError 
		 * if the sequence does not contain exactly one value. If predicate is supplied, 
		 * the first value to match the predicate will be returned with an IllegalOperationError 
		 * being thrown if the sequence does not contain exactly one match
		 * @param predicate (optional) A predicate used to match values: function(element : TElement) : Boolean
		 * @return The first value in the sequence or the first value in the sequence that matches predicate
		 */
		function single(predicate : Function = null) : Object;
		
		/**
		 * Returns the first element in the sequence or throws an IllegalOperationError 
		 * if the sequence does contains multiple values, but returns a default value if 
		 * the sequence returns no values. If predicate is supplied, the first value to match 
		 * the predicate will be returned with an IllegalOperationError 
		 * being thrown if the sequence contains more than one match and a default value being 
		 * returned if no matches are found
		 * @param defaultValue A defaultValue to 
		 * @param predicate (optional) A predicate used to match values: function(element : TElement) : Boolean
		 * @return The first matching value in the sequence or defaultValue
		 */
		function singleOrDefault(defaultValue : Object = null, predicate : Function = null) : Object;

		/**
		 * Returns the last element in the sequence or throws an IllegalOperationError 
		 * if the sequence is empty. If predicate is supplied, the last value to match the 
		 * predicate will be returned with an IllegalOperationError being thrown if no 
		 * values match the predicate
		 * @param predicate (optional) A predicate used to match values: function(element : TElement) : Boolean
		 * @return The last matching value
		 */
		function last(predicate : Function = null) : Object;
		
		/**
		 * Returns the last element in the sequence or returns a default value 
		 * if the sequence is empty. If predicate is supplied, the last value to match the 
		 * predicate will be returned with the default value being returned if no 
		 * values match the predicate
		 * @param predicate (optional) A predicate used to match values: function(element : TElement) : Boolean
		 * @return The last matching value in the sequence or defaultValue
		 */
		function lastOrDefault(defaultValue : Object = null, predicate : Function = null) : Object;
		
		/**
		 * Aggregates values in a sequence using functions passed as arguments.
		 * 
		 * Accumulates a value, starting with seed, by calling accumulator for each value in the source 
		 * sequence and using the return value as the new accumulated value. When the sequence completes, 
		 * the accumulated value is (optonally) mapped through resultSelector before being returned.
		 * @param seed The initial value for the accumulation
		 * @param accumulator A function that returns the new accumulated value: 
		 *        function(accumulate : TAccumulate, element : TElement) : TAccumulate
		 * @param resultSelector (optional) A function that maps the final accumulate value before being returned
		 * @return The return value of resultSelector (if supplied) or the final accumulate value if 
		 *         resultSelector is not supplied
		 */
		function reduce(seed : Object, accumulator : Function, resultSelector : Function = null) : Object;
		
		/**
		 * Returns a sequence that aggregates values using functions passed as arguments, using 
		 * deferred execution and returning the values accumulated values as they are returned.
		 * 
		 * Accumulates a value, starting with seed, by calling accumulator for each value in the 
		 * source sequence and using the return value as the new accumulated value. Each time  
		 * a new value is accumulated, the accumulated value is (optonally) mapped through 
		 * resultSelector before being returned.
		 * @param seed The initial value for the accumulation
		 * @param accumulator A function that returns the new accumulated value: 
		 *        function(accumulate : TAccumulate, element : TElement) : TAccumulate
		 * @param resultSelector (optional) A function that maps the final accumulate value before being returned
		 * @return A sequence of type TAccumulate that can be enumerated
		 */
		function scan(seed : Object, accumulator : Function, resultSelector : Function = null) : IEnumerable;
		
		/**
		 * Returns the total numeric value of every value in the sequence 
		 * @param valueSelector (optional) If specified, can be used to specify the numeric 
		 *        value for each element in the sequence 
		 * @return The summed values of each element in the sequence
		 */
		function sum(valueSelector : Function = null) : Number;
		
		/**
		 * Retrieves the minimum element in the sequence. Throws an IllegalOperationError 
		 * if the sequence is empty
		 * 
		 * If the comparison value (either the original element or the value returned by valueSelector)
		 * cannot be natively ordered (ie. is not String, u/int or Number), a comparer should be supplied 
		 * to compare the values
		 * @param valueSelector (optional) If specified, determines the value to be 
		 *        compared for each element in the sequence: function(element : TElement) : TValue
		 * @param comparer (optional) If specified, compares the value (either element 
		 *        value or the value returned by valueSelector): 
		 *        function(value : TValue) : int
		 * @return The sequence element deemed to be the minimum value
		 */
		function min(valueSelector : Function = null, comparer : Function = null) : Object;
		
		/**
		 * Retrieves the maximum element in the sequence. Throws an IllegalOperationError 
		 * if the sequence is empty.
		 * 
		 * If the comparison value (either the original element or the value returned by valueSelector)
		 * cannot be natively ordered (ie. is not String, u/int or Number), a comparer should be supplied 
		 * to compare the values
		 * @param valueSelector (optional) If specified, determines the value to be 
		 *        compared for each element in the sequence: function(element : TElement) : TValue
		 * @param comparer (optional) If specified, compares the value (either element 
		 *        value or the value returned by valueSelector): 
		 *        function(value : TValue) : int
		 * @return The sequence element deemed to be the maximum value
		 */
		function max(valueSelector : Function = null, comparer : Function = null) : Object;
		
		/**
		 * Retrieves the average value in the sequence. Throws an IllegalOperationError 
		 * if the sequence is empty.
		 * @param valueSelector (optional) If specified, determines the numeric value of the element 
		 * @return The average value of the sequence
		 */		
		function average(valueSelector : Function = null) : Number;		
		
		/**
		 * Returns a new sequence that only contains the unique values in the original sequence.
		 * 
		 * If the sequence contains values that are not natively comparable (String, u/int, Number, Boolean),
		 * a hashSelector should be specified to return a value that is. An example of this would be to return 
		 * the ID property of an entity.
		 * 
		 * Uses deferred execution
		 * @param hashSelector (optional) If specified, returns a unique value for the element:
		 *        function(element : TElement) : THash
		 * @return A new sequence that contains the distinct values of the original sequence
		 */		
		function distinct(hashSelector : Function = null) : IEnumerable;
		
		/**
		 * Returns a new sequence that contains the unique values across two sequences
		 * 
		 * @param right The right side of the union. Can be any value that can be converted 
		 *              to an IEnumerable using toEnumerable
		 * @param hashSelector (optional) If specified, returns a unique value for the element:
		 *                     function(element : TElement) : THash
		 * @return A new sequence containing the distinct values across both sequences 
		 * @see raix.interactive.toEnumerable
		 */		
		function union(right : *, hashSelector : Function = null) : IEnumerable;
		
		/**
		 * Returns a new sequence that contains only the values contained in both sequences
		 * 
		 * @param right The right side of the intersection. Can be any value that can be converted 
		 *              to an IEnumerable using toEnumerable
		 * @param hashSelector (optional) If specified, returns a unique value for the element:
		 *                     function(element : TElement) : THash
		 * @return A new sequence containing the unique values contained in both sequence 
		 * @see raix.interactive.toEnumerable
		 */
		function intersect(right : *, hashSelector : Function = null) : IEnumerable;
		
		/**
		 * Returns a new sequence that contains the values in the source sequence that 
		 * do not exist in the supplied sequence
		 * 
		 * @param right The right side of the except. Can be any value that can be converted 
		 *              to an IEnumerable using toEnumerable
		 * @param hashSelector (optional) If specified, returns a unique value for the element:
		 *                     function(element : TElement) : THash
		 * @return A new sequence containing the values contained in the source sequence but 
		 *         not the "right" sequence 
		 * @see raix.interactive.toEnumerable
		 */
		function except(right : *, hashSelector : Function = null) : IEnumerable;
		
		/**
		 * Converts the sequence to an ILookup, which is simiular to a Dictionary with the following 
		 * differences:
		 * 
		 * <ul>
		 * <li>Supports null keys</li>
		 * <li>Returns an empty sequence for requests for keys that do not exist</li>
		 * </ul>
		 * 
		 * Uses immediate execution
		 * 
		 * @param keySelector Retrieves the key for each element in the sequence
		 * @param elementSelector (optional) If specified, provides the "values"  
		 *     in the lookup. If not specified, the original element will be used
		 * @param keyHashSelector (optional) If the value returned by keySelector is not natively 
		 *        comparable (ie. String, u/int, Number, Boolean), keyHashSelector can be used to 
		 *        provide comparable values for the keys: function(key : TKey) : THash
		 * @return An ILookup
		 */
		function toLookup(keySelector : Function, elementSelector : Function = null, keyHashSelector : Function = null) : ILookup;
		
		/**
		 * Converts the sequence to a Dictionary. Uses immediate execution
		 * 
		 * @param keySelector Retrieves the key for each element in the sequence
		 * @param elementSelector (optional) If specified, provides the "values"  
		 *     in the lookup. If not specified, the original element will be used
		 * @return A Dictionary
		 */
		function toDictionary(keySelector : Function, elementSelector : Function = null) : Dictionary;
		
		/**
		 * Correlates the elements of two sequences based on keys.
		 * 
		 * Uses immediate execution on the inner sequence, uses deferred executino on the outer (source) 
		 * sequence
		 * 
		 * @param inner The sequence to join to the first sequence. Can be any value that can be converted 
		 *     to an IEnumerable using toEnumerable
		 * @param outerKeySelector Retrieves the key from values in the outer (source) sequence:
		 *     function(element : TOuterElement) : TKey 
		 * @param innerKeySelector Retrieves the key from values in the inner sequence:
		 *     function(element : TInnerElement) : TKey
		 * @param resultSelector Creates a result element from two matching elements:
		 *     function(outer : TOuterElement, inner : TInnerElement) : TResult
		 * @param keyHashSelector (optional) Returns a natively comparable value for a key:
		 *     function(key : TKey) : THash
		 * @return A sequence that has elements of type TResult that are obtained by joining outer and inner
		 *     sequences.
		 * @see raix.interactive.toEnumerable
		 */
		function join(inner : IEnumerable, outerKeySelector : Function, innerKeySelector : Function, resultSelector : Function, keyHashSelector : Function = null) : IEnumerable;
		
		/**
		 * Correlates the elements of two sequences based on keys and groups the results
		 * 
		 * Uses immediate execution on the inner sequence, uses deferred executino on the outer (source) 
		 * sequence
		 * 
		 * @param inner The sequence to join to the first sequence. Can be any value that can be converted 
		 *     to an IEnumerable using toEnumerable
		 * @param outerKeySelector Retrieves the key from values in the outer (source) sequence:
		 *     function(element : TOuterElement) : TKey 
		 * @param innerKeySelector Retrieves the key from values in the inner sequence:
		 *     function(element : TInnerElement) : TKey
		 * @param resultSelector Creates a result element from the source sequence and a sequnce of 
		 *     matching values from the inner sequence:
		 *     function(outer : TOuterElement, inner : IEnumerable.&lt;TInnerElement&rt;) : TResult
		 * @param keyHashSelector (optional) Returns a natively comparable value for a key:
		 *     function(key : TKey) : THash
		 * @return A sequence that has elements of type TResult that are obtained by joining outer and inner
		 *     sequences.
		 * @see raix.interactive.toEnumerable
		 */
		function groupJoin(inner : IEnumerable, outerKeySelector : Function, innerKeySelector : Function, resultSelector : Function, keyHashSelector : Function = null) : IEnumerable;
		
		/**
		 * Groups elements of a sequence using a key selector function
		 * @param keySelector Retrieves the key for a value in the sequence:
		 *     function(source : TSource) : TKey
		 * @param elementSelector (optional) If specified, maps the source element to an element 
		 *     to place in the grouping: function(source : TSource) : TElement
		 * @param keyHashSelector (optional) If specified, returns a natively comparable value
		 *     for a key in the sequence: function(key : TKey) : THash
		 * @return A sequence that has elements of type IGrouping, where each IGrouping is a sequence 
		 *     of values of type TElement and a key
		 */		
		function groupBy(keySelector : Function, elementSelector : Function = null, keyHashSelector : Function = null) : IEnumerable;
		
		/**
		 * Returns a new sequence that includes a maximum number of elements from the first sequence 
		 * @param count The number of elements to take from the source sequence
		 * @return A new sequence containing values of the same type as the source sequence
		 */
		function take(count : uint) : IEnumerable;
		
		/**
		 * Returns a new sequence that includes a maximum number of elements to take from 
		 * the end of the first sequence 
		 * @param count The number of elements to take from the end of source sequence
		 * @return A new sequence containing values of the same type as the source sequence
		 */
		function takeLast(count : uint) : IEnumerable;
		
		/**
		 * Returns a new sequence that includes values from the source sequence 
		 * until a specified predicate returns false, at which point the sequence will end 
		 * @param predicate A function that determines whether values should still be taken 
		 *     from the source sequence: function(element:TElement) : Boolean 
		 * @return A new sequence containing values of the same type as the source sequence
		 */
		function takeWhile(predicate : Function) : IEnumerable;
		
		/**
		 * Returns a new sequence that excludes the specified number of values from 
		 * the start of the source sequence 
		 * @param count The number of elements to skip from the source sequence
		 * @return A new sequence containing values of the same type as the source sequence
		 */
		function skip(count : uint) : IEnumerable; 
		
		/**
		 * Returns a new sequence that excludes the specified number of values from 
		 * the end of the source sequence 
		 * @param count The number of elements to skip from the end of source sequence
		 * @return A new sequence containing values of the same type as the source sequence
		 */
		function skipLast(count : uint) : IEnumerable;
		
		/**
		 * Returns a new sequence that skips values from the source sequence 
		 * until a specified predicate returns false, at which point values will be 
		 * returned from the rest of sequence 
		 * @param predicate A function that determines whether values should still be skipped 
		 *     from the source sequence: function(element:TElement) : Boolean 
		 * @return A new sequence containing values of the same type as the source sequence
		 */
		function skipWhile(predicate : Function) : IEnumerable; 
		
		/**
		 * Reverses the values in the source sequence
		 * @return A new sequence containing the reversed values of the source sequence
		 */		
		function reverse() : IEnumerable; 
		
		/**
		 * Returns a new sequence that will seemlessly enumerate a second sequence after 
		 * the first sequence completes
		 * @param second The sequence to enumerate after the first sequence
		 * @return A new sequence that contains the values from the first and second sequence, in order
		 */		
		function concat(second : IEnumerable) : IEnumerable;	
		
		/**
		 * Projects (converts) values using a selector function. Uses deferred execution
		 * @param selector Projects the values from the source sequence: 
		 *     function(element : TElement) : TResult
		 * @return A new sequence that contains the projected values of type TResult
		 */		
		function map(selector : Function) : IEnumerable;
		
		/**
		 * Maps a sequence for each value in the source sequence and concatonates the results into 
		 * a single sequence. Uses deferred execution.
		 * 
		 * @param collectionSelector A function to retrieve the sequence for a value in the source sequence: 
		 *     function(element : TElement) : IEnumerable.&lt;TCollection>
		 * @param resultSelector (optional) A function that creates a result element from each source element 
		 *     and each of its enumerated collection values: 
		 *     function(element : TElement, value : TCollection) : TResult
		 * @return A sequence that contains values of type TResult if resultSelector is specified, 
		 *     or TCollection if it is not.
		 */		
		function mapMany(collectionSelector : Function, resultSelector : Function = null) : IEnumerable;
		
		/**
		 * Filters the source sequence based on a predicate function. Uses deferred execution.
		 * @param predicate A function that determines which elements should appear in the result:
		 *     function(element : TElement) : Boolean
		 * @return A sequence that contains values from the source sequence for which predicate returned true
		 */		
		function filter(predicate : Function) : IEnumerable;
		
		/**
		 * Filters values from a sequence based on their type
		 * @param cls A class on which to filter values from the source sequence.
		 * @return A sequence that contains only elements from the source sequence that are of type 
		 *     cls (or a subclass)
		 */		
		function ofType(cls : Class) : IEnumerable;
		
		/**
		 * Pairs values from two sequences in order and uses a selector function to project the results
		 * @param right The sequence to pair with the left (source) sequence
		 * @param resultSelector A function to map values from the left and right sequences:
		 *     function(left : TLeft, right : TRight) : TResult
		 * @return A sequence containing values of type TResult
		 */		
		function zip(right : IEnumerable, resultSelector : Function) : IEnumerable;
		
		/**
		 * Determines whether two sequences are equal. Uses immediate execution 
		 * 
		 * @param right Ths sequence to compare to the source
		 * @param comparer A function that will determine equality between left and right values:
		 *     function(left : TLeft, right : TRight) : Boolean
		 * @return true if the sequences are of equal length and all of their values are equal
		 */		
		function sequenceEqual(right : IEnumerable, comparer : Function = null) : Boolean;
		
		/**
		 * Repeats the source sequence a specified number of times 
		 * @param count (optional) The number of times to repeat the sequence. If 0, the 
		 *     sequence will be repeated indefinately
		 * @return A sequence containing values of the same type as the source
		 */		
		function repeat(count : uint = 0) : IEnumerable;
		
		/**
		 * Orders the values in the source sequence in ascending order
		 * @param keySelector A function that retrieves the key used to order the values in the source sequence:
		 *     function(element : TElement) : TKey
		 * @param comparer (optional) A function that compares key values. The return value should follow rules of 
		 *     the compareFunction in Array.sort: function(x : TKey, y : TKey) : int
		 * @return An IOrderedObservable that can be enumerated or further ordered using methods 
		 *     available on IOrderedObservable
		 * @see raix.interactive.IOrderedObservable
		 */
		function orderBy(keySelector : Function, comparer : Function = null) : IOrderedEnumerable;
		
		/**
		 * Orders the values in the source sequence in descending order
		 * @param keySelector A function that retrieves the key used to order the values in the source sequence:
		 *     function(element : TElement) : TKey
		 * @param comparer (optional) A function that compares key values. The return value should follow rules of 
		 *     the compareFunction in Array.sort: function(x : TKey, y : TKey) : int
		 * @return An IOrderedObservable that can be enumerated or further ordered using methods 
		 *     available on IOrderedObservable
		 * @see raix.interactive.IOrderedObservable
		 */
		function orderByDescending(keySelector : Function, comparer : Function = null) : IOrderedEnumerable;
		
		/**
		 * Determines the number of elements in the sequence. Uses immediate execution.
		 * @return The number of elements in the sequence
		 */		
		function count() : uint;
		
		/**
		 * Converts the interactive sequence to an observable sequence, optionally using a scheduler 
		 * @param scheduler (optional) The scheduler to use to distribute the values. Defaults to 
		 *     Scheduler.asynchronous
		 * @return An observable sequence that contains values of the same type as the source sequence
		 */		
		function toObservable(scheduler : IScheduler = null) : IObservable;
		
		/**
		 * Retrieves an array containing all the values in the sequence 
		 * @return An Array containing values of the same type as the source sequence
		 */
		function toArray() : Array;
	}
}