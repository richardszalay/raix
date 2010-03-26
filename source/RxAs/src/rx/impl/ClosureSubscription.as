package rx.impl
{
	import rx.ISubscription;
	
	public class ClosureSubscription implements ISubscription
	{
		private var _unsubscribeFunc : Function;
		private var _isUnsubscribed : Boolean = false;
		
		public function ClosureSubscription(unsubscribeFunc : Function)
		{
			_unsubscribeFunc = unsubscribeFunc;
		}
		
		public function unsubscribe() : void
		{
			if (!_isUnsubscribed)
			{
				_isUnsubscribed = true;
				_unsubscribeFunc(); 
			}
		}

	}
}