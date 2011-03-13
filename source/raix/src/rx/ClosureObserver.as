package rx
{
	import rx.IObserver;
	import rx.Observable;
	
	internal class ClosureObserver implements IObserver
	{
		private var _onNext : Function;		
		private var _onComplete : Function;		
		private var _onError : Function;		
		
		public function ClosureObserver(onNext : Function, onComplete : Function = null, onError : Function = null)
		{
			_onNext = onNext;
			_onComplete = onComplete;
			_onError = onError;
		}
		
		public function onCompleted() : void
		{
			if (_onComplete != null)
			{
				_onComplete();
			}
		}
		
    	public function onError(error : Error) : void
    	{
    		if (_onError != null)
    		{
    			_onError(error);
    		}
    	}
    	
    	public function onNext(value : Object) : void
    	{
    		if (_onNext != null)
    		{
    			_onNext(value);
    		}
    	}

	}
}