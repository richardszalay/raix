package raix.reactive.tests.subjects
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class ConnectableObservableFixture
	{
		[Test]
        public function uses_subject_for_subscriptions() : void
        {
            var source : IObservable = Observable.empty();
            var stats : StatsObserver = new StatsObserver();

            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            Assert.assertFalse(subject.hasSubscriptions);

            var sub : ICancelable = connectable.subscribeWith(stats);

            Assert.assertTrue(subject.hasSubscriptions);

            sub.cancel();

            Assert.assertFalse(subject.hasSubscriptions);
        }

        [Test]
        public function disconnecting_does_not_remove_subscriptions() : void
        {
            var source : IObservable = Observable.empty();
            var stats : StatsObserver = new StatsObserver();

            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            Assert.assertFalse(subject.hasSubscriptions);

            var sub : ICancelable = connectable.subscribeWith(stats);

            Assert.assertTrue(subject.hasSubscriptions);

            connectable.connect().cancel();

            Assert.assertTrue(subject.hasSubscriptions);
        }

        [Test]
        public function values_send_before_completion_are_ignored() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject();
            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            var sub : ICancelable = connectable.subscribeWith(stats);

            source.onNext(0);
            source.onCompleted();
            source.onError(new Error());

            Assert.assertFalse(stats.nextCalled);
            Assert.assertFalse(stats.completedCalled);
            Assert.assertFalse(stats.errorCalled);
        }

        [Test]
        public function connecting_subscribes_to_source() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject();
            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            var sub : ICancelable = connectable.subscribeWith(stats);

            Assert.assertFalse(source.hasSubscriptions);

            connectable.connect();

            Assert.assertTrue(source.hasSubscriptions);
        }

        [Test]
        public function disconnecting_subscribes_to_source() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject();
            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            var sub : ICancelable = connectable.subscribeWith(stats);

            Assert.assertFalse(source.hasSubscriptions);

            connectable.connect().cancel();

            Assert.assertFalse(source.hasSubscriptions);
        }

        [Test]
        public function connecting_multiple_times_does_not_subscribe_to_source_multiple_times() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject();
            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            var sub : ICancelable = connectable.subscribeWith(stats);

            connectable.connect();
            connectable.connect();

            Assert.assertEquals(1, source.subscriptionCount);
        }

        [Test]
        public function disconnecting_last_of_multiple_connections_subscribes_to_source() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject();
            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            var sub : ICancelable = connectable.subscribeWith(stats);

            Assert.assertFalse(source.hasSubscriptions);

            connectable.connect();
            connectable.connect().cancel();

            Assert.assertFalse(source.hasSubscriptions);
        }

        [Test]
        public function disconnecting_first_of_multiple_connections_subscribes_to_source() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject();
            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            var sub : ICancelable = connectable.subscribeWith(stats);

            Assert.assertFalse(source.hasSubscriptions);

            var connectionA : ICancelable = connectable.connect();
            var connectionB : ICancelable = connectable.connect();

            connectionA.cancel();

            Assert.assertFalse(source.hasSubscriptions);
        }

        [Test]
        public function operations_are_passed_on_once_connected() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject();
            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            var sub : ICancelable = connectable.subscribeWith(stats);

            source.onNext(0);

            connectable.connect();

            source.onNext(1);

            Assert.assertTrue(stats.nextCalled);
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertFalse(stats.completedCalled);
            Assert.assertFalse(stats.errorCalled);
        }

        [Test]
        public function operation_order_is_honoured_prior_to_connection() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject();
            var subject : Subject = new Subject();

            var connectable : ConnectableObservable = new ConnectableObservable(source, subject);

            var sub : ICancelable = connectable.subscribeWith(stats);

            source.onNext(0);
            source.onCompleted();

            connectable.connect();

            source.onNext(1);

            Assert.assertFalse(stats.nextCalled);
            Assert.assertFalse(stats.completedCalled);
            Assert.assertFalse(stats.errorCalled);
        }

	}
}