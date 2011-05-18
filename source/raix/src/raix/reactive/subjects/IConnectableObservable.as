package raix.reactive.subjects
{
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	
	/**
	 * Represents a 'pending' hot observable. Calling connect will turn the observable 
	 * into a hot observable. Calling refCount will turn the observable into a hot observable 
	 * when the first observer subscribes
	 */	
	public interface IConnectableObservable extends IObservable
	{
		/**
		 * Makes this observable 'hot', so that values will be 
		 * emitted whether there is a subscriber connected or not.
		 */
		function connect() : ICancelable;
		
		/**
		 * Makes this observable 'hot' when an observer subscribes, and 
		 * will cancel the source subscription when the last observer unsubscribes
		 */
		function refCount() : IObservable;
	}
}