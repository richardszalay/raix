package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.testing.ColdObservable;
	import raix.reactive.testing.MockObserver;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class SampleFixture
	{
		[Test]
        public function last_value_is_taken_from_sample_timespan() : void
        {
            var subject : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            var scheduler : TestScheduler = new TestScheduler();
            
            var observer : MockObserver = new MockObserver(scheduler);
            
            scheduler.createColdObservable([
            		new Recorded(5, new OnNext(0)),
            		new Recorded(10, new OnNext(1)),
            		new Recorded(15, new OnNext(2)),
            		new Recorded(20, new OnNext(3)),
            		new Recorded(25, new OnNext(4)),
            		new Recorded(30, new OnNext(5))
            	])
            	.sample(15, scheduler)
            	.subscribeWith(observer);
            	
            scheduler.runTo(30);
            	
            observer.assertTimings([
            		new Recorded(15, new OnNext(2)),
            		new Recorded(30, new OnNext(5))
            	], Assert.fail);
        }

        [Test]
        public function subscribes_immedietly() : void
        {
            var scheduler : TestScheduler = new TestScheduler();
            
            var observer : MockObserver = new MockObserver(scheduler);
            
            var source : ColdObservable = scheduler.createColdObservable([
            		new Recorded(5, new OnNext(0)),
            		new Recorded(10, new OnNext(1)),
            		new Recorded(15, new OnNext(2))
            	]);

            source
            	.sample(15, scheduler)
            	.take(1)
            	.subscribeWith(observer);

            scheduler.run();

            Assert.assertEquals(0, source.subscriptions[0].subscribe);
            Assert.assertEquals(15, source.subscriptions[0].unsubscribe);
        }
        
        [Test]
        public function latest_value_is_sampled_at_next_sample_time_after_completion() : void
        {
            var scheduler : TestScheduler = new TestScheduler();
            
            var observer : MockObserver = new MockObserver(scheduler);
            
            scheduler.createColdObservable([
            		new Recorded(5, new OnNext(0)),
            		new Recorded(6, new OnCompleted())
            	])
            	.sample(15, scheduler)
            	.subscribeWith(observer);
            	
            scheduler.run();
            
            observer.assertTimings([
            		new Recorded(15, new OnNext(0)),
            		new Recorded(15, new OnCompleted())
            	], Assert.fail);
        }
	}
}