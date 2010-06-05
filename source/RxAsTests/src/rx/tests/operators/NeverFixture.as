package rx.tests.operators
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import rx.IObservable;
	import rx.ICancelable;
	import rx.Observable;
	import rx.scheduling.IScheduler;
	import rx.tests.mocks.NullScheduler;
	
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
			
			obs.subscribeFunc(
				function():void { wasCalled = true; },
				function():void { wasCalled = true; },
				function():void { wasCalled = true; }
			);
			
			Async.asyncHandler(this, function():void {}, 200, null, timeoutHandler)
		}
	}
}