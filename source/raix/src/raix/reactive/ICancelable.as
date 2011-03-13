package raix.reactive
{
	/**
	 * Represents a handle that can be used to cancel an operation 
	 * 
	 * @see rx.CompositeCancelable, rx.BooleanCancelable, rx.FutureCancelable, rx.Cancelable
	*/	
	public interface ICancelable
	{
		/**
		 * Cancels the operation
		 */
		function cancel() : void;
	}
}