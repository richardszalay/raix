package raix.interactive
{
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.scheduling.IScheduler;
	
	public interface IEnumerable extends ICancelable
	{
		function getEnumerator() : IEnumerator;
		
		function any(predicate : Function = null) : Boolean;
		function all(predicate : Function) : Boolean;
		
		function defaultIfEmpty(defaultValue : Object = null) : IEnumerable;
		
		function first(predicate : Function = null) : Object;
		function firstOrDefault(defaultValue : Object = null, predicate : Function = null) : Object;
		
		function single(predicate : Function = null) : Object;
		function singleOrDefault(defaultValue : Object = null, predicate : Function = null) : Object;

		function last(predicate : Function = null) : Object;
		function lastOrDefault(defaultValue : Object = null, predicate : Function = null) : Object;
		
		function aggregate(seed : Object, accumulator : Function, resultSelector : Function = null) : Object;
		function scan(seed : Object, accumulator : Function, resultSelector : Function = null) : IEnumerable;
		
		function distinct(hashSelector : Function = null) : IEnumerable;
		
		function union(right : IEnumerable, hashSelector : Function = null) : IEnumerable;
		function intersect(right : IEnumerable, hashSelector : Function = null) : IEnumerable;
		function except(right : IEnumerable, hashSelector : Function = null) : IEnumerable;
		
		function toLookup(keySelector : Function, elementSelector : Function = null, keyHashSelector : Function = null) : ILookup;
		function join(inner : IEnumerable, outerKeySelector : Function, innerKeySelector : Function, resultSelector : Function, keyHashSelector : Function = null) : IEnumerable;
		function groupJoin(inner : IEnumerable, outerKeySelector : Function, innerKeySelector : Function, resultSelector : Function, keyHashSelector : Function = null) : IEnumerable;		
		function groupBy(keySelector : Function, elementSelector : Function = null, keyHashSelector : Function = null) : IEnumerable;
		
		function take(count : uint) : IEnumerable; 
		function takeLast(count : uint) : IEnumerable; 
		function takeWhile(predicate : Function) : IEnumerable;
		
		function skip(count : uint) : IEnumerable; 
		function skipLast(count : uint) : IEnumerable; 
		function skipWhile(predicate : Function) : IEnumerable; 
		
		function concat(second : IEnumerable) : IEnumerable;	
		
		function map(selector : Function) : IEnumerable;
		function mapMany(collectionSelector : Function, resultSelector : Function = null) : IEnumerable;
		
		function filter(predicate : Function) : IEnumerable;
		function ofType(cls : Class) : IEnumerable;
		
		function zip(right : IEnumerable, resultSelector : Function) : IEnumerable;
		function sequenceEqual(right : IEnumerable, comparer : Function = null) : Boolean;
		
		function repeat(count : uint = 0) : IEnumerable;
		
		function count() : uint;
		
		function toObservable(scheduler : IScheduler = null) : IObservable;
		function toArray() : Array;
	}
}