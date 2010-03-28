package rx.tests.operators
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import rx.IObservable;
	import rx.TimeStamped;
	import rx.tests.mocks.ManualObservable;
	import rx.tests.mocks.ManualScheduler;
	
	[TestCase]
	public class TimestampFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.timestamp();
		}
		
		[Test(async)]
		public function timestamp_is_applied_to_values() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.timestamp();
			
			var nextValues : Array = new Array();
			
			obs.subscribeFunc(function(pl:TimeStamped):void
			{
				nextValues.push(pl);
			});
			
			manObs.onNext(5);
			
			// Wait past the throttle timeframe (+5ms to be sure)
			Async.asyncHandler(this, function():void{}, 55, null, function():void
			{
				manObs.onNext(10);
			
				Assert.assertEquals(2, nextValues.length);
				
				var tsA : TimeStamped = nextValues[0];
				var tsB : TimeStamped = nextValues[1];
				
				Assert.assertEquals(5, tsA.value);
				Assert.assertEquals(10, tsB.value);
				
				Assert.assertTrue(tsB.timestamp > tsA.timestamp); 
			});
		}
		
		[Test(async)]
		public function timestamp_is_applied_at_time_of_scheduling() : void
		{
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.timestamp(scheduler);
			
			var nextValues : Array = new Array();
			
			obs.subscribeFunc(function(pl:TimeStamped):void
			{
				nextValues.push(pl);
			});
			
			manObs.onNext(5);
			
			// Wait past the throttle timeframe (+5ms to be sure)
			Async.asyncHandler(this, function():void{}, 55, null, function():void
			{
				manObs.onNext(10);
			
				Assert.assertEquals(0, nextValues.length);
				
				scheduler.runAll();
				Assert.assertEquals(2, nextValues.length);
				
				var tsA : TimeStamped = nextValues[0];
				var tsB : TimeStamped = nextValues[1];
				
				var diffMs : Number = tsB.timestamp - tsA.timestamp;
				
				Assert.assertTrue(diffMs > 50); 
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