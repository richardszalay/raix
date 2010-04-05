package rx.impl
{
	import rx.ISubscription;
	
	public class FutureSubscription implements ISubscription
	{
		private var _unsubscribed : Boolean = false;
		private var _innerSubscription : ISubscription = null;
		
		public function FutureSubscription()
		{
		}
		
		public function unsubscribe() : void
		{
			_unsubscribed = true;
			
			if (_innerSubscription != null)
			{
				_innerSubscription.unsubscribe();
				_innerSubscription = null;
			}
		}
		
		public function set innerSubscription(value : ISubscription) : void
		{
			if (_unsubscribed)
			{
				value.unsubscribe();
			}
			else
			{
				_innerSubscription = value;
			}
		}
	}
}