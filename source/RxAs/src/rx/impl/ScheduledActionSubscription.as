package rx.impl
{
	import rx.ISubscription;
	import rx.scheduling.IScheduledAction;
	
	public class ScheduledActionSubscription implements ISubscription
	{
		private var _scheduledAction : IScheduledAction;
		
		public function ScheduledActionSubscription(scheduledAction : IScheduledAction)
		{
			_scheduledAction = scheduledAction;
		}
		
		public function unsubscribe() : void
		{
			_scheduledAction.cancel();
		}
	}
}