package rx.impl
{
	import rx.AbsObservable;
	import rx.IObserver;
	import rx.ICancelable;
	
	public class ClosureObservable extends AbsObservable
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
			
			var subscription : ICancelable = ICancelable(_observeFunc(safetyObserver));
			
			safetyObserver.setSubscription(subscription);
			
			return subscription; 
		}
		
		public override function get type() : Class
		{
			return _type;
		}
	}
}
