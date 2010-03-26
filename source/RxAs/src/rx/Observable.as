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
		
		public static function interval(intervalMs : uint):IObservable
		{
			return new ClosureObservable(function(observer : IObserver, scheduler : IScheduler = null) : ISubscription
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
		
		public static function fromEvent(eventDispatcher:IEventDispatcher, type:String, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):IObservable
		{
			return new ClosureObservable(function(observer : IObserver, scheduler : IScheduler = null) : ISubscription
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
		
		public static function empty(scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || ImmediateScheduler.instance;
			
			return new ClosureObservable(function(obs:IObserver) : ISubscription
			{
				scheduler.schedule(obs.onCompleted);
				
				return new ClosureSubscription(function():void{});
			});
		}
		
		/**
		 * Returns an IObservable that never completes
		 */		
		public static function never() : IObservable
		{
			return new ClosureObservable(function(obs:IObserver) : ISubscription
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
		
		public static function resolveScheduler(scheduler : IScheduler) : IScheduler
		{
			return scheduler || Scheduler.defaultScheduler;
		}
		
		
	}
}