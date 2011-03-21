package raix.reactive.tests.operators.mutation
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.OnCompleted;
	import raix.reactive.OnNext;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	import raix.reactive.tests.AssertEx;
	import raix.reactive.tests.mocks.StatsObserver;
	
	[TestCase]
	public class BufferWithTimeOrCount
	{
		[Test]
		public function values_can_be_triggered_by_time_or_count() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			
			var source : IObservable = scheduler.createColdObservable([
				// start #1 (@0)
				new Recorded(10, new OnNext(1)),
				new Recorded(12, new OnNext(2)),
				new Recorded(14, new OnNext(3)),
				// start #2 (@15)
				new Recorded(16, new OnNext(4)),
				new Recorded(20, new OnNext(5)),
				new Recorded(24, new OnNext(6)),				
				new Recorded(28, new OnNext(7)),				
				// start #3 (@28)
				// start #4 (@34)
				new Recorded(50, new OnNext(8)),
				new Recorded(51, new OnCompleted())
			]);
			
			var stats : StatsObserver = new StatsObserver();
			
			var value : int = 0;
			
			source.bufferWithTimeOrCount(15, 4, scheduler)
				.subscribeWith(stats);
			
			scheduler.run();
			
			Assert.assertEquals(4, stats.nextCount);
			Assert.assertEquals(3, stats.nextValues[0].length);
			Assert.assertEquals(4, stats.nextValues[1].length);
			Assert.assertEquals(0, stats.nextValues[2].length);
			Assert.assertEquals(1, stats.nextValues[3].length);
		}
	}
}
