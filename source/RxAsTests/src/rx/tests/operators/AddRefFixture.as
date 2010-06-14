package rx.tests.operators
{
	import org.flexunit.Assert;
	import rx.tests.mocks.StatsObserver;
	import rx.Subject;
	import rx.IObservable;
	import rx.ICancelable;
	
	public class AddRefFixture
	{
		[Test]
        public function subscription_is_added_to_source_after_first_subscription() : void
        {
            var subject : Subject = new Subject(int);

            var refCount : IObservable = subject.publish().refCount();

            Assert.assertEquals(0, subject.subscriptionCount);

            refCount.subscribe(new Subject(int));
            Assert.assertEquals(1, subject.subscriptionCount);
        }


        [Test]
        public function multiple_subscriptions_do_not_cause_subscriptions_to_the_source() : void
        {
            var subject : Subject = new Subject(int);

            var refCount : IObservable = subject.publish().refCount();

            refCount.subscribe(new Subject(int));
            Assert.assertEquals(1, subject.subscriptionCount);

            refCount.subscribe(new Subject(int));
            Assert.assertEquals(1, subject.subscriptionCount);
        }

        [Test]
        public function subscriptions_is_disposed_after_last_child_susbcription_is_disposed() : void
        {
            var subject : Subject = new Subject(int);

            var refCount : IObservable = subject.publish().refCount();

            var subscriptionA : ICancelable = refCount.subscribe(new Subject(int));
            var subscriptionB : ICancelable = refCount.subscribe(new Subject(int));

            Assert.assertEquals(1, subject.subscriptionCount);

            subscriptionA.cancel();
            Assert.assertEquals(1, subject.subscriptionCount);

            subscriptionB.cancel();
            Assert.assertEquals(0, subject.subscriptionCount);
        }

        [Test]
        public function values_are_received_by_all_subscriptions() : void
        {
            var subject : Subject = new Subject(int);

            var statsA : StatsObserver = new StatsObserver();
            var statsB : StatsObserver = new StatsObserver();

            var refCount : IObservable = subject.publish().refCount();

            var subscriptionA : ICancelable = refCount.subscribe(statsA);
            var subscriptionB : ICancelable = refCount.subscribe(statsB);

            subject.onNext(0);

            Assert.assertEquals(1, statsA.nextCount);
            Assert.assertEquals(1, statsB.nextCount);
        }

        [Test]
        public function values_are_not_received_by_unsubscribed_observers() : void
        {
            var subject : Subject = new Subject(int);

            var statsA : StatsObserver = new StatsObserver();
            var statsB : StatsObserver = new StatsObserver();

            var refCount : IObservable = subject.publish().refCount();

            var subscriptionA : ICancelable = refCount.subscribe(statsA);
            refCount.subscribe(statsB).cancel();

            subject.onNext(0);

            Assert.assertEquals(1, statsA.nextCount);
            Assert.assertEquals(0, statsB.nextCount);
        }

        [Test]
        public function errors_cause_unsubscription_of_everything() : void
        {
            var subject : Subject = new Subject(int);

            var statsA : StatsObserver = new StatsObserver();
            var statsB : StatsObserver = new StatsObserver();

            var refCount : IObservable = subject.publish().refCount();

            var subscriptionA : ICancelable = refCount.subscribe(statsA);
            var subscriptionB : ICancelable = refCount.subscribe(statsB);

            subject.onError(new Error());

            Assert.assertEquals(1, statsA.errorCount);
            Assert.assertEquals(1, statsB.errorCount);
            Assert.assertEquals(0, subject.subscriptionCount);
        }

	}
}