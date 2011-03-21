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
	public class BufferWithTimeFixture
	{
		[Test]
		public function values_are_buffered_in_specified_time() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			
			var source : IObservable = scheduler.createColdObservable([
				// start #1 (@0)
				new Recorded(10, new OnNext(1)),
				new Recorded(12, new OnNext(2)),
				// start #2 (@15)
				// start #3 (@30)
				new Recorded(40, new OnNext(3)),
				// start #4 (@45)
				new Recorded(50, new OnNext(4)),
				new Recorded(51, new OnCompleted())
			]);
			
			
			var stats : StatsObserver = new StatsObserver();
			
			var value : int = 0;
			
			source.bufferWithTime(15, 0, scheduler)
				.subscribeWith(stats);
			
			scheduler.run();
			
			Assert.assertEquals(4, stats.nextCount);
			Assert.assertEquals(2, stats.nextValues[0].length);
			Assert.assertEquals(0, stats.nextValues[1].length);
			Assert.assertEquals(1, stats.nextValues[2].length);
			Assert.assertEquals(1, stats.nextValues[3].length);
		}
		
		[Test]
		public function time_shifted_values_make_it_into_the_next_window() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			
			var source : IObservable = scheduler.createColdObservable([
				// start #1 (@0)
				// start #2 (@10) <-- happens before subscribe so its before the first value
				new Recorded(10, new OnNext(1)),
				new Recorded(12, new OnNext(2)),
				// end #1 (@15)
				// start #3 (@20)
				// end #2 (@25)
				// start #4 (@30)
				// end #3 (@35)
				new Recorded(40, new OnNext(3)),
				// start #5 (@40)
				// end #4 (@45)
				new Recorded(50, new OnNext(4)),
				// start #6 (@50)
				new Recorded(51, new OnCompleted())
			]);
			
			var stats : StatsObserver = new StatsObserver();
			
			source.bufferWithTime(15, 10, scheduler)
				.subscribeWith(stats);
			
			scheduler.run();
			
			Assert.assertEquals(6, stats.nextCount);
			Assert.assertEquals(2, stats.nextValues[0].length);
			Assert.assertEquals(2, stats.nextValues[1].length);
			Assert.assertEquals(0, stats.nextValues[2].length);
			Assert.assertEquals(1, stats.nextValues[3].length);
			Assert.assertEquals(1, stats.nextValues[4].length);
			Assert.assertEquals(0, stats.nextValues[5].length);
			
			AssertEx.assertArrayEquals([1, 2], stats.nextValues[0]);
			AssertEx.assertArrayEquals([1, 2], stats.nextValues[1]);
			AssertEx.assertArrayEquals([3], stats.nextValues[3]);
			AssertEx.assertArrayEquals([4], stats.nextValues[4]);
		}
	}
}
