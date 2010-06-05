package rx.impl
{
	import rx.ICancelable;
	
	public class ClosureScheduledAction implements ICancelable
	{
		private var _cancelFunc : Function;
		private var _isCancelled : Boolean = false;
		
		public function ClosureScheduledAction(cancelFunc : Function)
		{
			_cancelFunc = cancelFunc;
		}
		
		public function cancel() : void
		{
			if (!_isCancelled)
			{
				_isCancelled = true;
				_cancelFunc();
			}
		}
		
		public static function empty() : ICancelable
		{
			return new ClosureScheduledAction(function():void{});
		}

	}
}