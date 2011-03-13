package raix.reactive
{
	import raix.reactive.AbsObservable;
	import raix.reactive.IObserver;
	import raix.reactive.ICancelable;
	import raix.reactive.scheduling.Scheduler;
	
	internal class ClosureObservable extends AbsObservable
	{
		private var _observeFunc : Function;
		private var _type : Class;
		
		public function ClosureObservable(type : Class, observeFunc : Function)
		{
			_observeFunc = observeFunc;
			_type = type;
		}
		
		public override function subscribeWith(observer : IObserver) : ICancelable 
		{
			// TODO: What is observer is already a SafetyObserver (eg. select().first())?
			var safetyObserver : SafetyObserver = new SafetyObserver(observer);
			
			var subscription : FutureCancelable = new FutureCancelable();
			safetyObserver.setSubscription(subscription);
			
			Scheduler.immediate.schedule(function():void
			{
				subscription.innerCancelable = ICancelable(_observeFunc(safetyObserver));
			});
			
			
			return subscription; 
		}
		
		public override function get valueClass() : Class
		{
			return _type;
		}
	}
}
