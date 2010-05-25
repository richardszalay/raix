package rx.scheduling
{
	import rx.ISubscription;
	
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
	}
}