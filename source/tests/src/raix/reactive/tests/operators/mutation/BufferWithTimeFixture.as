package raix.reactive.tests.operators.mutation
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.OnCompleted;
	import raix.reactive.OnNext;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	[TestCase]
	public class BufferWithTimeFixture
	{
		[Test]
		public function values_are_buffered_in_specified_time() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			
			var source : IObservable = scheduler.createColdObservable([
				new Recorded(0, new OnNext(1)),
				new Recorded(10, new OnNext(2)),
				new Recorded(20, new OnNext(3)),
				new Recorded(30, new OnNext(4)),
				new Recorded(31, new OnCompleted())
			]);
			
			var stats : StatsObserver = new StatsObserver();
			
			source.bufferWithTime(15, 0, scheduler)
				.subscribeWith(stats);
			
			scheduler.run();
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(2, stats.nextValues[0].length);
			Assert.assertEquals(2, stats.nextValues[1].length);
			Assert.assertEquals(0, stats.nextValues[2].length);
		}
		
		/*
		[Test]
		public function values_are_includes_from_previous_offsets() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var valueScheduler : ManualScheduler = new ManualScheduler();
			var bufferScheduler : ManualScheduler = new ManualScheduler();
			
			var startTime : Date = new Date();
			
			Observable.range(0, 5, valueScheduler)
				.bufferWithTime(30, 20, bufferScheduler)
				.subscribeWith(stats);
			
			Assert.assertFalse(stats.nextCalled);
			
			bufferScheduler.now = new Date(startTime.time + 10);
			valueScheduler.runNext();
			
			bufferScheduler.now = new Date(startTime.time + 30);
			valueScheduler.runNext();
			
			bufferScheduler.now = new Date(startTime.time + 40);
			valueScheduler.runNext();
			
			bufferScheduler.runNext();
			bufferScheduler.runNext();
			
			Assert.assertEquals(2, stats.nextCount);
			Assert.assertEquals(3, stats.nextValues[0].length);
			Assert.assertEquals(0, stats.nextValues[0][0]);
			Assert.assertEquals(1, stats.nextValues[0][1]);
			Assert.assertEquals(2, stats.nextValues[0][2]);
			Assert.assertEquals(2, stats.nextValues[1].length);
			Assert.assertEquals(1, stats.nextValues[1][0]);
			Assert.assertEquals(2, stats.nextValues[1][1]);
		}
		
		[Test]
		public function empty_list_is_emitted_with_source_is_empty() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var bufferScheduler : ManualScheduler = new ManualScheduler();
			
			var startTime : Date = new Date();
			
			Observable.never()
				.bufferWithTime(30, 20, bufferScheduler)
				.take(1)
				.subscribeWith(stats);
			
			Assert.assertFalse(stats.nextCalled);
			
			bufferScheduler.runNext();
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0].length);
		}
		
		[Test]
		public function empty_values_are_released_on_completion() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var bufferScheduler : ManualScheduler = new ManualScheduler();
			
			var startTime : Date = new Date();
			
			Observable.empty()
				.bufferWithTime(30, 20, bufferScheduler)
				.take(1)
				.subscribeWith(stats);
				
		
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0].length);
		}
		
		[Test]
		public function time_offset_includes_values_of_exact_offset() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var valueScheduler : ManualScheduler = new ManualScheduler();
			var bufferScheduler : ManualScheduler = new ManualScheduler();
			
			var startTime : Date = new Date();
			
			Observable.range(0, 5, valueScheduler)
				.bufferWithTime(30, 20, bufferScheduler)
				.subscribeWith(stats);
			
			Assert.assertFalse(stats.nextCalled);
			
			bufferScheduler.now = new Date(startTime.time + 10);
			valueScheduler.runNext();
			
			bufferScheduler.now = new Date(startTime.time + 20);
			valueScheduler.runNext();
			
			bufferScheduler.now = new Date(startTime.time + 30);
			valueScheduler.runNext();
			
			bufferScheduler.runNext();
			bufferScheduler.runNext();
			
			Assert.assertEquals(2, stats.nextCount);
            Assert.assertEquals(1, stats.nextValues[1].length);
            Assert.assertEquals(2, stats.nextValues[1][0]);
		}
		
		[Test]
		public function buffer_is_aborted_on_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var valueScheduler : ManualScheduler = new ManualScheduler();
			var bufferScheduler : ManualScheduler = new ManualScheduler();
			
			var startTime : Date = new Date();
			
			Observable.range(0, 5).concat([Observable.error(new Error())])
				.bufferWithTime(30, 20, bufferScheduler)
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertEquals(0, stats.nextCount);
            //Assert.assertEquals(5, stats.nextValues[0].length);
		}
		
		[Test]
		public function empty_buffer_is_aborted_on_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var valueScheduler : ManualScheduler = new ManualScheduler();
			var bufferScheduler : ManualScheduler = new ManualScheduler();
			
			var startTime : Date = new Date();
			
			Observable.empty().concat([Observable.error(new Error())])
				.bufferWithTime(30, 20, bufferScheduler)
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertEquals(0, stats.nextCount);
            //Assert.assertEquals(5, stats.nextValues[0].length);
		}*/
	}
}
