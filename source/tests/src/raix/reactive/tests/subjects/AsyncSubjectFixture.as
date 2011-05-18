package raix.reactive.tests.subjects
{
	import org.flexunit.Assert;
	
	import raix.reactive.subjects.AsyncSubject;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class AsyncSubjectFixture
	{
		public function AsyncSubjectFixture()
		{
		}
		
		[Test]
        public function sends_no_values_before_completion() : void
        {
            var subject : AsyncSubject = new AsyncSubject();

            var stats : StatsObserver = new StatsObserver();

            subject.subscribeWith(stats);

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);

            Assert.assertFalse(stats.nextCalled);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function sends_last_value_after_completion_if_subscribed_before_values() : void
        {
            var subject : AsyncSubject = new AsyncSubject();

            var stats : StatsObserver = new StatsObserver();

            subject.subscribeWith(stats);

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
            var subject : AsyncSubject = new AsyncSubject();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            subject.subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(3, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function sends_no_values_after_error() : void
        {
            var subject : AsyncSubject = new AsyncSubject();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onError(new Error());

            subject.subscribeWith(stats);

            Assert.assertFalse(stats.nextCalled);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function scheduler_is_used_to_distribute_values() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : AsyncSubject = new AsyncSubject(scheduler);

            var statsA : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            subject.subscribeWith(statsA);

            Assert.assertFalse(statsA.nextCalled);

            scheduler.runNext();

            Assert.assertTrue(statsA.nextCalled);
        }

        [Test]
        public function next_and_complete_are_scheduled_separately() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : AsyncSubject = new AsyncSubject(scheduler);

            var statsA : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            subject.subscribeWith(statsA);
            
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

            var subject : AsyncSubject = new AsyncSubject(scheduler);

            var statsA : StatsObserver = new StatsObserver();
            var statsB : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            subject.subscribeWith(statsA);
            subject.subscribeWith(statsB);


            scheduler.runNext();

            Assert.assertTrue(statsA.nextCalled);
            Assert.assertFalse(statsB.nextCalled);

            scheduler.runNext();

            Assert.assertTrue(statsB.nextCalled);
        }

	}
}