package rx.scheduling
{
	import rx.ICancelable;
	
	public interface IScheduler
	{
		function schedule(action : Function, dueTime : int = 0) : ICancelable;
		
		function get now() : Date;
	}
}