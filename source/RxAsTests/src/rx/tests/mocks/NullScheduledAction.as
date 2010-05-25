package rx.tests.mocks
{
	import rx.scheduling.IScheduledAction;
	
	public class NullScheduledAction implements IScheduledAction
	{
		public function NullScheduledAction()
		{
		}
		
		public function cancel() : void
		{
		}
	}
}