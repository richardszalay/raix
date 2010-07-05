package rx
{
	import flash.errors.IllegalOperationError;
	
	import rx.impl.ClosureCancelable;
	
	public class Cancelable
	{
		public static ICancelable create(action : Function) : ICancelable
		{
			return new ClosureCancelable(action);
		});
		
		public function Cancelable()
		{
			throw new IllegalOperationError("This class is static is not intended to be instantiated");
		}

	}
}