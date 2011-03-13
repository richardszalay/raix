package raix.reactive.tests.operators.creation
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import raix.reactive.IObservable;
	import raix.reactive.ICancelable;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.IScheduler;
	import raix.reactive.tests.mocks.NullScheduler;
	
	[TestCase]
	public class NeverFixture
	{
		[Test(async)]
		public function does_not_call_any_methods_on_observer() : void
		{
			var obs : IObservable = Observable.never();
			
			var wasCalled : Boolean = false;
			
			var timeoutHandler : Function = function():void {
				Assert.assertFalse(wasCalled);
			};
			
			obs.subscribe(
				function():void { wasCalled = true; },
				function():void { wasCalled = true; },
				function():void { wasCalled = true; }
			);
			
			Async.asyncHandler(this, function():void {}, 200, null, timeoutHandler)
		}
	}
}