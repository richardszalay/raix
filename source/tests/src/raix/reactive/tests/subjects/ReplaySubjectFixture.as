package raix.reactive.tests.subjects
{
	import org.flexunit.Assert;
	
	import raix.reactive.subjects.ReplaySubject;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class ReplaySubjectFixture
	{
		[Test]
        public function sends_live_values() : void
        {
            var subject : ReplaySubject = new ReplaySubject();

            var stats : StatsObserver = new StatsObserver();

            subject.subscribeWith(stats);

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function sends_live_values_after_replay() : void
        {
            var subject : ReplaySubject = new ReplaySubject();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);

            subject.subscribeWith(stats);

            subject.onNext(3);
            subject.onCompleted();

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function replays_values_when_incomplete() : void
        {
            var subject : ReplaySubject = new ReplaySubject();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);

            subject.subscribeWith(stats);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function replays_values_when_complete() : void
        {
            var subject : ReplaySubject = new ReplaySubject();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            subject.subscribeWith(stats);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function replays_values_when_errored() : void
        {
            var subject : ReplaySubject = new ReplaySubject();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onError(new Error());

            subject.subscribeWith(stats);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function replays_empty_sequence() : void
        {
            var subject : ReplaySubject = new ReplaySubject();

            var stats : StatsObserver = new StatsObserver();

            subject.onCompleted();

            subject.subscribeWith(stats);

            Assert.assertEquals(0, stats.nextCount);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function replays_error_sequence() : void
        {
            var subject : ReplaySubject = new ReplaySubject();

            var stats : StatsObserver = new StatsObserver();

            subject.onError(new Error());

            subject.subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function ignores_buffer_size_for_live_subscriptions() : void
        {
            var subject : ReplaySubject = new ReplaySubject(2);

            var stats : StatsObserver = new StatsObserver();

            subject.subscribeWith(stats);

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function honours_buffer_size_for_replays_with_priority_to_most_recent() : void
        {
            var subject : ReplaySubject = new ReplaySubject(2);

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);

            subject.subscribeWith(stats);

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(3, stats.nextValues[1]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function buffer_size_includes_oncompleted() : void
        {
            var subject : ReplaySubject = new ReplaySubject(2);

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
        public function buffer_size_includes_onerror() : void
        {
            var subject : ReplaySubject = new ReplaySubject(2);

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onError(new Error());

            subject.subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(3, stats.nextValues[0]);
            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function ignores_window_for_live_subscriptions() : void
        {
            var subject : ReplaySubject = 
                new ReplaySubject(0, 10);

            var stats : StatsObserver = new StatsObserver();

            subject.subscribeWith(stats);

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function honours_window_for_replays_with_priority_to_most_recent() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject =
                new ReplaySubject(0, 10, scheduler);

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 10);
            subject.onNext(3);

            scheduler.now = new Date(start + 11);
            subject.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(3, stats.nextValues[1]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function window_includes_oncompleted() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject =
                new ReplaySubject(0, 10, scheduler);

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 10);
            subject.onCompleted();

            scheduler.now = new Date(start + 11);
            subject.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function window_includes_onerror() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject =
                new ReplaySubject(0, 10, scheduler);

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 10);
            subject.onError(new Error());

            scheduler.now = new Date(start + 11);
            subject.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function window_can_pass_complete() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject =
                new ReplaySubject(0, 10, scheduler);

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onCompleted();

            scheduler.now = new Date(start + 11);
            subject.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(0, stats.nextCount);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function window_can_pass_error() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject =
                new ReplaySubject(0, 10, scheduler);

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onError(new Error());

            scheduler.now = new Date(start + 11);
            subject.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertFalse(stats.errorCalled);
        }

        [Test]
        public function with_both_window_and_buffer_size_values_can_be_ignored_by_buffer_size() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject =
                new ReplaySubject(2, 10, scheduler);

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start); // ignored by buffer size
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 8);
            subject.onCompleted();

            scheduler.now = new Date(start + 8);
            subject.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function with_both_window_and_buffer_size_values_can_be_ignored_by_window() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject =
                new ReplaySubject(3, 10, scheduler);

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start); // ignored by window
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 8);
            subject.onCompleted();

            scheduler.now = new Date(start + 11);
            subject.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function live_values_are_sent_through_scheduler() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject = new ReplaySubject(0, 0, scheduler);

            var stats : StatsObserver = new StatsObserver();

            subject.subscribeWith(stats);

            subject.onNext(1);
            subject.onNext(2);
            subject.onCompleted();

            Assert.assertFalse(stats.nextCalled);

            scheduler.runNext();
            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertFalse(stats.completedCalled);

            scheduler.runNext();
            Assert.assertEquals(2, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertFalse(stats.completedCalled);

            scheduler.runNext();
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function replayed_values_are_sent_through_scheduler() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject = new ReplaySubject(0, 0, scheduler);

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onCompleted();

            subject.subscribeWith(stats);

            Assert.assertFalse(stats.nextCalled);

            scheduler.runNext();
            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertFalse(stats.completedCalled);

            scheduler.runNext();
            Assert.assertEquals(2, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertFalse(stats.completedCalled);

            scheduler.runNext();
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function errors_are_sent_through_scheduler() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject = new ReplaySubject(0, 0, scheduler);

            var stats : StatsObserver = new StatsObserver();

            subject.onError(new Error());

            subject.subscribeWith(stats);

            Assert.assertFalse(stats.errorCalled);

            scheduler.runNext();
            Assert.assertTrue(stats.errorCalled);
        }
        
        [Test]
        public function values_cannot_be_replayed_out_of_order() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : ReplaySubject = new ReplaySubject(0, 0, scheduler);

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);

            subject.subscribeWith(stats);

            Assert.assertFalse(stats.nextCalled);

            scheduler.runNext();
            Assert.assertEquals(1, stats.nextValues[0]);

            subject.onNext(3);

            scheduler.runNext();
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertEquals(2, stats.nextValues[1]);

            scheduler.runNext();
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertEquals(2, stats.nextValues[1]);
            Assert.assertEquals(3, stats.nextValues[2]);

            subject.onCompleted();
            
            scheduler.runNext();
            Assert.assertTrue(stats.completedCalled);
        }
	}
}