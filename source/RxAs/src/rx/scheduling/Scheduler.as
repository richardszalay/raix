package rx.scheduling
{
	import rx.ISubscription;
	
	public class Scheduler
	{
		public static function get defaultScheduler() : IScheduler
		{
			return ImmediateScheduler.instance;
		}
	}
}