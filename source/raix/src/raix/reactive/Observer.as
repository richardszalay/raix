package raix.reactive
{
	import flash.errors.IllegalOperationError;
	
	/**
	 * Provides static methods that create observers
	 */
	public class Observer
	{
		public function Observer()
		{
			throw new IllegalOperationError("This class is static and cannot be instantiated. Create an IObserver by calling Observer.create");
		}
		
		/**
		 * Creates an IObserver from onNext, onCompleted and onError functions
		 * 
		 * @param onNext The function to call when a value is received
		 * @param onCompleted The function to call when the sequence has complted
		 * @param onError The function to call if an error occurs in the sequence 
		 */
		public static function create(onNext : Function, onCompleted : Function = null, 
			onError : Function = null) : IObserver
		{
			return new ClosureObserver(onNext, onCompleted, onError);
		}

	}
}