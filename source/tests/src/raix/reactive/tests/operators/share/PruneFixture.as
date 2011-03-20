package raix.reactive.tests.operators.share
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.subjects.IConnectableObservable;
	import raix.reactive.tests.mocks.*;
	
	public class PruneFixture
	{
		[Test]
        public function sends_no_values_before_completion() : void
        {
            var subject : Subject = new Subject();
            var connectable : IConnectableObservable = subject.prune();

            var stats : StatsObserver = new StatsObserver();

            connectable.subscribeWith(stats);
            connectable.connect();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);

            Assert.assertFalse(stats.nextCalled);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function sends_last_value_after_completion_if_subscribed_before_values() : void
        {
            var subject : Subject = new Subject();
            var connectable : IConnectableObservable = subject.prune();

            var stats : StatsObserver = new StatsObserver();

            connectable.subscribeWith(stats);
            connectable.connect();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(3, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function sends_last_value_after_completion_if_subscribed_after_values() : void
        {
            var subject : Subject = new Subject();
            var connectable : IConnectableObservable = subject.prune();

            var stats : StatsObserver = new StatsObserver();

			connectable.connect();
            
            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            connectable.subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(3, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function sends_no_values_after_error() : void
        {
            var subject : Subject = new Subject();
            var connectable : IConnectableObservable = subject.prune();

            var stats : StatsObserver = new StatsObserver();

            connectable.connect();
            
            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onError(new Error());

            connectable.subscribeWith(stats);

            Assert.assertFalse(stats.nextCalled);
            Assert.assertFalse(stats.completedCalled);
            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function scheduler_is_used_to_distribute_values() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var connectable : IConnectableObservable = subject.prune(scheduler);

            var statsA : StatsObserver = new StatsObserver();

            connectable.connect();
            
            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            connectable.subscribeWith(statsA);

            Assert.assertFalse(statsA.nextCalled);

            scheduler.runNext();

            Assert.assertTrue(statsA.nextCalled);
        }

        [Test]
        public function next_and_complete_are_scheduled_separately() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var connectable : IConnectableObservable = subject.prune(scheduler);

            var statsA : StatsObserver = new StatsObserver();

            connectable.connect();
            
            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            connectable.subscribeWith(statsA);
            
            Assert.assertEquals(1, scheduler.queueSize);
            scheduler.runNext();
            Assert.assertTrue(statsA.nextCalled);
            Assert.assertFalse(statsA.completedCalled);
            
            Assert.assertEquals(1, scheduler.queueSize);
            scheduler.runNext();
            Assert.assertTrue(statsA.completedCalled);
        }

        [Test]
        public function each_subscriber_is_scheduled_individually() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var connectable : IConnectableObservable = subject.prune(scheduler);

            var statsA : StatsObserver = new StatsObserver();
            var statsB : StatsObserver = new StatsObserver();

            connectable.connect();
            
            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            connectable.subscribeWith(statsA);
            connectable.subscribeWith(statsB);
            

            scheduler.runNext();

            Assert.assertTrue(statsA.nextCalled);
            Assert.assertFalse(statsB.nextCalled);

            scheduler.runNext();

            Assert.assertTrue(statsB.nextCalled);
        }
	}
}