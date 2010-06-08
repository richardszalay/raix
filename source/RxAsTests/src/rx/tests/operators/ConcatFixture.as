package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.*;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	public class ConcatFixture
	{
		[Test]
        public function runs_each_sequence_and_completes() : void
        {
            var stats : StatsObserver = new StatsObserver();
            
        	Observable.concat(int, [
        		Observable.returnValue(int, 1),
        		Observable.returnValue(int, 2),
        		Observable.returnValue(int, 3)
        		])
        		.subscribe(stats);
            
            Assert.assertEquals(3, stats.nextCount);
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertEquals(2, stats.nextValues[1]);
            Assert.assertEquals(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
        }
        
        [Test]
        public function can_be_cancelled_at_any_time() : void
        {
            var stats : StatsObserver = new StatsObserver();
            
            var scheduler : ManualScheduler = new ManualScheduler();
            
        	var subs : ICancelable = Observable.concat(int, [
        		Observable.returnValue(int, 1),
        		Observable.returnValue(int, 2),
        		Observable.returnValue(int, 3)
        		], scheduler)
        		.subscribe(stats);
        		
        	Assert.assertEquals(1, scheduler.queueSize);
        	scheduler.runNext()
        	
        	subs.cancel();
            
            Assert.assertEquals(0, scheduler.queueSize);
            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertFalse(stats.completedCalled);
        }
        
        [Test]
        public function scheduler_is_used_for_first_subscription() : void
        {
            var sourceA : Subject = new Subject(int);
            var sourceB : IObservable = Observable.empty(int);

            var scheduler : ManualScheduler = new ManualScheduler();
            var stats : StatsObserver = new StatsObserver();

            sourceA.concat([sourceB], scheduler).subscribe(stats);

            Assert.assertEquals(0, sourceA.subscriptionCount);
            Assert.assertEquals(1, scheduler.queueSize);

            scheduler.runNext();

            Assert.assertEquals(1, sourceA.subscriptionCount);
            Assert.assertEquals(0, scheduler.queueSize);
        }

        [Test]
        public function scheduler_is_used_for_subsequent_subscriptions() : void
        {
            var sourceA : IObservable = Observable.empty();
            var sourceB : Subject = new Subject(int);

            var scheduler : ManualScheduler = new ManualScheduler();
            var stats : StatsObserver = new StatsObserver();

            sourceA.concat([sourceB], scheduler).subscribe(stats);

            scheduler.runNext();

            Assert.assertEquals(0, sourceB.subscriptionCount);
            Assert.assertEquals(1, scheduler.queueSize);

            scheduler.runNext();

            Assert.assertEquals(1, sourceB.subscriptionCount);
            Assert.assertEquals(0, scheduler.queueSize);
        }
	}
}