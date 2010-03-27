package rx
{
	import flash.errors.IllegalOperationError;
	
	import rx.impl.ClosureObservable;
	import rx.impl.ClosureObserver;
	import rx.impl.ClosureSubscription;
	import rx.joins.Pattern;
	import rx.scheduling.IScheduler;
	
	public class AbsObservable implements IObservable
	{
		public function AbsObservable()
		{
		}
		
		public function subscribe(observer : IObserver) : ISubscription
		{
			// Abstract methods not supported by AS3
			throw new IllegalOperationError("subscribe() must be overriden");
		}
		
		public function subscribeFunc(onNext : Function, onComplete : Function = null, 
			onError : Function = null) : ISubscription
		{
			var observer : IObserver = new ClosureObserver(onNext, onComplete, onError);
			
			return subscribe(observer);
		}

		public function aggregate(accumulator:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function amb(sources:Array):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function and(right:IObservable):Pattern
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function asynchronous():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function bufferWithCount(count:int, skip:int=0):IObservable
		{
			if (skip != 0)
			{
				throw new IllegalOperationError("Not implemented");
			}
			
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver, obsSched:IScheduler=null):ISubscription
			{
				var scheduler : IScheduler = Observable.resolveScheduler(obsSched);
				
				var buffer : Array = new Array();
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						buffer.push(pl);
						
						if (buffer.length == count)
						{
							scheduler.schedule((function(b:Array):Function
							{
								return function():void { observer.onNext(b); }
							})(buffer));
							
							buffer = new Array();
						}
					},
					function () : void { scheduler.schedule(function():void{observer.onCompleted();}); },
					function (error : Error) : void { scheduler.schedule(function():void{observer.onError(error);}); });
					
				return source.subscribe(dec);
			});
		}
		
		public function bufferWithTime(timeMs:int, timeShiftMs:int=0, scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function combineLatest(right:IObservable, selector:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function concat(sources:Array, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver, obsSched:IScheduler=null):ISubscription
			{
				var currentSource : IObservable = source;
			
				var subscription : ISubscription = null;
				
				var remainingSources : Array = [].concat(sources);
				
				scheduler = scheduler || Observable.resolveScheduler(obsSched);
				
				var dec : IObserver = null;
				
				var onNext : Function = function onNext(pl : Object) : void
				{
					scheduler.schedule(function():void { observer.onNext(pl); });
				};
				
				var onError : Function = function (error : Error) : void { observer.onError(error); };
				
				var onComplete : Function = function () : void
				{
					subscription.unsubscribe();
					
					if (remainingSources.length > 0)
					{
						trace("concat :: Move to next source");
						
						currentSource = IObservable(remainingSources.shift());
						subscription = currentSource.subscribe(dec);
					}
					else
					{
						trace("concat :: Completed");
						
						observer.onCompleted();
					}
				}
				
				dec = new ClosureObserver(onNext, onComplete, onError);

				subscription = currentSource.subscribe(dec);
				
				return new ClosureSubscription(function():void
				{
					subscription.unsubscribe();
				});
			});
		}
		
		public function count():int
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function defer(observableFactory:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function delay(delayMs:int, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver, obsSched:IScheduler=null):ISubscription
			{
				scheduler = scheduler || Observable.resolveScheduler(obsSched);
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						scheduler.schedule(function():void { observer.onNext(pl); }, delayMs);
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); });
					
				return source.subscribe(dec);
			});
		}
		
		public function delayUntil(dt:Date, scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function dematerialize():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function doAction(action:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function finallyAction(finallyAction:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function first():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function firstOrDefault():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function forkJoin(sources:Array):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function asObservable():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function distinctUntilChanged(comparer:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function join(plans:Array):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function last():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function lastOrDefault():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function latest():Array
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function let(func : Function) : IObservable
		{
			return IObservable(func(this));
		}
		
		public function materialize():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function merge(sources:Array, scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function mostRecent(initialValue:Object):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function observeOn(scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
				
		public function onErrorResumeNext(sources:Array, scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function publish(scheduler:IScheduler=null):Subject
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function repeat(repeatCount:int=0, scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function retry(retryCount:int, scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function returnValue(value:Object):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function select(selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver) : ISubscription
			{
				var countSoFar : uint = 0;
				
				var subscription : ISubscription;
				
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						value = selector(value);
						
						observer.onNext(value);
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				subscription = source.subscribe(decoratorObserver);
				
				return subscription;
			});
		}
		
		public function selectMany(selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function(observer : IObserver, obsSched:IScheduler=null):ISubscription
			{
				var scheduler : IScheduler = Observable.resolveScheduler(obsSched);
				
				var subscriptions : Array = new Array();
				
				var unsubscribeAll : Function = function():void
				{
					for each(var subscription : ISubscription in subscriptions)
					{
						subscription.unsubscribe();
					}
					
					subscriptions = [];
				};
				
				var selectedObserver : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						trace("selectMany :: child onNext");
						
						observer.onNext(pl);
					},
					function () : void { },
					function (error : Error) : void { scheduler.schedule(function():void{observer.onError(error);}); }
					);
				
				var dec : IObserver = new ClosureObserver(
					function(pl : Object) : void
					{
						var result : IObservable = selector(pl);
						
						trace("selectMany :: origin onNext");
						
						var subscription : ISubscription = result.subscribe(selectedObserver);
						subscriptions.push(subscription);
					},
					function () : void { unsubscribeAll(); scheduler.schedule(function():void{observer.onCompleted();}); },
					function (error : Error) : void { unsubscribeAll(); scheduler.schedule(function():void{observer.onError(error);}); }
					);
					
				subscriptions.push(source.subscribe(dec));
				
				return new ClosureSubscription(unsubscribeAll);
			});
		}
		
		public function single():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function singleOrDefault():IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function skip(count:int):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver, scheduler : IScheduler = null) : ISubscription
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var skippedSoFar : uint = 0;
				
				var subscription : ISubscription;
				
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						if (++skippedSoFar > count)
						{
							scheduler.schedule(function():void { observer.onNext(value); });
						}
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				subscription = source.subscribe(decoratorObserver);
				
				return subscription;
			});
		}
		
		public function skipUntil(other:IObservable):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function skipWhile(predicate:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}

		public function sum():Number
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function take(count:int, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver, scheduler : IScheduler = null) : ISubscription
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var countSoFar : uint = 0;
				
				var subscription : ISubscription;
				
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						scheduler.schedule(function():void { observer.onNext(value); });
						
						if (++countSoFar == count)
						{
							subscription.unsubscribe();
							scheduler.schedule(function():void { observer.onCompleted(); });
						}
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				subscription = source.subscribe(decoratorObserver);
				
				return subscription;
			});
		}
		
		public function takeUntil(other:IObservable):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver, scheduler : IScheduler = null) : ISubscription
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var subscription : ISubscription;
				
				var primarySubscription : ISubscription;
				var otherSubscription : ISubscription;
				
				var dispose : Function = function():void
				{
					trace("takeUntil :: Disposing");
					
					if (primarySubscription != null)
					{
						primarySubscription.unsubscribe();
					}
					
					if (otherSubscription != null)
					{
						otherSubscription.unsubscribe();
					}
				};
				
				var primaryObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						trace("takeUntil :: onNext");
						scheduler.schedule(function():void { observer.onNext(value); });
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
					
				var otherObserver : IObserver = new ClosureObserver(
					function (value : Object) : void { dispose(); observer.onCompleted(); },
					function () : void  { dispose(); observer.onCompleted(); },
					function (error : Error) : void  { dispose(); observer.onError(error); }
					);
				
				primarySubscription = source.subscribe(primaryObserver);
				otherSubscription = other.subscribe(otherObserver);
				
				return new ClosureSubscription(dispose);
			});
		}
		
		public function takeWhile(predicate:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function throttle(dueTimeMs:int, scheduler:IScheduler=null):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver, scheduler : IScheduler = null) : ISubscription
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var lastValueTimestamp : Number = 0;
				
				var subscription : ISubscription;
				
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : TimeStamped) : void
					{
						var diffMs : Number = value.timestamp - lastValueTimestamp;
						
						if (diffMs > dueTimeMs)
						{
							lastValueTimestamp = value.timestamp;
							
							scheduler.schedule(function():void { observer.onNext(value.value); });
						}
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				subscription = source.timestamp().subscribe(decoratorObserver);
				
				return subscription;
			});
		}
		
		public function throwError(error:Error):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function timeInterval(scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function timeout(timeoutMs:int, other:IObservable=null, scheduler:IScheduler=null):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function timer(dueTimeMs:int):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function timestamp(scheduler:IScheduler=null):IObservable
		{
			return select(function(value : Object) : TimeStamped
			{
				return new TimeStamped(value, new Date().getTime());
			});
		}
		
		public function toAsync(func:Function):IObservable
		{
			throw new IllegalOperationError("Not implemented");
		}
		
		public function where(predicate:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver, scheduler : IScheduler = null) : ISubscription
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var decoratorObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						scheduler.schedule(function():void
						{
							var result : Boolean = false;
							
							try
							{
								result = predicate(value);
								
								if (result)
								{
									observer.onNext(value);
								}
							}
							catch(error : Error)
							{
								observer.onError(error);
							}
						});
					},
					function () : void { observer.onCompleted(); },
					function (error : Error) : void { observer.onError(error); }
					);
				
				return source.subscribe(decoratorObserver);
			});
		}
		
		public function zip(rightSource:IObservable, selector:Function):IObservable
		{
			var source : IObservable = this;
			
			return new ClosureObservable(function (observer : IObserver, scheduler : IScheduler = null) : ISubscription
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var leftValues : Array = new Array();
				var rightValues : Array = new Array();
				
				var leftSubscription : ISubscription, 
					rightSubscription : ISubscription;
				
				var unsubscribeAll : Function = function():void
				{
					if (leftSubscription != null)
					{
						leftSubscription.unsubscribe();
						leftSubscription = null;
					}
					
					if (rightSubscription != null)
					{
						rightSubscription.unsubscribe();
						rightSubscription = null;
					}
				};				
				
				var leftObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						trace("zip :: left");
						
						if (rightValues.length > 0)
						{
							value = selector(value, rightValues.shift());
							
							scheduler.schedule(function():void { observer.onNext(value); });
						}
						else
						{
							leftValues.push(value);
						}
					},
					function () : void { unsubscribeAll(); observer.onCompleted(); },
					function (error : Error) : void { unsubscribeAll(); observer.onError(error); }
					);
					
				var rightObserver : IObserver = new ClosureObserver(
					function (value : Object) : void
					{
						trace("zip :: right");
						
						if (leftValues.length > 0)
						{
							value = selector(leftValues.shift(), value);
							
							scheduler.schedule(function():void { observer.onNext(value); });
						}
						else
						{
							rightValues.push(value);
						}
					},
					function () : void { unsubscribeAll(); observer.onCompleted(); },
					function (error : Error) : void { unsubscribeAll(); observer.onError(error); }
					);
					
				leftSubscription = source.subscribe(leftObserver);
				rightSubscription = rightSource.subscribe(rightObserver);
				
				return new ClosureSubscription(function():void
				{
					if (leftSubscription != null)
					{
						leftSubscription.unsubscribe();
						leftSubscription = null;
					}
					
					if (rightSubscription != null)
					{
						rightSubscription.unsubscribe();
						rightSubscription = null;
					}
				});
			});
		}		
	}
}