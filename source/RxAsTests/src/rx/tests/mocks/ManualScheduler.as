package rx.tests.mocks
{
	import rx.impl.ClosureScheduledAction;
	import rx.scheduling.IScheduledAction;
	import rx.scheduling.IScheduler;
	
	public class ManualScheduler implements IScheduler
	{
		private var _buffer : Array;
		
		public function ManualScheduler()
		{
			_buffer = new Array();
		}

		public function schedule(action:Function, dueTime:int=0):IScheduledAction
		{
			_buffer.push(action);
			
			return new ClosureScheduledAction(function():void
			{
				throw new Error("Not supported");
			});
		}
		
		public function runNext() : void
		{
			if (_buffer.length > 0)
			{
				(_buffer.shift() as Function)();
			}
		}
		
		public function runAll() : void
		{
			while(_buffer.length > 0)
			{
				(_buffer.shift() as Function)();
			}
		}
	}
}