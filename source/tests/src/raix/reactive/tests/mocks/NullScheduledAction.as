package raix.reactive.tests.mocks
{
	import raix.reactive.ICancelable;
	
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