package rx.scheduling
{
	import rx.ICancelable;
	
	import rx.impl.ClosureScheduledAction;
	
	public class Scheduler
	{
		public static function get immediate() : ImmediateScheduler
		{
			return ImmediateScheduler.instance;
		}
		
		public static function get greenThread() : GreenThreadScheduler
		{
			return GreenThreadScheduler.instance;
		}
		
		public static function get defaultScheduler() : IScheduler
		{
			return immediate;
		}
		
		public static function scheduleRecursive(scheduler : IScheduler, action : Function, dueTime : int = 0) : ICancelable
		{
			var reschedule : Function = null;
			var scheduledAction : ICancelable = null;
			
			var cancelled : Boolean = false;
			
			reschedule = function():void
			{
				if (!cancelled)
				{
					scheduledAction = scheduler.schedule(function():void { action(reschedule); }, dueTime);
				}
			};
			
			reschedule();
			
			return new ClosureScheduledAction(function():void
			{
				cancelled = true;
				scheduledAction.cancel();
			});
		}
	}
}