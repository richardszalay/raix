using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class ConcatFixture
    {
        [Test]
        public void scheduler_is_used_for_first_subscription()
        {
            var sourceA = new StatsSubject<int>();
            var sourceB = Observable.Empty<int>();

            var scheduler = new ManualScheduler();
            var stats = new StatsObserver<int>();

            sourceA.Concat(sourceB, scheduler).Subscribe(stats);

            Assert.AreEqual(0, sourceA.SubscriptionCount);
            Assert.AreEqual(1, scheduler.QueueSize);

            scheduler.RunNext();

            Assert.AreEqual(1, sourceA.SubscriptionCount);
            Assert.AreEqual(0, scheduler.QueueSize);
        }

        [Test]
        public void scheduler_is_used_for_subsequent_subscriptions()
        {
            var sourceA = Observable.Empty<int>();
            var sourceB = new StatsSubject<int>();

            var scheduler = new ManualScheduler();
            var stats = new StatsObserver<int>();

            sourceA.Concat(sourceB, scheduler).Subscribe(stats);

            scheduler.RunNext();

            Assert.AreEqual(0, sourceB.SubscriptionCount);
            Assert.AreEqual(1, scheduler.QueueSize);

            scheduler.RunNext();

            Assert.AreEqual(1, sourceB.SubscriptionCount);
            Assert.AreEqual(0, scheduler.QueueSize);
        }
    }
}
