package raix.reactive.scheduling
{
	import raix.reactive.*;
	
	/**
	 * Provides static helpers to schedulers
	 */
	public class Scheduler
	{
		/**
		 * Gets the default synchronous scheduler
		 */
		public static function get synchronous() : IScheduler
		{
			return immediate;
		}
		
		/**
		 * Gets the default asynchronous scheduler
		 */
		public static function get asynchronous() : IScheduler
		{
			return greenThread;
		}
		
		/**
		 * Gets the ImmediateScheduler singleton instance
		 */
		public static function get immediate() : ImmediateScheduler
		{
			return ImmediateScheduler.instance;
		}
		
		/**
		 * Gets the GreenThreadScheduler singleton instance
		 */
		public static function get greenThread() : GreenThreadScheduler
		{
			return GreenThreadScheduler.instance;
		}
		
		/**
		 * Gets the default scheduler
		 */
		public static function get defaultScheduler() : IScheduler
		{
			return synchronous;
		}
		
		/**
		 * Schedules a recursive action on an IScheduler 
		 * @param scheduler The scheduler that will schedule each recursive call
		 * @param action The action to call. The action will be called with one argument: a Function that call be called to reschedule the original action
		 * @param dueTime The amount of time to delay the call to ation
		 * @return An ICancelable that can be used to cancel the recursive schedule at any time
		 */		
		public static function scheduleRecursive(scheduler : IScheduler, action : Function, dueTime : int = 0) : ICancelable
		{
			var reschedule : Function = null;
			var scheduledAction : MutableCancelable = new MutableCancelable();
			
			var cancelled : BooleanCancelable = new BooleanCancelable();
			
			reschedule = function():void
			{
				if (!cancelled.isCanceled)
				{
					scheduledAction.cancelable = scheduler.schedule(function():void { action(reschedule); }, dueTime);
				}
			};
			
			reschedule();
			
			return new CompositeCancelable([cancelled, scheduledAction]);
		}
	}
}