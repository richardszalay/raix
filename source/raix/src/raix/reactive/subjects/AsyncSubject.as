package raix.reactive.subjects
{
	import flash.errors.IllegalOperationError;
	
	import raix.reactive.AbsObservable;
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObserver;
	import raix.reactive.ISubject;
	import raix.reactive.Notification;
	import raix.reactive.OnCompleted;
	import raix.reactive.OnError;
	import raix.reactive.OnNext;
	import raix.reactive.scheduling.IScheduler;
	import raix.reactive.scheduling.Scheduler;
	
	/**
	 * A subject that replays the last value (or error) received to observers that subscribe 
	 * after the sequence has completed
	 */	
	public class AsyncSubject extends AbsObservable implements ISubject
	{
		private var _valueClass : Class;
		private var _scheduler : IScheduler;
		
		private var _complete : Boolean = false;		
		private var _lastValue : Notification;
		private var _observers : Array = new Array();
		
		public function AsyncSubject(valueClass : Class, scheduler : IScheduler = null)
		{
			_scheduler = scheduler || Scheduler.synchronous;
			_valueClass = valueClass;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get valueClass():Class
		{
			return _valueClass;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			if (_complete)
			{
				var scheduledAction : ICancelable = _scheduler.schedule(function():void
				{
					dispatch(observer);
				});
				
				return scheduledAction;
			}
			else
			{
				_observers.push(observer);
				
				return Cancelable.create(function():void
				{
					var index : int = _observers.indexOf(observer);
					
					if (index != -1)
					{
						_observers.splice(index, 1);
					}
				});
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function onNext(value : Object) : void
		{
			if (!_complete)
			{
				_lastValue = new OnNext(value);
			}
		}
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @inheritDoc
		 */
		public function onError(err : Error) : void
		{
			if (!_complete)
			{
				_complete = true;
				
				_lastValue = new OnError(err);
				
				dispatchAll();
			}
		}
		
		/**
		 * Gets the last value received, or throws an IllegalOperationError if no value 
		 * has been received.
		 */
		public function lastValue() : Object
		{
			if (_lastValue == null || !_lastValue.hasValue)
			{
				throw new IllegalOperationError("No value available");
			}
			
			return _lastValue.value;
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
			_lastValue.acceptWith(observer);
			
			if (_lastValue.hasValue)
			{
				_scheduler.schedule(function():void
				{
					observer.onCompleted();
				});
			}
		}
	}
}