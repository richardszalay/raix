package raix.reactive.tests.mocks
{
	import raix.reactive.ICancelable;
	import raix.reactive.Cancelable;
	import raix.reactive.scheduling.IScheduler;
	
	public class ManualScheduler implements IScheduler
	{
		private var _buffer : Array;
		
		public function ManualScheduler()
		{
			_buffer = new Array();
		}

		public function schedule(action:Function, dueTime:int=0):ICancelable
		{
			_buffer.push(action);
			
			return Cancelable.create(function():void
			{
				for (var i:int=0; i<_buffer.length; i++)
				{
					if (_buffer[i] == action)
					{
						_buffer.splice(i, 1);
						break;
					}
				}
			});
		}
		
		public function get queueSize() : int 
		{
			return _buffer.length;
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
		
		private var _now : Date = new Date();
		
		public function get now() : Date { return _now; }
		public function set now(value : Date) : void { _now = value; }
	}
}