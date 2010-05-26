package rx.scheduling
{
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
		
		public static function scheduleRecursive(scheduler : IScheduler, action : Function) : IScheduledAction
		{
			var reschedule : Function = null;
			var scheduledAction : IScheduledAction = null;
			
			reschedule = function():void
			{
				scheduledAction = scheduler.schedule(function():void { action(reschedule); });
			};
			
			reschedule();
			
			return new ClosureScheduledAction(function():void
			{
				scheduledAction.cancel();
			});
		}
	}
}