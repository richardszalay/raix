package rx
{
	import rx.ICancelable;
	
	public class FutureCancelable implements ICancelable
	{
		private var _canceled : Boolean = false;
		private var _innerCancelable : ICancelable = null;
		
		public function FutureCancelable()
		{
		}
		
		public function cancel() : void
		{
			_canceled = true;
			
			if (_innerCancelable != null)
			{
				_innerCancelable.cancel();
				_innerCancelable = null;
			}
		}
		
		public function set innerCancelable(value : ICancelable) : void
		{
			if (_innerCancelable != null)
			{
				_innerCancelable.cancel();
				_innerCancelable = null;
			}
			
			if (_canceled)
			{
				value.cancel();
			}
			else
			{
				_innerCancelable = value;
			}
		}
	}
}