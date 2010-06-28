package rx.subjects
{
	import rx.AbsObservable;
	import rx.ICancelable;
	import rx.IObservable;
	import rx.IObserver;
	import rx.ISubject;
	import rx.Subject;
	import rx.impl.ClosureObservable;
	import rx.impl.ClosureCancelable;
	import rx.impl.CompositeCancelable;

	public class ConnectableObservable extends AbsObservable implements IConnectableObservable
	{
		private var _subscription : ICancelable;
		private var _source : IObservable;
		private var _subject : ISubject;
		
		public function ConnectableObservable(source : IObservable, subject : ISubject = null)
		{
			// TODO: Assert source != null
			// TODO: Assert source.type = subject.type
			
			_source = source.asObservable();
			_subject = subject || new Subject(source.type);
		}
		
		public function connect():ICancelable
		{
			var hasSubscription : Boolean = (_subscription != null);
			
			if (!hasSubscription)
			{
				_subscription = new CompositeCancelable([
					new ClosureCancelable(function():void { _subscription = null; }),
					_source.subscribeWith(_subject)
					]);
			}
			
			return _subscription;
		}
		
		public function refCount() : IObservable
		{
			var source : IConnectableObservable = this;
			
			var connection : ICancelable = null;
			var subscriptionCount : uint = 0;
			
			return new ClosureObservable(this.type, function(observer : IObserver) : ICancelable
			{
				subscriptionCount++;
				
				var subscription : ICancelable = source.subscribeWith(observer);
				
				if (subscriptionCount == 1)
				{
					connection = source.connect();
				}
				
				return new CompositeCancelable([
					subscription,
					new ClosureCancelable(function():void
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
		
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			return _subject.subscribeWith(observer);
		}
	}
}