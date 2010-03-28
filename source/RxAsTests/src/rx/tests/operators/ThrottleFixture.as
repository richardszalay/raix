package rx.tests.operators
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import rx.IObservable;
	import rx.tests.mocks.ManualObservable;
	
	[TestCase]
	public class ThrottleFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.throttle(0);
		}
		
		[Test(async)]
		public function values_are_throttled_within_specified_timeframe() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.throttle(50);
			
			var nextCount : uint = 0;
			
			obs.subscribeFunc(function(pl:int):void
			{
				nextCount++;
			});
			
			manObs.onNext(1); // piped
			manObs.onNext(1); // ignored
			manObs.onNext(1); // ignored
			manObs.onNext(1); // ignored
			
			Assert.assertEquals(1, nextCount);
			
			// Wait past the throttle timeframe (+5ms to be sure)
			Async.asyncHandler(this, function():void{}, 55, null, function():void
			{
				manObs.onNext(1); // piped
				manObs.onNext(2); // ignored
			
				Assert.assertEquals(2, nextCount);
			});
		}

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.throttle(5);
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}