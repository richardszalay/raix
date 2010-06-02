package rx.impl
{
	import rx.ICancelable;
	
	public class ClosureSubscription implements ICancelable
	{
		private var _unsubscribeFunc : Function;
		private var _isUnsubscribed : Boolean = false;
		
		public function ClosureSubscription(unsubscribeFunc : Function)
		{
			_unsubscribeFunc = unsubscribeFunc;
		}
		
		public function cancel() : void
		{
			if (!_isUnsubscribed)
			{
				_isUnsubscribed = true;
				_unsubscribeFunc(); 
			}
		}

	}
}