package rx
{
	import rx.ICancelable;
	
	internal class ClosureCancelable implements ICancelable
	{
		private var _unsubscribeFunc : Function;
		private var _isUnsubscribed : Boolean = false;
		
		public function ClosureCancelable(unsubscribeFunc : Function)
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
		
		public static function empty() : ClosureCancelable
		{
			return new ClosureCancelable(function():void{});
		}

	}
}