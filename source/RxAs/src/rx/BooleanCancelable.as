package rx
{
	import rx.ICancelable;
	
	public class BooleanCancelable implements ICancelable
	{
		private var _isCanceled : Boolean = false;
		
		public function BooleanCancelable()
		{
		}
		
		public function cancel() : void
		{
			_isCanceled = true;
		}
		
		public function get isCanceled() : Boolean
		{
			return _isCanceled;
		}
	}
}