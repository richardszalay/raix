package rx.scheduling
{
	import rx.ISubscription;
	
	public interface IScheduler
	{
		function schedule(action : Function, dueTime : int = 0) : IScheduledAction;
		
		function get now() : Date;
	}
}