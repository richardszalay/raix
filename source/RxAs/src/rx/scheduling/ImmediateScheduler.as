package rx.scheduling
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import rx.impl.ClosureScheduledAction;
	
	public class ImmediateScheduler implements IScheduler
	{
		public function schedule(action : Function, dueTime : int = 0) : IScheduledAction
		{
			if (dueTime != 0)
			{
				var timer : Timer = new Timer(dueTime, 1);
				timer.addEventListener(TimerEvent.TIMER, action);
				timer.start()
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