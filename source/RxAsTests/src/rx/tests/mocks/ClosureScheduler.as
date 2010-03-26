package rx.tests.mocks
{
	import rx.scheduling.IScheduledAction;
	import rx.scheduling.IScheduler;

	public class ClosureScheduler implements IScheduler
	{
		private var _scheduleFunc : Function;
		
		public function ClosureScheduler(scheduleFunc : Function)
		{
			_scheduleFunc = scheduleFunc;
		}

		public function schedule(action:Function, dueTime:int=0):IScheduledAction
		{
			return IScheduledAction(_scheduleFunc(action, dueTime));
		}
	}
}