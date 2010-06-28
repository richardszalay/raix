package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.*;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	public class SampleFixture
	{
		[Test]
        public function uses_scheduler_to_schedule_samples() : void
        {
            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            var scheduler : ManualScheduler = new ManualScheduler();

            subject
                .sample(1000, scheduler)
                .subscribeWith(stats);

            Assert.assertEquals(1, scheduler.queueSize);

            subject.onNext(0);
            scheduler.runNext();

            Assert.assertEquals(1, scheduler.queueSize);
            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(0, stats.nextValues[0]);
        }

        [Test]
        public function last_value_is_taken_for_each_sample() : void
        {
            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            var scheduler : ManualScheduler = new ManualScheduler();

            subject
                .sample(1000, scheduler)
                .subscribeWith(stats);

            subject.onNext(0);
            subject.onNext(1);
            scheduler.runNext();

            subject.onNext(2);
            subject.onNext(3);
            scheduler.runNext();

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertEquals(3, stats.nextValues[1]);
        }

        [Test]
        public function no_value_is_emitted_if_sampled_value_hasnt_changed() : void
        {
            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            var scheduler : ManualScheduler = new ManualScheduler();

            subject
                .sample(1000, scheduler)
                .subscribeWith(stats);

            stats.onNext(0);

            scheduler.runNext();
            scheduler.runNext();

            Assert.assertEquals(1, stats.nextCount);
        }

        [Test]
        public function no_value_is_emitted_if_empty() : void
        {
            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            var scheduler : ManualScheduler = new ManualScheduler();

            subject
                .sample(1000, scheduler)
                .subscribeWith(stats);

            Assert.assertEquals(1, scheduler.queueSize);

            scheduler.runNext();

            Assert.assertEquals(1, scheduler.queueSize);
            Assert.assertEquals(0, stats.nextCount);
        }

        [Test]
        public function completion_occurs_after_interval() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();
            var stats : StatsObserver = new StatsObserver();

            Observable.empty(int)
                .sample(1000, scheduler)
                .subscribeWith(stats);

            Assert.assertFalse(stats.completedCalled);

            scheduler.runNext();
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function latest_value_is_sampled_on_completion() : void
        {
            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            var scheduler : ManualScheduler = new ManualScheduler();

            subject
                .sample(1000, scheduler)
                .subscribeWith(stats);

            subject.onNext(0);
            subject.onCompleted();
            scheduler.runNext();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function interval_is_cancelled_on_completion() : void
        {
            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            var scheduler : ManualScheduler = new ManualScheduler();

            subject
                .sample(1000, scheduler)
                .subscribeWith(stats);

            subject.onNext(0);
            subject.onCompleted();
            scheduler.runNext();

            Assert.assertEquals(0, scheduler.queueSize);
        }

        [Test]
        public function errors_do_not_wait_for_interval() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var stats : StatsObserver = new StatsObserver();

            Observable.throwError(new Error())
                .sample(1000, scheduler)
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function errors_cancel_interval() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var stats : StatsObserver = new StatsObserver();

            Observable.throwError(new Error())
                .sample(1000, scheduler)
                .subscribeWith(stats);

            Assert.assertEquals(0, scheduler.queueSize);
        }
	}
}