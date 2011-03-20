package raix.reactive.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class QueueFixture
	{
		[Test]
        public function outputs_values_from_all() : void
        {
            var queue : IObserver = Observable.queue();
			
			var queuedSourceA : IObservable = Observable.value(1).queued(queue);
			var queuedSourceB : IObservable = Observable.value(2).queued(queue);
			
			var stats : StatsObserver = new StatsObserver();
			
			queuedSourceA.subscribeWith(stats);
			queuedSourceB.subscribeWith(stats);
			
			Assert.assertEquals(2, stats.nextCount);
			Assert.assertEquals(1, stats.nextValues[0]);
			Assert.assertEquals(2, stats.nextValues[1]);
        }
		
		[Test]
		public function continues_to_next_source_on_completed() : void
		{
			var queue : IObserver = Observable.queue();
			
			var sourceA : Subject = new Subject();
			var sourceB : Subject = new Subject();
			
			var queuedSourceA : IObservable = sourceA.queued(queue);
			var queuedSourceB : IObservable = sourceB.queued(queue);
			
			var stats : StatsObserver = new StatsObserver();
			
			queuedSourceA.subscribeWith(stats);
			queuedSourceB.subscribeWith(stats);
			
			Assert.assertTrue(sourceA.hasSubscriptions);
			Assert.assertFalse(sourceB.hasSubscriptions);
			Assert.assertEquals(0, stats.nextCount);
			
			sourceA.onCompleted();
			Assert.assertFalse(sourceA.hasSubscriptions);
			Assert.assertTrue(sourceB.hasSubscriptions);
		}
		
		[Test]
		public function continues_to_next_source_on_error() : void
		{
			var queue : IObserver = Observable.queue();
			
			var sourceA : Subject = new Subject();
			var sourceB : Subject = new Subject();
			
			var queuedSourceA : IObservable = sourceA.queued(queue);
			var queuedSourceB : IObservable = sourceB.queued(queue);
			
			var stats : StatsObserver = new StatsObserver();
			
			queuedSourceA.subscribeWith(stats);
			queuedSourceB.subscribeWith(stats);
			Assert.assertTrue(sourceA.hasSubscriptions);
			Assert.assertFalse(sourceB.hasSubscriptions);
			Assert.assertEquals(0, stats.nextCount);
			
			sourceA.onError(new Error());
			Assert.assertFalse(sourceA.hasSubscriptions);
			Assert.assertTrue(sourceB.hasSubscriptions);
		}
		
		[Test]
		public function continues_to_next_source_on_cancel() : void
		{
			var queue : IObserver = Observable.queue();
			
			var sourceA : Subject = new Subject();
			var sourceB : Subject = new Subject();
			
			var queuedSourceA : IObservable = sourceA.queued(queue);
			var queuedSourceB : IObservable = sourceB.queued(queue);
			
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = queuedSourceA.subscribeWith(stats);
			queuedSourceB.subscribeWith(stats);
			Assert.assertTrue(sourceA.hasSubscriptions);
			Assert.assertFalse(sourceB.hasSubscriptions);
			Assert.assertEquals(0, stats.nextCount);
			
			subscription.cancel();
			Assert.assertFalse(sourceA.hasSubscriptions);
			Assert.assertTrue(sourceB.hasSubscriptions);
		}
		
		[Test]
		public function continues_to_next_source_after_pause() : void
		{
			var queue : IObserver = Observable.queue();
			
			var sourceA : Subject = new Subject();
			var sourceB : Subject = new Subject();
			
			var stats : StatsObserver = new StatsObserver();
			
			var queuedSourceA : IObservable = sourceA.queued(queue);
			queuedSourceA.subscribeWith(stats);
			sourceA.onCompleted();
			
			var queuedSourceB : IObservable = sourceB.queued(queue);
			queuedSourceB.subscribeWith(stats);
			
			Assert.assertFalse(sourceA.hasSubscriptions);
			Assert.assertTrue(sourceB.hasSubscriptions);
		}
	}
}