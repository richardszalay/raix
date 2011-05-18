package raix.reactive
{
	import raix.reactive.ICancelable;
	
	/**
	 * Represents a cancelable operation, the canceled status of which can 
	 * be checked by isCanceled 
	*/
	public class BooleanCancelable implements ICancelable
	{
		private var _isCanceled : Boolean = false;
		
		public function BooleanCancelable()
		{
		}
		
		/**
		 * Cancels the operation. isCanceled will return true after this call.
		 */
		public function cancel() : void
		{
			_isCanceled = true;
		}
		
		/**
		 * Determines if canceled() has been called on this instance
		 */
		public function get isCanceled() : Boolean
		{
			return _isCanceled;
		}
	}
}