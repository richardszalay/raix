package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.Observable;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class BufferWithTimeFixture
	{
		[Test(async)]
		public function values_are_buffered_in_specified_time() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var valueScheduler : ManualScheduler = new ManualScheduler();
			var bufferScheduler : ManualScheduler = new ManualScheduler();
			
			var startTime : Date = new Date();
			
			Observable.range(0, 5, valueScheduler)
				.bufferWithTime(120, 0, bufferScheduler)
				.subscribe(stats);
			
			Assert.assertFalse(stats.nextCalled);
			
			bufferScheduler.now = new Date(startTime.time + 10);
			valueScheduler.runNext();
			
			bufferScheduler.now = new Date(startTime.time + 20);
			valueScheduler.runNext();
			
			bufferScheduler.runNext();
			
			Assert.assertEquals(1, stats.nextCount);
		}
	}
}
