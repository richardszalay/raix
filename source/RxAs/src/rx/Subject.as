package rx
{
	import rx.AbsObservable;
	import rx.IObserver;
	import rx.ICancelable;
	import rx.impl.ClosureSubscription;
	
	public class Subject extends AbsObservable implements IObserver
	{
		private var _subscriptionCount : uint = 0;
		
		private var _observers : Array = new Array();
		
		private var _type : Class;
		
		public function Subject(type : Class)
		{
			_type= type;
		}
		
		public override function get type() : Class
		{
			return _type;
		}
		
		public override function subscribe(observer:IObserver):ICancelable
		{
			_subscriptionCount++;
			
			_observers.push(observer);
			
			return new ClosureSubscription(function():void
			{
				for (var i:int=0; i<_observers.length; i++)
				{
					if (_observers[i] == observer)
					{
						_observers.splice(i, 1);
						break;
					}
				}
				
				_subscriptionCount--;
			});
		}
		
		public function onNext(pl : Object) : void
		{
			for each(var obs : IObserver in _observers)
			{
				obs.onNext(pl);
			}
		}
		
		public function onCompleted() : void
		{
			var observers : Array = [].concat(_observers);
			
			for each(var obs : IObserver in observers)
			{
				obs.onCompleted();
			}
		}
		
		public function onError(error : Error) : void
		{
			var observers : Array = [].concat(_observers);
			
			for each(var obs : IObserver in observers)
			{
				obs.onError(error);
			}
		}
		
		public function get hasSubscriptions() : Boolean
		{
			return _subscriptionCount > 0;
		}

	}
}