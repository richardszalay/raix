package raix.reactive
{
	import raix.reactive.ICancelable;
	
	/**
	* A cancelable resource than is not immediately available
	*/	
	public class MutableCancelable implements ICancelable
	{
		private var _canceled : Boolean = false;
		private var _cancelable : ICancelable = null;
		
		public function MutableCancelable()
		{
		}
		
		/**
		 * Cancels the operation for current and future innerCancelable values
		 */				
		public function cancel() : void
		{
			_canceled = true;
			
			if (_cancelable != null)
			{
				_cancelable.cancel();
				_cancelable = null;
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
		public function set cancelable(value : ICancelable) : void
		{
			if (_cancelable != null)
			{
				_cancelable.cancel();
				_cancelable = null;
			}
			
			if (_canceled)
			{
				value.cancel();
			}
			else
			{
				_cancelable = value;
			}
		}
	}
}