package raix.reactive.scheduling
{
	import raix.reactive.ICancelable;
	
	/**
	 * Used to distribute workload
	 */	
	public interface IScheduler
	{
		/**
		 * Schedules a function to be run, either immediately or in the future 
		 * @param action The function to run
		 * @param dueTime The time, in milliseconds, after which action should be executed. If 0, action should be executed at the first available opportunity
		 * @return An ICancelable that will stop the action from being run, if it hasn't already
		 */		
		function schedule(action : Function, dueTime : int = 0) : ICancelable;
		
		/**
		 * Gets the current Date and time
		 */		
		function get now() : Date;
	}
}