package raix.reactive
{
	/**
	 * Represents a handle that can be used to cancel an operation 
	 * 
	 * @see raix.reactive.CompositeCancelable, raix.reactive.BooleanCancelable, raix.reactive.FutureCancelable, raix.reactive.Cancelable
	*/	
	public interface ICancelable
	{
		/**
		 * Cancels the operation
		 */
		function cancel() : void;
	}
}