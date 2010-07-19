package rx.subjects
{
	import rx.*;
	
	/**
	 * Concrete implementation of IConnectableObservable
	 */	
	public class ConnectableObservable extends AbsObservable implements IConnectableObservable
	{
		private var _subscription : ICancelable;
		private var _source : IObservable;
		private var _subject : ISubject;
		
		public function ConnectableObservable(source : IObservable, subject : ISubject = null)
		{
			// TODO: Assert source != null
			// TODO: Assert source.valueClass = subject.valueClass
			
			_source = source.asObservable();
			_subject = subject || new Subject(source.valueClass);
		}
		
		/**
		 * @inheritDoc
		 */
		public function connect():ICancelable
		{
			var hasSubscription : Boolean = (_subscription != null);
			
			if (!hasSubscription)
			{
				_subscription = new CompositeCancelable([
					Cancelable.create(function():void { _subscription = null; }),
					_source.subscribeWith(_subject)
					]);
			}
			
			return _subscription;
		}
		
		/**
		 * @inheritDoc
		 */
		public function refCount() : IObservable
		{
			var source : IConnectableObservable = this;
			
			var connection : ICancelable = null;
			var subscriptionCount : uint = 0;
			
			return Observable.createWithCancelable(this.valueClass, function(observer : IObserver) : ICancelable
			{
				subscriptionCount++;
				
				var subscription : ICancelable = source.subscribeWith(observer);
				
				if (subscriptionCount == 1)
				{
					connection = source.connect();
				}
				
				return new CompositeCancelable([
					subscription,
					Cancelable.create(function():void
					{
						subscriptionCount--;
						
						if (subscriptionCount == 0)
						{
							connection.cancel();
							connection = null;
						}
					})
				]);
			});
		}
		
		/**
		 * @inheritDoc
		 */
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			return _subject.subscribeWith(observer);
		}
	}
}