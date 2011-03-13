package raix.reactive.subjects
{
	import raix.reactive.*;
	import raix.reactive.*;
	import raix.reactive.scheduling.*;
	
	public class ReplaySubject extends AbsObservable implements ISubject
	{
		private var _scheduler : IScheduler;
		private var _bufferSize : uint;
		private var _window : uint;
		
		private var _complete : Boolean = false;		
		
		private var _values : Array = new Array(); // of Timestamp of Notification
		
		private var _liveObservers : Array = new Array();
		private var _observerValues : Array = new Array(); // of Array of Timestamp of Notification
		
		private var _valueClass : Class;
		
		public function ReplaySubject(valueClass : Class, bufferSize : uint = 0, 
			window : uint = 0, scheduler : IScheduler = null)
		{
			_valueClass = valueClass;
			_bufferSize = bufferSize;
			_window = window;
			_scheduler = scheduler || Scheduler.synchronous;
		}
		
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			removeInvalidValues();
			
			var observerValues : Array = new Array(); // of Timestamp of Notification
			observerValues = observerValues.concat(_values);
			
			_observerValues.push(observerValues);
			
			var scheduledAction : ICancelable = 
				Scheduler.scheduleRecursive(_scheduler, function(recurse:Function):void
			{
				if (observerValues.length > 0)
				{
					var not : Notification = observerValues.shift().value;
					not.acceptWith(observer);
					
					recurse();
				}
				else
				{
					_liveObservers.push(observer);
					
					var valuesIndex : int = _observerValues.indexOf(observerValues);
					
					if (valuesIndex != -1) 
					{
						_observerValues.splice(valuesIndex, 1);
					}
				}
																
			}, 0);
			
			return Cancelable.create(function():void
			{
				scheduledAction.cancel();
				
				var observerIndex : int = _liveObservers.indexOf(observer);
				
				if (observerIndex != -1) 
				{
					_liveObservers.splice(observerIndex, 1);
				}
				
				var valuesIndex : int = _observerValues.indexOf(observerValues);
					
				if (valuesIndex != -1) 
				{
					_observerValues.splice(valuesIndex, 1);
				}
			});
		}
		
		private function removeInvalidValues() : void
		{
			var removeForBufferSize : Boolean = 
					(_bufferSize != 0 && _values.length > _bufferSize);
					
			var nowValue : Number = _scheduler.now.time;
			
			while (_values.length > 0 || removeForBufferSize)
			{
				var timestamp : TimeStamped = _values[0];
				
				var removeForWindow : Boolean = 
					(_window != 0 && (nowValue-timestamp.timestamp) > _window);
				
				if (removeForBufferSize || removeForWindow)
				{
					_values.shift();
				}
				else
				{
					break;
				}
				
				removeForBufferSize = (_bufferSize != 0 && _values.length > _bufferSize);
			}
		}
		
		private function addValue(notification : Notification) : void
		{
			var value : TimeStamped = new TimeStamped(notification, _scheduler.now.time);
			
			_values.push(value);
			
			for each(var observerValues : Array in _observerValues)
			{
				observerValues.push(value);
			}
			
			removeInvalidValues();
		}
		
		public function onNext(value : Object) : void
		{
			if (!_complete)
			{
				addValue(new OnNext(value));
				
				for each(var liveObserver : IObserver in _liveObservers)
				{
					liveObserver.onNext(value);
				}
			}
		}
		
		public function onCompleted() : void
		{
			if (!_complete)
			{
				_complete = true;
				addValue(new OnCompleted());
				
				for each(var liveObserver : IObserver in _liveObservers)
				{
					liveObserver.onCompleted();
				}
			}
		}
		
		public function onError(err : Error) : void
		{
			if (!_complete)
			{
				_complete = true;
				addValue(new OnError(err));
				
				for each(var liveObserver : IObserver in _liveObservers)
				{
					liveObserver.onError(err);
				}
			}
		}
	}
}