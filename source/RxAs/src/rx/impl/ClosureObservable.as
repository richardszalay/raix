package rx.impl
{
	import rx.AbsObservable;
	import rx.IObserver;
	import rx.ISubscription;
	import rx.scheduling.IScheduler;
	
	public class ClosureObservable extends AbsObservable
	{
		private var _observeFunc : Function;
		
		public function ClosureObservable(observeFunc : Function)
		{
			_observeFunc = observeFunc;
		}
		
		public override function subscribe(observer : IObserver, scheduler : IScheduler = null) : ISubscription 
		{
			// TODO: Here would be a good place to implement
			// a safety wrapper for the execution order of 
			// third party IObservables as mentioned on a channel9 vid (CITE?)
			return ISubscription(_observeFunc(observer, scheduler));
		}
	}
}
