package rx
{
	/**
	 * An object that receives messages from an IObservable sequence
	 * 
	 * @see Observer
	 */
	public interface IObserver
	{
		/**
		 * Notifies the subscriber that the sequence has completed and 
		 * that no more messages will be received
		 */
		function onCompleted() : void;
		
		/**
		 * Notifies the subscriber that the sequence has halted with an error 
		 * and that no more messages will be received
		 */
    	function onError(error : Error) : void;
    	
		/**
		 * Notifies the subscriber that a value has been received
		 */
    	function onNext(value : Object) : void;
	}
}