package rx
{
	import flash.errors.IllegalOperationError;
	
	public class Subject extends AbsObservable implements IObserver
	{
		public function Subject()
		{
		}
		
		public function onNext(payload : Object) : void
		{
		}
		
		public function onCompleted() : void
		{
		}
		
		public function onError(error : Error) : void
		{
		}
	}
}