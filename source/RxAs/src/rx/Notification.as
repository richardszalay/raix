package rx
{
	import flash.errors.IllegalOperationError;
	
	public class Notification/*.<T>*/
	{
		public function Notification()
		{
		}
		
		public function accept(observer : IObserver) : void
		{
			acceptFunc(observer.onNext, observer.onCompleted, observer.onError);
		}
		
		public function acceptFunc(onNext : Function, onCompleted : Function = null, 
			onError : Function = null) : void
		{
			throw new IllegalOperationError("accept must be overridden");
		}
		
		public function get hasValue() : Boolean
		{
			throw new IllegalOperationError("hasValue must be overridden");
		}
		
		public function get error() : Error
		{
			throw new IllegalOperationError("hasValue must be overridden");
		}
		
		public function get value() : Object // T
		{
			throw new IllegalOperationError("hasValue must be overridden");
		}
		
		public function get kind() : int
		{
			throw new IllegalOperationError("hasValue must be overridden");
		}
	}
}