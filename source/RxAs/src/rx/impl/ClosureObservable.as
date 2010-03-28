package rx.impl
{
	import rx.AbsObservable;
	import rx.IObserver;
	import rx.ISubscription;
	
	public class ClosureObservable extends AbsObservable
	{
		private var _observeFunc : Function;
		
		public function ClosureObservable(observeFunc : Function)
		{
			_observeFunc = observeFunc;
		}
		
		public override function subscribe(observer : IObserver) : ISubscription 
		{
			// TODO: What is observer is already a SafetyObserver (eg. select().first())?
			var safetyObserver : SafetyObserver = new SafetyObserver(observer);
			
			var subscription : ISubscription = ISubscription(_observeFunc(safetyObserver));
			
			safetyObserver.setSubscription(subscription);
			
			return subscription; 
		}
	}
}
	import rx.IObserver;
	import rx.ISubscription;
	
// a safety wrapper for the execution order of 
// third party IObservables as mentioned on the channel 9 video:
// Reactive Extensions API in depth: Contract (02:10)
class SafetyObserver implements IObserver
{
	private var _innerObserver : IObserver;
	private var _active : Boolean;
	private var _subscription : ISubscription;
	
	public function SafetyObserver(innerObserver : IObserver)
	{
		_innerObserver = innerObserver;
		_active = true;
	}
	
    public function onNext(value : Object) : void
    {
    	_innerObserver.onNext(value);
    }
    
	public function onCompleted() : void
    {
    	if (_active)
    	{
    		_innerObserver.onCompleted();
    		setInactive(); 
    	}
    }
    
    public function onError(error : Error) : void
    {
    	if (_active)
    	{
    		_innerObserver.onError(error);
    		setInactive(); 
    	}
    }
    
    private function setInactive() : void
    {
    	_active = false;
    	
    	if (_subscription != null)
    	{
    		_subscription.unsubscribe();
    		_subscription = null;
    	}
    }
    
    public function setSubscription(subscription : ISubscription) : void
    {
    	if (_active)
    	{
    		_subscription = subscription;
    	}
    	else
    	{
    		subscription.unsubscribe();
    	}
    }
}