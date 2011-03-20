package raix.reactive.testing
{
	import raix.reactive.AbsObservable;
	import raix.reactive.Cancelable;
	import raix.reactive.CompositeCancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObserver;
	
	public class ColdObservable extends AbsObservable
	{
		private var _scheduler : TestScheduler;
		private var _messages : Array;
		
		private var _subscriptions : Array = new Array();
		
		public function ColdObservable(scheduler : TestScheduler, messages : Array)
		{
			_scheduler = scheduler;
			_messages = messages;
		}
		
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			var subscription : Subscription = new Subscription(_scheduler.now.time);
			
			_subscriptions.push(subscription);
			
			var schedule : CompositeCancelable = new CompositeCancelable([]);
			
			for each(var recordedNotification : Recorded in _messages)
			{
				(function(recordedNotification : Recorded) : void {
					schedule.add(_scheduler.schedule(function() : void
					{
						recordedNotification.value.accept(observer.onNext, 
							observer.onCompleted, observer.onError);
					}, recordedNotification.time));
				})(recordedNotification);
			}
			
			var subscriptionIndex : int = _subscriptions.length - 1;
			
			return Cancelable.create(function():void
			{
				schedule.cancel();
				
				_subscriptions[subscriptionIndex] = new Subscription(
					_subscriptions[subscriptionIndex].subscribe,
					_scheduler.now.time);
			});
		}
		
		public function get subscriptions() : Array
		{
			return _subscriptions;
		}
	}
}