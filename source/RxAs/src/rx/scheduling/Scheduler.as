package rx.scheduling
{
	import rx.*;
	
	public class Scheduler
	{
		public static function get synchronous() : IScheduler
		{
			return immediate;
		}
		
		public static function get asynchronous() : IScheduler
		{
			return greenThread;
		}
		
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
			return synchronous;
		}
		
		public static function scheduleRecursive(scheduler : IScheduler, action : Function, dueTime : int = 0) : ICancelable
		{
			var reschedule : Function = null;
			var scheduledAction : FutureCancelable = new FutureCancelable();
			
			var cancelled : BooleanCancelable = new BooleanCancelable();
			
			reschedule = function():void
			{
				if (!cancelled.isCanceled)
				{
					scheduledAction.innerCancelable = scheduler.schedule(function():void { action(reschedule); }, dueTime);
				}
			};
			
			reschedule();
			
			return new CompositeCancelable([cancelled, scheduledAction]);
		}
	}
}