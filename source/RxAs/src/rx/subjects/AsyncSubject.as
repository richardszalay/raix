package rx.subjects
{
	import rx.AbsObservable;
	import rx.IObserver;
	import rx.ISubject;
	import rx.ISubscription;
	import rx.Notification;
	import rx.Observable;
	import rx.impl.ClosureSubscription;
	import rx.impl.OnCompleted;
	import rx.impl.OnError;
	import rx.impl.OnNext;
	import rx.impl.ScheduledActionSubscription;
	import rx.scheduling.IScheduledAction;
	import rx.scheduling.IScheduler;
	
	public class AsyncSubject extends AbsObservable implements ISubject
	{
		private var _scheduler : IScheduler;
		private var _complete : Boolean = false;		
		private var _lastValue : Notification;
		private var _observers : Array = new Array();
		
		public function AsyncSubject(type : Class, scheduler : IScheduler = null)
		{
			_scheduler = Observable.resolveScheduler(scheduler);
		}
		
		public override function subscribe(observer:IObserver):ISubscription
		{
			if (_complete)
			{
				var scheduledAction : IScheduledAction = _scheduler.schedule(function():void
				{
					dispatch(observer);
				});
				
				return new ScheduledActionSubscription(scheduledAction);
			}
			else
			{
				_observers.push(observer);
				
				return new ClosureSubscription(function():void
				{
					var index : int = _observers.indexOf(observer);
					
					if (index != -1)
					{
						_observers.splice(index, 1);
					}
				});
			}
		}
		
		public function onNext(value : Object) : void
		{
			if (!_complete)
			{
				_lastValue = new OnNext(value);
			}
		}
		
		public function onCompleted() : void
		{
			if (!_complete)
			{
				_complete = true;
				
				if (_lastValue == null)
				{
					_lastValue = new OnCompleted();
				}
				
				dispatchAll();
			}
		}
		
		public function onError(err : Error) : void
		{
			if (!_complete)
			{
				_complete = true;
				
				_lastValue = new OnError(err);
				
				dispatchAll();
			}
		}
		
		private function dispatchAll() : void
		{
			while(_observers.length > 0)
			{
				(function(obs:IObserver):void
				{
					_scheduler.schedule(function():void
					{
						dispatch(obs);
					});
				})(_observers.shift());
			}
		}
		
		private function dispatch(observer : IObserver) : void
		{
			_lastValue.accept(observer);
			
			if (_lastValue.hasValue)
			{
				observer.onCompleted();
			}
		}
	}
}