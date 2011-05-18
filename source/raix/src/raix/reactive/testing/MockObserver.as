package raix.reactive.testing
{
	import flash.utils.getQualifiedClassName;
	
	import raix.interactive.toEnumerable;
	import raix.reactive.IObserver;
	import raix.reactive.Notification;
	import raix.reactive.NotificationKind;
	import raix.reactive.OnCompleted;
	import raix.reactive.OnError;
	import raix.reactive.OnNext;
	
	public class MockObserver implements IObserver
	{
		private var _values : Array = new Array();
		private var _completed : Boolean = false;
		private var _error : Error = null;
		
		private var _recordedNotificatons : Array = new Array();
		private var _scheduler : TestScheduler;
		
		public function MockObserver(scheduler : TestScheduler)
		{
			_scheduler = scheduler;
		}
		
		public function get recordedNotifications() : Array
		{
			return _recordedNotificatons.slice(0);
		}
		
		public function completed() : Boolean
		{
			return _completed;
		}
		
		public function hasError() : Boolean
		{
			return _error != null;
		}
		
		public function error() : Error
		{
			return _error;
		}
		
		/**
		 * @inheritDoc
		 */
		public function onCompleted() : void
		{
			_recordedNotificatons.push(
				new Recorded(_scheduler.now.time, new OnCompleted()));
				
			_completed = true;
		}
		
		/**
		 * @inheritDoc
		 */
    	public function onError(error : Error) : void
    	{
    		_recordedNotificatons.push(
				new Recorded(_scheduler.now.time, new OnError(error)));
				
			_error = error;
    	}
    	
		/**
		 * @inheritDoc
		 */
    	public function onNext(value : Object) : void
    	{
    		_recordedNotificatons.push(
				new Recorded(_scheduler.now.time, new OnNext(value)));
				
			_values.push(value);
    	}
    	
    	
    	public function assertValues(expectedValues : Array, failFunction : Function, comparer : Function = null, message : String = null) : void
    	{
    		var values : Array = toEnumerable(_recordedNotificatons)
    			.filter(function(r:Recorded) : Boolean { return r.value.hasValue; })
    			.map(function(r:Recorded) : Object { return r.value.value; })
    			.toArray();
    		
    		comparer = comparer || defaultComparer;
    		
    		if (expectedValues.length != values.length)
    		{
    			failFunction(["Unexpected number of values. Expected ", expectedValues.length,
    				" but was ", values.length, ". ", message].join("")); 
    		}
    		
    		for (var i:int=0; i<expectedValues.length; i++)
    		{
    			if (!comparer(expectedValues[i], values[i]))
    			{
    				failFunction(["Unexpected value at index ", i, ". Expected ", expectedValues[i],
    					" but was ", values[i], ". ", message].join(""));
    			}
    		}
    	}
    	
    	public function assertTimings(recordedNotifications : Array, failFunction : Function, valueComparer : Function = null, message : String = null) : void
    	{
    		var expected : Array = recordedNotifications;
    		
    		valueComparer = valueComparer || defaultComparer;
    		
    		for (var i:int=0; i<expected.length; i++)
    		{
    			if (_recordedNotificatons.length < i + 1)
    			{
    				failFunction(["Expected ", formatNotification(expected[i].value),
    					" @ " + expected[i].time].join(""));
    			}
    			
    			if (!notificationEquals(expected[i].value, _recordedNotificatons[i].value, valueComparer))
    			{
    				failFunction(["Expected ", formatNotification(expected[i].value),
    					" @ " + expected[i].time,
    					" but was ", formatNotification(_recordedNotificatons[i].value), 
    					" @ ", _recordedNotificatons[i].time].join(""));
    			}
    			
    			if (expected[i].time != _recordedNotificatons[i].time)
    			{
	    			failFunction(["Expected ", formatNotification(expected[i].value),
	    					" @ " + expected[i].time, " but was @ ",
	    					_recordedNotificatons[i].time].join(""));
	    		}
    		}
    	}
    	
    	public function assertNotifications(expectedNotifications : Array, failFunction : Function, valueComparer : Function = null, message : String = null) : void
    	{
    		var expected : Array = expectedNotifications;
    		
    		valueComparer = valueComparer || defaultComparer;
    		
    		for (var i:int=0; i<expected.length; i++)
    		{
    			if (_recordedNotificatons.length < i + 1)
    			{
    				failFunction(["Expected ", formatNotification(expected[i])].join(""));
    			}
    			
    			if (!notificationEquals(expected[i], _recordedNotificatons[i].value, valueComparer))
    			{
    				failFunction(["Expected ", formatNotification(expected[i]),
    					" but was ", formatNotification(_recordedNotificatons[i].value)].join(""));
    			}
    		}
    	}
    	
    	private function defaultComparer(x : Object, y : Object) : Boolean
    	{
    		return (x == null && y == null) || (x == y);
    	}
    	
    	private function formatNotification(notification : Notification) : String
    	{
    		if (notification.kind == NotificationKind.ON_NEXT)
    		{
    			return "value (" + notification.value + ")";
    		}
    		
    		if (notification.kind == NotificationKind.ON_ERROR)
    		{
    			return "error (" + getQualifiedClassName(notification.error) + ": " +
    				notification.error.message + ")";
    		}
    		
    		return "completion";
    	}
    	
    	private function notificationEquals(expected : Notification, actual : Notification, valueComparer : Function) : Boolean
    	{
    		if (expected.kind != actual.kind)
    		{
    			return false;
    		}
    		
    		if (expected.kind == NotificationKind.ON_COMPLETED)
    		{
    			return true;
    		}
    		
    		if (expected.hasValue)
    		{
    			return valueComparer(expected.value, actual.value);
    		}
    		
     		return (expected.error == actual.error);
    	}
	}
}