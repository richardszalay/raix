package raix.reactive.testing
{
	import raix.reactive.IObserver;
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
			return _recordedNotificatons.slice(0, _recordedNotificatons.length - 1);
		}
		
		public function get values() : Array
		{
			return _values.slice(0, _values.length - 1);
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
	}
}