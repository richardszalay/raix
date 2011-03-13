package rx.scheduling
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	internal class TimerPool
	{
		private var _pool : Array = new Array();
		
		private var _capacity : int;
		
		private var _createCount : int = 0;
		private var _maxCreated : int = 0;
		
		public function TimerPool(capacity : int)
		{
			_capacity = capacity;
		}
		
		public function obtain() : Timer
		{
			_createCount++;
			
			if (_maxCreated < _createCount)
			{
				_maxCreated = _createCount;
			}
			
			if (size > 0)
			{
				return _pool.shift() as Timer;
			}
			else
			{
				return new Timer(0);
			}
		}
		
		public function release(timer : Timer) : void
		{
			_createCount--;
			
			if (timer.running)
			{
				throw new ArgumentError("Cannot release Timer that is still in use");
			}
			
			if (timer.hasEventListener(TimerEvent.TIMER) ||
				timer.hasEventListener(TimerEvent.TIMER_COMPLETE))
			{
				throw new ArgumentError("Cannot release Timer that still has event subscriptions");
			}
			
			var reuse : Boolean = (size < _capacity);
			
			if (reuse)
			{
				_pool.push(timer);
			}
		}
		
		public function get size() : int
		{
			return _pool.length;
		}
		
		private static const DEFAULT_CAPACITY : int = 10;
		private static var _instance : TimerPool = new TimerPool(DEFAULT_CAPACITY);
		
		public static function get instance() : TimerPool
		{
			return _instance;
		}
	}
}