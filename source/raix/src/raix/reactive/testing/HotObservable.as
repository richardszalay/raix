package raix.reactive.testing
{
	import raix.reactive.AbsObservable;
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObserver;
	
	public class HotObservable extends AbsObservable
	{
		private var _scheduler : TestScheduler;
		private var _messages : Array;
		
		private var _observers : Array = new Array();
		private var _subscriptions : Array = new Array();
		
		public function HotObservable(scheduler : TestScheduler, messages : Array)
		{
			_scheduler = scheduler;
			_messages = messages;
			
			for each(var recordedNotification : Recorded in _messages)
			{
				(function(recordedNotification : Recorded) : void {
					_scheduler.schedule(function() : void
					{
						var observers : Array = _observers.slice();
						
						for each(var observer : IObserver in observers)
						{					
							recordedNotification.value.accept(observer.onNext, 
								observer.onCompleted, observer.onError);
						}
					}, recordedNotification.time);
				})(recordedNotification);
			}
		}
		
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			var subscription : Subscription = new Subscription(_scheduler.now.time);
			_subscriptions.push(subscription);
			
			_observers.push(observer);
						
			return Cancelable.create(function():void
			{
				var index : int = _observers.indexOf(observer);
				if (index != -1) _observers.splice(index, 1);
			});
		}
		
		public function get subscriptions() : Array
		{
			return _subscriptions;
		}
		
		public function get observers() : Array
		{
			return _observers; 
		}
	}
}