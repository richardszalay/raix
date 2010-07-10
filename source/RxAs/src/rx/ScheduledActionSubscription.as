package rx
{
	import rx.ICancelable;
	import rx.ICancelable;
	
	public class ScheduledActionSubscription implements ICancelable
	{
		private var _scheduledAction : ICancelable;
		
		public function ScheduledActionSubscription(scheduledAction : ICancelable)
		{
			_scheduledAction = scheduledAction;
		}
		
		public function cancel() : void
		{
			_scheduledAction.cancel();
		}
	}
}