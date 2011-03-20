package raix.reactive.tests.operators.share
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Subject;
	import raix.reactive.subjects.IConnectableObservable;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class ReplayFixture
	{
		[Test]
        public function sends_live_values() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay();

            var stats : StatsObserver = new StatsObserver();

            source.subscribeWith(stats);
            source.connect();

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
            var subject : Subject = new Subject();
            
            var source : IConnectableObservable = subject.replay();

            var stats : StatsObserver = new StatsObserver();

            source.connect();
            
            subject.onNext(1);
            subject.onNext(2);

            source.subscribeWith(stats);

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
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay();

            var stats : StatsObserver = new StatsObserver();

            source.connect();
            
            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);

            source.subscribeWith(stats);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function replays_values_when_complete() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay();
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            source.subscribeWith(stats);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function replays_values_when_errored() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay();
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onError(new Error());

            source.subscribeWith(stats);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertTrue(1, stats.nextValues[0]);
            Assert.assertTrue(2, stats.nextValues[1]);
            Assert.assertTrue(3, stats.nextValues[2]);
            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function replays_empty_sequence() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay();
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onCompleted();

            source.subscribeWith(stats);

            Assert.assertEquals(0, stats.nextCount);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function replays_error_sequence() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay();
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onError(new Error());

            source.subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function ignores_buffer_size_for_live_subscriptions() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(2);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            source.subscribeWith(stats);

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
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(2);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);

            source.subscribeWith(stats);

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(3, stats.nextValues[1]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function buffer_size_includes_oncompleted() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(2);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onCompleted();

            source.subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(3, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function buffer_size_includes_onerror() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(2);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onNext(3);
            subject.onError(new Error());

            source.subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(3, stats.nextValues[0]);
            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function ignores_window_for_live_subscriptions() : void
        {
            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 10);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            source.subscribeWith(stats);

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

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 10, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 10);
            subject.onNext(3);

            scheduler.now = new Date(start + 11);
            source.subscribeWith(stats);

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

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 10, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 10);
            subject.onCompleted();

            scheduler.now = new Date(start + 11);
            source.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function window_includes_onerror() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 10, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 10);
            subject.onError(new Error());

            scheduler.now = new Date(start + 11);
            source.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function window_can_pass_complete() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 10, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onCompleted();

            scheduler.now = new Date(start + 11);
            source.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(0, stats.nextCount);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function window_can_pass_error() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 10, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start);
            subject.onError(new Error());

            scheduler.now = new Date(start + 11);
            source.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertFalse(stats.errorCalled);
        }

        [Test]
        public function with_both_window_and_buffer_size_values_can_be_ignored_by_buffer_size() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(2, 10, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start); // ignored by buffer size
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 8);
            subject.onCompleted();

            scheduler.now = new Date(start + 8);
            source.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function with_both_window_and_buffer_size_values_can_be_ignored_by_window() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(3, 10, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            var start : Number = new Date().time;

            scheduler.now = new Date(start); // ignored by window
            subject.onNext(1);

            scheduler.now = new Date(start + 5);
            subject.onNext(2);

            scheduler.now = new Date(start + 8);
            subject.onCompleted();

            scheduler.now = new Date(start + 11);
            source.subscribeWith(stats);

            scheduler.runAll();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertTrue(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function live_values_are_sent_through_scheduler() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 0, scheduler);

            source.connect();
            var stats : StatsObserver = new StatsObserver();

            source.subscribeWith(stats);

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

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 0, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);
            subject.onCompleted();

            source.subscribeWith(stats);

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

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 0, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onError(new Error());

            source.subscribeWith(stats);

            Assert.assertFalse(stats.errorCalled);

            scheduler.runNext();
            Assert.assertTrue(stats.errorCalled);
        }
        
        [Test]
        public function values_cannot_be_replayed_out_of_order() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();
            var source : IConnectableObservable = subject.replay(0, 0, scheduler);
            source.connect();

            var stats : StatsObserver = new StatsObserver();

            subject.onNext(1);
            subject.onNext(2);

            source.subscribeWith(stats);

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