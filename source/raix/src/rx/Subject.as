package rx
{
	import rx.ClosureCancelable;
	
	/**
	 * A Subject is both an IObservable and an IObserver, so it can be 
	 * returned as an IObservable and fed values through the IObserver 
	 * methods.
	 * 
	 * <p>When returning a Subject as an IObservable, it's recommended that you
	 * return subject.asObservable() to hide the original instance</p>
	 */	
	public class Subject extends AbsObservable implements ISubject
	{
		private var _isFinished : Boolean = false;
		private var _subscriptionCount : uint = 0;
		
		private var _observers : Array = new Array();
		
		private var _type : Class;
		
		public function Subject(type : Class)
		{
			_type= type;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get valueClass() : Class
		{
			return _type;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			_subscriptionCount++;
			
			_observers.push(observer);
			
			return new ClosureCancelable(function():void
			{
				var index : int = _observers.indexOf(observer);
				
				if (index != -1)
				{
					_observers.splice(index, 1);
				}
				
				_subscriptionCount--;
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public function onNext(pl : Object) : void
		{
			if (!_isFinished)
			{
				var observers : Array = _observers.slice();
				
				for each(var obs : IObserver in observers)
				{
					obs.onNext(pl);
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function onCompleted() : void
		{
			if (!_isFinished)
			{
				_isFinished = true;
				
				var observers : Array = _observers.slice();
				
				for each(var obs : IObserver in observers)
				{
					obs.onCompleted();
				}
				
				_observers = [];
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function onError(error : Error) : void
		{
			if (!_isFinished)
			{
				_isFinished = true;
				
				var observers : Array = _observers.slice();
				
				for each(var obs : IObserver in observers)
				{
					obs.onError(error);
				}
				
				_observers = [];
			}
		}
		
		/**
		 * Determines whether this subject has any subscriptions
		 */
		public function get hasSubscriptions() : Boolean
		{
			return _subscriptionCount > 0;
		}
		
		/**
		 * Gets the number of subscriptions this subject has
		 */		
		public function get subscriptionCount() : int
		{
			return _subscriptionCount;
		}
	}
}