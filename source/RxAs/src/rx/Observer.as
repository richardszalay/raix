package rx
{
	import rx.ClosureObserver;
	
	public class Observer
	{
		public static function create(onNext : Function, onComplete : Function = null, 
			onError : Function = null) : IObserver
		{
			return new ClosureObserver(onNext, onComplete, onError);
		}

	}
}