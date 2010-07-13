package rx
{
	/**
	* Represents a handle that can be used to 
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