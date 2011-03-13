package raix.reactive.tests.mocks
{
	import raix.reactive.ICancelable;
	import raix.reactive.scheduling.IScheduler;

	public class ClosureScheduler implements IScheduler
	{
		private var _scheduleFunc : Function;
		
		public function ClosureScheduler(scheduleFunc : Function)
		{
			_scheduleFunc = scheduleFunc;
		}

		public function schedule(action:Function, dueTime:int=0):ICancelable
		{
			return ICancelable(_scheduleFunc(action, dueTime));
		}
		
		private var _now : Date = new Date();
		
		public function get now() : Date { return _now; }
		public function set now(value : Date) : void { _now = value; }
	}
}