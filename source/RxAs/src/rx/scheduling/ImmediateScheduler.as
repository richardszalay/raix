package rx.scheduling
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import rx.impl.ClosureScheduledAction;
	import rx.impl.TimerPool;
	
	public class ImmediateScheduler implements IScheduler
	{
		public function schedule(action : Function, dueTime : int = 0) : IScheduledAction
		{
			if (dueTime != 0)
			{
				var timer : Timer = TimerPool.instance.obtain();
				timer.repeatCount = 1;
				timer.delay = dueTime;
				
				var handler : Function = function():void
				{
					timer.stop();
					timer.removeEventListener(TimerEvent.TIMER, handler);
					TimerPool.instance.release(timer);
					
					action();
				};
				
				timer.addEventListener(TimerEvent.TIMER, handler);
				timer.start();
			}
			else
			{
				action();
			}
			
			return ClosureScheduledAction.empty();
		}
		
		private static var _instance : ImmediateScheduler = new ImmediateScheduler();
		
		public static function get instance() : ImmediateScheduler 
		{
			return _instance;
		}
	}
}