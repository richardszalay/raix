package raix.reactive
{
	import flash.errors.IllegalOperationError;
	
	import raix.reactive.ClosureCancelable;
	
	/**
	 * Provides static methods that create cancelable resources
	 */
	public class Cancelable
	{
		/**
		 * Creates a cancelable resource that calls a function when canceled
		 *  
		 * @param action The function to call when the resource is canceled 
		 */
		public static function create(action : Function) : ICancelable
		{
			return new ClosureCancelable(action);
		}
		
		/**
		 * Returns a cancelable resource that does nothing when canceled
		 */
		public static function get empty() : ICancelable
		{
			return ClosureCancelable.empty();
		}
		
		public function Cancelable()
		{
			throw new IllegalOperationError("This class is static is not intended to be instantiated");
		}
	}
}