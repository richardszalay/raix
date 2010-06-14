using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class AddRefFixture
    {
        [Test]
        public void subscription_is_added_to_source_after_first_subscription()
        {
            var subject = new StatsSubject<int>();

            var refCount = subject.Publish().RefCount();

            Assert.AreEqual(0, subject.SubscriptionCount);

            refCount.Subscribe(new Subject<int>());
            Assert.AreEqual(1, subject.SubscriptionCount);
        }


        [Test]
        public void multiple_subscriptions_do_not_cause_subscriptions_to_the_source()
        {
            var subject = new StatsSubject<int>();

            var refCount = subject.Publish().RefCount();

            refCount.Subscribe(new Subject<int>());
            Assert.AreEqual(1, subject.SubscriptionCount);

            refCount.Subscribe(new Subject<int>());
            Assert.AreEqual(1, subject.SubscriptionCount);
        }

        [Test]
        public void subscriptions_is_disposed_after_last_child_susbcription_is_disposed()
        {
            var subject = new StatsSubject<int>();

            var refCount = subject.Publish().RefCount();

            var subscriptionA = refCount.Subscribe(new Subject<int>());
            var subscriptionB = refCount.Subscribe(new Subject<int>());

            Assert.AreEqual(1, subject.SubscriptionCount);

            subscriptionA.Dispose();
            Assert.AreEqual(1, subject.SubscriptionCount);

            subscriptionB.Dispose();
            Assert.AreEqual(0, subject.SubscriptionCount);
        }

        [Test]
        public void values_are_received_by_all_subscriptions()
        {
            var subject = new StatsSubject<int>();

            var statsA = new StatsObserver<int>();
            var statsB = new StatsObserver<int>();

            var refCount = subject.Publish().RefCount();

            var subscriptionA = refCount.Subscribe(statsA);
            var subscriptionB = refCount.Subscribe(statsB);

            subject.OnNext(0);

            Assert.AreEqual(1, statsA.NextCount);
            Assert.AreEqual(1, statsB.NextCount);
        }

        [Test]
        public void values_are_not_received_by_unsubscribed_observers()
        {
            var subject = new StatsSubject<int>();

            var statsA = new StatsObserver<int>();
            var statsB = new StatsObserver<int>();

            var refCount = subject.Publish().RefCount();

            var subscriptionA = refCount.Subscribe(statsA);
            refCount.Subscribe(statsB).Dispose();

            subject.OnNext(0);

            Assert.AreEqual(1, statsA.NextCount);
            Assert.AreEqual(0, statsB.NextCount);
        }

        [Test]
        public void errors_cause_unsubscription_of_everything()
        {
            var subject = new StatsSubject<int>();

            var statsA = new StatsObserver<int>();
            var statsB = new StatsObserver<int>();

            var refCount = subject.Publish().RefCount();

            var subscriptionA = refCount.Subscribe(statsA);
            var subscriptionB = refCount.Subscribe(statsB);

            subject.OnError(new Exception());

            Assert.AreEqual(1, statsA.ErrorCount);
            Assert.AreEqual(1, statsB.ErrorCount);
            Assert.AreEqual(0, subject.SubscriptionCount);
        }
    }
}
