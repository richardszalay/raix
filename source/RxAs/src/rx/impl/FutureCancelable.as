package rx.impl
{
	import rx.ICancelable;
	
	public class FutureCancelable implements ICancelable
	{
		private var _unsubscribed : Boolean = false;
		private var _innerSubscription : ICancelable = null;
		
		public function FutureCancelable()
		{
		}
		
		public function cancel() : void
		{
			_unsubscribed = true;
			
			if (_innerSubscription != null)
			{
				_innerSubscription.cancel();
				_innerSubscription = null;
			}
		}
		
		public function set innerSubscription(value : ICancelable) : void
		{
			if (_innerSubscription != null)
			{
				_innerSubscription.cancel();
				_innerSubscription = null;
			}
			
			if (_unsubscribed)
			{
				value.cancel();
			}
			else
			{
				_innerSubscription = value;
			}
		}
	}
}