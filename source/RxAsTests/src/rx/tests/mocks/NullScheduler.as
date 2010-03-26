package rx.tests.mocks
{
	import rx.scheduling.IScheduledAction;
	import rx.scheduling.IScheduler;

	public class NullScheduler implements IScheduler
	{
		public function schedule(action:Function, dueTime:int=0):IScheduledAction
		{
			return new NullScheduledAction();
		}
		
	}
}