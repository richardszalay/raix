package rx
{
	import flash.errors.IllegalOperationError;
	
	import rx.ClosureCancelable;
	
	public class Cancelable
	{
		public static function create(action : Function) : ICancelable
		{
			return new ClosureCancelable(action);
		}
		
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