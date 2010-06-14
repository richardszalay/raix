package rx
{
	import rx.scheduling.IScheduler;
	import rx.subjects.IConnectableObservable;
	
	public interface IObservable
	{
		function get type() : Class;
		
		/**
		 * Subscribes to this observable using the supplied functions 
		 * @param onNext Function to be called for every payload. Signature is function(payload : T) : void
		 * @param onComplete Optional. Function to be called when the sequence completes. Signature is function():void
		 * @param onError Optional. Function to be called when an error occurs in the sequence. Signature is function(err:Error):void
		 * @return An instance of ISubscription that can be used to unsubscribe at anytime by calling unsubscribe() 
		 */
		function subscribeFunc(onNext : Function, onComplete : Function = null, 
			onError : Function = null) : ICancelable;
		
		/**
		 * Subscribes to this observable using the supplied observer 
		 * @param scheduler Optional. The schduler to use
		 * @return An instance of ISubscription that can be used to unsubscribe at anytime by calling unsubscribe() 
		 */
		function subscribe(observer : IObserver) : ICancelable;
		
		function and(right : IObservable) : Pattern;
		
		function aggregate(accumulator : Function, outputType : Class = null, initialValue : Object = null) : IObservable;
		
		function any(predicate : Function = null) : IObservable;
		
		function all(predicate : Function) : IObservable;
		
		function asynchronous() : IObservable;
		
		function average():IObservable;
		
		function bufferWithCount(count : uint, skip : uint = 0) : IObservable;
		
		function bufferWithTime(timeMs : uint, timeShiftMs : uint = 0, scheduler : IScheduler = null) : IObservable;
		
		function cast(type : Class) : IObservable;
		
		function catchError(second : IObservable) : IObservable;
		
		function catchErrorDefered(errorType : Class, deferFunc : Function) : IObservable;
		
		function combineLatest(returnType : Class, right:IObservable, selector:Function):IObservable;
		
		function concat(sources : Array/*.<IObservable>*/) : IObservable;
		
		function contains(value : Object, comparer : Function = null) : IObservable
		
		function count() : IObservable;
		
		// static create(subscribe : Function) : IObservable;

		function delay(delayMs : uint, scheduler : IScheduler = null) : IObservable;
		
		// Not sure if this makes sense
		//function delayUntil(dt : Date, scheduler : IScheduler = null) : IObservable;
		
		function dematerialize(type : Class):IObservable;
		
		function doAction(next:Function, complete:Function = null, error:Function = null):IObservable;
		
		function finallyAction(finallyAction : Function) : IObservable;
		
		function first() : IObservable;
		
		function firstOrDefault() : IObservable;
		
		function forkJoin(resultType : Class, right : IObservable, selector : Function):IObservable;
		
		function asObservable() : IObservable;
		
		function distinctUntilChanged(comparer : Function = null) : IObservable;
		
		function last() : IObservable;
		function lastOrDefault() : IObservable;
		
		function latest() : Array;
		
		function let(func : Function) : IObservable;
		
		function materialize() : IObservable;
		
		function merge(sources : IObservable, scheduler : IScheduler = null) : IObservable;
		
		function mostRecent(initialValue : Object) : IObservable;
		
		function ofType(type : Class) : IObservable;

		function observeOn(scheduler : IScheduler) : IObservable;
		
		function onErrorResumeNext(second:IObservable, scheduler:IScheduler=null):IObservable; 
		 
		function prune(scheduler : IScheduler = null) : IConnectableObservable;
		
		function pruneAndConnect(selector : Function, scheduler : IScheduler = null) : IObservable;
		
		function publish() : IConnectableObservable;
		
		function publishAndConnect(selector : Function) : IObservable;
		
		function removeTimeInterval(type : Class) : IObservable;
		function removeTimestamp(type : Class) : IObservable;
		
		function replay(bufferSize : uint = 0, window : uint = 0, scheduler : IScheduler = null) : IConnectableObservable;
		function replayAndConnect(selector : Function, bufferSize : uint = 0, window : uint = 0, scheduler : IScheduler = null) : IObservable;
		
		function repeat(repeatCount : uint = 0) : IObservable;
		
		function retry(retryCount : uint = 0) : IObservable;
		
		function returnValue(value : Object) : IObservable;
		
		function scan(accumulator : Function, outputType : Class = null, initialValue : Object = null) : IObservable;
		
		function select(result : Class, selector:Function):IObservable;
		
		function selectMany(type : Class, selector : Function) : IObservable;
		
		function single() : IObservable;
		function singleOrDefault() : IObservable;
		
		function skip(count : uint) : IObservable;
		
		function skipLast(count : uint) : IObservable;
		
		function skipUntil(other : IObservable) : IObservable;
		
		function skipWhile(predicate : Function) : IObservable;
		
		//static function start(func : Function, scheduler : IScheduler = null) : IObservable;
		
		function startWith(value : Array, scheduler : IScheduler = null) : IObservable;
		
		function sum() : IObservable;
		
		function takeLast(count : uint) : IObservable;
		
		function take(count : uint) : IObservable;
		
		function takeUntil(other : IObservable) : IObservable;
		
		function takeWhile(predicate : Function) : IObservable;
		
		function throttle(dueTimeMs : uint, scheduler : IScheduler = null) : IObservable;
		
		function timeInterval(scheduler : IScheduler = null) : IObservable;
		
		function timeout(timeoutMs : uint, other : IObservable = null, scheduler : IScheduler = null) : IObservable;
		
		function timestamp(scheduler : IScheduler = null) : IObservable;
		
		function toAsync(func : Function) : IObservable;
		
		function where(predicate : Function) : IObservable;
		
		function zip(resultType : Class, rightSource : IObservable, selector : Function) : IObservable;
	}
}