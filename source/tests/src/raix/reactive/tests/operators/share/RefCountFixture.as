package raix.reactive.tests.operators.share
{
	import org.flexunit.Assert;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.Subject;
	import raix.reactive.IObservable;
	import raix.reactive.ICancelable;
	
	public class RefCountFixture
	{
		[Test]
        public function subscription_is_added_to_source_after_first_subscription() : void
        {
            var subject : Subject = new Subject();

            var refCount : IObservable = subject.publish().refCount();

            Assert.assertEquals(0, subject.subscriptionCount);

            refCount.subscribeWith(new Subject());
            Assert.assertEquals(1, subject.subscriptionCount);
        }


        [Test]
        public function multiple_subscriptions_do_not_cause_subscriptions_to_the_source() : void
        {
            var subject : Subject = new Subject();

            var refCount : IObservable = subject.publish().refCount();

            refCount.subscribeWith(new Subject());
            Assert.assertEquals(1, subject.subscriptionCount);

            refCount.subscribeWith(new Subject());
            Assert.assertEquals(1, subject.subscriptionCount);
        }

        [Test]
        public function subscriptions_is_disposed_after_last_child_susbcription_is_disposed() : void
        {
            var subject : Subject = new Subject();

            var refCount : IObservable = subject.publish().refCount();

            var subscriptionA : ICancelable = refCount.subscribeWith(new Subject());
            var subscriptionB : ICancelable = refCount.subscribeWith(new Subject());

            Assert.assertEquals(1, subject.subscriptionCount);

            subscriptionA.cancel();
            Assert.assertEquals(1, subject.subscriptionCount);

            subscriptionB.cancel();
            Assert.assertEquals(0, subject.subscriptionCount);
        }

        [Test]
        public function values_are_received_by_all_subscriptions() : void
        {
            var subject : Subject = new Subject();

            var statsA : StatsObserver = new StatsObserver();
            var statsB : StatsObserver = new StatsObserver();

            var refCount : IObservable = subject.publish().refCount();

            var subscriptionA : ICancelable = refCount.subscribeWith(statsA);
            var subscriptionB : ICancelable = refCount.subscribeWith(statsB);

            subject.onNext(0);

            Assert.assertEquals(1, statsA.nextCount);
            Assert.assertEquals(1, statsB.nextCount);
        }

        [Test]
        public function values_are_not_received_by_unsubscribed_observers() : void
        {
            var subject : Subject = new Subject();

            var statsA : StatsObserver = new StatsObserver();
            var statsB : StatsObserver = new StatsObserver();

            var refCount : IObservable = subject.publish().refCount();

            var subscriptionA : ICancelable = refCount.subscribeWith(statsA);
            refCount.subscribeWith(statsB).cancel();

            subject.onNext(0);

            Assert.assertEquals(1, statsA.nextCount);
            Assert.assertEquals(0, statsB.nextCount);
        }

        [Test]
        public function errors_cause_unsubscription_of_everything() : void
        {
            var subject : Subject = new Subject();

            var statsA : StatsObserver = new StatsObserver();
            var statsB : StatsObserver = new StatsObserver();

            var refCount : IObservable = subject.publish().refCount();

            var subscriptionA : ICancelable = refCount.subscribeWith(statsA);
            var subscriptionB : ICancelable = refCount.subscribeWith(statsB);

            subject.onError(new Error());

            Assert.assertEquals(1, statsA.errorCount);
            Assert.assertEquals(1, statsB.errorCount);
            Assert.assertEquals(0, subject.subscriptionCount);
        }

	}
}