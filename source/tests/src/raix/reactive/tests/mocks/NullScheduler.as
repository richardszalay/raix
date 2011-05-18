package raix.reactive.tests.mocks
{
	import raix.reactive.ICancelable;
	import raix.reactive.scheduling.IScheduler;

	public class NullScheduler implements IScheduler
	{
		public function schedule(action:Function, dueTime:int=0):ICancelable
		{
			return new NullScheduledAction();
		}
		
		private var _now : Date = new Date();
		
		public function get now() : Date { return _now; }
		public function set now(value : Date) : void { _now = value; }
		
	}
}