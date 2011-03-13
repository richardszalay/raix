package rx.tests.mocks
{
	import rx.ICancelable;
	
	public class NullScheduledAction implements ICancelable
	{
		public function NullScheduledAction()
		{
		}
		
		public function cancel() : void
		{
		}
	}
}