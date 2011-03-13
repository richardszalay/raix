package rx.tests.operators.metadata
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	import rx.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class TimestampFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.timestamp();
		}
		
		[Test]
		public function timestamp_is_applied_to_values() : void
		{
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.timestamp(scheduler);
			
			var nextValues : Array = new Array();
			
			var startTime : Date = new Date();
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			scheduler.now = startTime;			
			manObs.onNext(1);
			
			scheduler.now = new Date(startTime.time + 10);			
			manObs.onNext(2);
			
			scheduler.now = new Date(startTime.time + 20);			
			manObs.onNext(3);
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(startTime.time, stats.nextValues[0].timestamp);
			Assert.assertEquals(startTime.time + 10, stats.nextValues[1].timestamp);
			Assert.assertEquals(startTime.time + 20, stats.nextValues[2].timestamp);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.throttle(5);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}