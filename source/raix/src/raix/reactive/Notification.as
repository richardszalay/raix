package raix.reactive
{
	import flash.errors.IllegalOperationError;
	
	/**
	 * Represents one of the three messages that can be sent to 
	 * an observer.
	 * 
	 * @see rx.OnNext 
	 * @see rx.OnCompleted 
	 * @see rx.OnError
	 */
	public /*abstract*/ class Notification/*.<T>*/
	{
		public function Notification()
		{
		}
		
		/**
		 * Calls the appropriate method on an observer
		 */
		public function acceptWith(observer : IObserver) : void
		{
			accept(observer.onNext, observer.onCompleted, observer.onError);
		}
		
		/**
		 * Calls the appropriate method
		 */
		public function accept(onNext : Function, onCompleted : Function = null, 
			onError : Function = null) : void
		{
			throw new IllegalOperationError("accept must be overridden");
		}
		
		/**
		 * Determined whether this instance has a value property available
		 */
		public function get hasValue() : Boolean
		{
			throw new IllegalOperationError("hasValue must be overridden");
		}
		
		/**
		 * Gets the error associated with this message or null if there is no error.
		 */
		public function get error() : Error
		{
			throw new IllegalOperationError("hasValue must be overridden");
		}
		
		/**
		 * Gets the value associated with this message
		 */
		public function get value() : Object // T
		{
			throw new IllegalOperationError("hasValue must be overridden");
		}
		
		/**
		 * Gets the NotificationKind of this instance
		 */
		public function get kind() : int
		{
			throw new IllegalOperationError("hasValue must be overridden");
		}
	}
}