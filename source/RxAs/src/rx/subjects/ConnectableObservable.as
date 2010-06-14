package rx.subjects
{
	import rx.AbsObservable;
	import rx.ICancelable;
	import rx.IObservable;
	import rx.IObserver;
	import rx.ISubject;
	import rx.Subject;
	import rx.impl.ClosureObservable;
	import rx.impl.ClosureSubscription;
	import rx.impl.CompositeSubscription;

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
				_subscription = new CompositeSubscription([
					new ClosureSubscription(function():void { _subscription = null; }),
					_source.subscribe(_subject)
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
				
				var subscription : ICancelable = source.subscribe(observer);
				
				if (subscriptionCount == 1)
				{
					connection = source.connect();
				}
				
				return new CompositeSubscription([
					subscription,
					new ClosureSubscription(function():void
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
		
		public override function subscribe(observer:IObserver):ICancelable
		{
			return _subject.subscribe(observer);
		}
	}
}