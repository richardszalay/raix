package rx
{
	import rx.ICancelable;
	
	/**
	* A cancelable resource than is not immediately available
	*/	
	public class FutureCancelable implements ICancelable
	{
		private var _canceled : Boolean = false;
		private var _innerCancelable : ICancelable = null;
		
		public function FutureCancelable()
		{
		}
		
		/**
		 * Cancels the operation for current and future innerCancelable values
		 */				
		public function cancel() : void
		{
			_canceled = true;
			
			if (_innerCancelable != null)
			{
				_innerCancelable.cancel();
				_innerCancelable = null;
			}
		}
		
		/**
		 * Assigns the cancelable operation.
		 * 
		 * If an existing value exists for innerCancelable, it will be canceled.
		 * 
		 * If cancel() has already been called on this FutureCancelable, the value 
		 * will be instantly canceled and innerCancelable will be null
		 */		 
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