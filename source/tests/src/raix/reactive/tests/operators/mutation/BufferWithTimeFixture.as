package raix.reactive.tests.operators.mutation
{
	import org.flexunit.Assert;
	
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	[TestCase]
	public class BufferWithTimeFixture
	{
		[Test]
		public function values_are_buffered_in_specified_time() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var valueScheduler : ManualScheduler = new ManualScheduler();
			var bufferScheduler : ManualScheduler = new ManualScheduler();
			
			var startTime : Date = new Date();
			
			Observable.range(0, 5, valueScheduler)
				.bufferWithTime(120, 0, bufferScheduler)
				.subscribeWith(stats);
			
			Assert.assertFalse(stats.nextCalled);
			
			bufferScheduler.now = new Date(startTime.time + 10);
			valueScheduler.runNext();
			
			bufferScheduler.now = new Date(startTime.time + 20);
			valueScheduler.runNext();
			
			Assert.assertFalse(stats.nextCalled);
			
			bufferScheduler.runNext();
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(2, stats.nextValues[0].length);
			Assert.assertEquals(0, stats.nextValues[0][0]);
			Assert.assertEquals(1, stats.nextValues[0][1]);
		}
		
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
			
			Observable.range(0, 5).concat([Observable.throwError(new Error())])
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
			
			Observable.empty().concat([Observable.throwError(new Error())])
				.bufferWithTime(30, 20, bufferScheduler)
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertEquals(0, stats.nextCount);
            //Assert.assertEquals(5, stats.nextValues[0].length);
		}
	}
}
