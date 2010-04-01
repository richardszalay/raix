package rx
{
	import flash.display.LoaderInfo;
	import flash.errors.IllegalOperationError;
	import flash.events.*;
	import flash.utils.Timer;
	
	import rx.impl.*;
	import rx.scheduling.*;

	public class Observable
	{
		public function Observable()
		{
			throw new IllegalOperationError("This class is static and cannot be instantiated. Create an IObservable by using one of Observable's static methods");
		}
		
		public static function defer(type : Class, observableFactory:Function):IObservable
		{
			if (observableFactory == null)
			{
				throw new ArgumentError("observableFactory cannot be null");
			}
			
			return new ClosureObservable(type, function(observer : IObserver):ISubscription
			{
				var observable : IObservable = observableFactory();
				
				if (observable.type != type)
				{
					throw new ArgumentError("Deffered observable type must match type given to defer"); 
				}
				
				return observable.subscribe(observer);
			});
		}
		
		public static function interval(intervalMs : uint):IObservable
		{
			return new ClosureObservable(int, function(observer : IObserver, scheduler : IScheduler = null) : ISubscription
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var intervalIndex : uint = 0;
				
				var listener : Function = function(event : Event) : void
				{
					scheduler.schedule(function():void
					{
						observer.onNext(++intervalIndex);
					});
				};
				
				var timer : Timer = new Timer(intervalMs, 0);
				timer.addEventListener(TimerEvent.TIMER, listener);
				timer.start();
				
				return new ClosureSubscription(function():void
				{
					timer.stop();
				});
			});
		}
		
		public static function fromEvent(eventDispatcher:IEventDispatcher, type:String, eventType : Class = null, useCapture:Boolean=false, priority:int=0):IObservable
		{
			eventType = eventType || Event;
			
			return new ClosureObservable(eventType, function(observer : IObserver, scheduler : IScheduler = null) : ISubscription
			{
				scheduler = Observable.resolveScheduler(scheduler);
				
				var listener : Function = function(event : Event) : void
				{
					scheduler.schedule(function():void
					{
						observer.onNext(event);
					});
				};
				
				scheduler.schedule(function():void
				{
					eventDispatcher.addEventListener(type, listener, useCapture, priority);
				});
				
				return new ClosureSubscription(function():void
				{
					eventDispatcher.removeEventListener(type, listener, useCapture);
				});
			});
		}
		
		public static function empty(observableType : Class = null, scheduler : IScheduler = null) : IObservable
		{
			observableType = observableType || Object;
			scheduler = scheduler || ImmediateScheduler.instance;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ISubscription
			{
				return new ScheduledActionSubscription(
					scheduler.schedule(obs.onCompleted)
				);
			});
		}
		
		public static function onErrorResumeNext(sources:Array, scheduler:IScheduler=null):IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = resolveScheduler(scheduler);
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(sources[0].type, function(obs:IObserver) : ISubscription
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : ISubscription = null;
				var scheduledAction : IScheduledAction = null;
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
						
					subscription = currentSource.subscribeFunc(
						function(pl:Object) : void { obs.onNext(pl); },
						function() : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onCompleted();
							}
						},
						function(e:Error) : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onError(e);
							}
						});
				};
				
				scheduledAction = scheduler.schedule(moveNextFunc);
				
				return new ClosureSubscription(function():void
				{
					if (scheduledAction != null)
					{
						scheduledAction.cancel();
					}
					
					if (subscription != null)
					{
						subscription.unsubscribe();
					}
				});
			});
		}
		
		/**
		 * Returns an IObservable that never completes
		 */		
		public static function never(observableType : Class = null) : IObservable
		{
			observableType = observableType || Object;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ISubscription
			{
				return new ClosureSubscription(function():void{});
			});
		}
		
		public static function uncaughtErrors(loaderInfo : LoaderInfo = null) : IObservable
		{
			loaderInfo = loaderInfo || LoaderInfo.getLoaderInfoByDefinition(Observable);
			
			var uncaughtErrorsSupported : Boolean = 
				loaderInfo.hasOwnProperty("uncaughtErrorEvents");
			
			if (uncaughtErrorsSupported)
			{
				return fromEvent(
					IEventDispatcher(loaderInfo["uncaughtErrorEvents"]),
					"uncaughtError"
					);
			}
			else
			{
				return never();
			}
		}
		
		public static function range(start : int, count : uint, scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Observable.resolveScheduler(scheduler);
			
			return new ClosureObservable(int, function(obs:IObserver) : ISubscription
			{
				var end : int = start + count;
				
				var scheduledActions : Array = new Array();
				
				for (var i:int = start; i<end; i++)
				{
					(function(value:int):void
					{
						scheduledActions.push(scheduler.schedule(function():void { obs.onNext(value); }));
					})(i);
				}
				
				scheduledActions.push(scheduler.schedule(function():void { obs.onCompleted(); }));
				
				return new ClosureSubscription(function():void
				{
					while (scheduledActions.length > 0)
					{
						IScheduledAction(scheduledActions.shift()).cancel();
					}
				});
			});
		}
		
		public static function repeatValue(type : Class, value : Object, scheduler : IScheduler) : void
		{
			throw new IllegalOperationError("subscribe() must be overriden");
		}
		
		public static function throwError(error : Error, observableType : Class = null) : IObservable
		{
			if (error == null)
			{
				throw new ArgumentError("error cannot be null");
			}
			
			observableType = observableType || Object;
			
			return new ClosureObservable(observableType, function(obs:IObserver) : ISubscription
			{
				obs.onError(error);
				
				return new ClosureSubscription(function():void{});
			});
		}
		
		public static function returnValue(type : Class, value : Object, scheduler : IScheduler = null) : IObservable
		{
			scheduler = resolveScheduler(scheduler);
			
			return new ClosureObservable(type, function(obs:IObserver) : ISubscription
			{
				var valueScheduledAction : IScheduledAction = 
					scheduler.schedule(function():void { obs.onNext(value); });
					
				var completeScheduledAction : IScheduledAction =
					scheduler.schedule(function():void { obs.onCompleted(); });
				
				return new ClosureSubscription(function():void
				{
					valueScheduledAction.cancel();
					completeScheduledAction.cancel();
				});
			});
		}
		
		public static function catchErrors(sources : Array, scheduler : IScheduler = null) : IObservable
		{
			if (sources == null || sources.length == 0)
			{
				throw new ArgumentError("sources");
			}
			
			scheduler = resolveScheduler(scheduler);
			
			// Make internally immutable
			sources = new Array().concat(sources);
			
			return new ClosureObservable(sources[0].type, function(obs:IObserver) : ISubscription
			{
				var remainingSources : Array = new Array().concat(sources);
				
				var subscription : ISubscription = null;
				var scheduledAction : IScheduledAction = null;
				
				var moveNextFunc : Function = null;
				
				moveNextFunc = function():void
				{
					var currentSource : IObservable = remainingSources.shift();
						
					subscription = currentSource.subscribeFunc(
						function(pl:Object) : void { obs.onNext(pl); },
						function() : void { obs.onCompleted(); },
						function(e:Error) : void
						{
							if (remainingSources.length > 0)
							{
								scheduledAction = scheduler.schedule(moveNextFunc);
							}
							else
							{
								obs.onError(e);
							}
						});
				};
				
				scheduledAction = scheduler.schedule(moveNextFunc);
				
				return new ClosureSubscription(function():void
				{
					if (scheduledAction != null)
					{
						scheduledAction.cancel();
					}
					
					if (subscription != null)
					{
						subscription.unsubscribe();
					}
				});
			});
		}
		
		public static function resolveScheduler(scheduler : IScheduler) : IScheduler
		{
			return scheduler || Scheduler.defaultScheduler;
		}
		
		
		
	}
}