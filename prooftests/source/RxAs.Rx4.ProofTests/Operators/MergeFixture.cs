using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Concurrency;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class MergeFixture
    {
        [Test]
        public void merge_output_order()
        {
            var stats = new StatsObserver<int>();

            Observable.Merge(
                Scheduler.Immediate,
                Observable.Range(0, 3, Scheduler.Immediate),
                Observable.Range(3, 3, Scheduler.Immediate),
                Observable.Range(6, 3, Scheduler.Immediate)
                )
                .Subscribe(stats);

            Assert.AreEqual(9, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0]);
            Assert.AreEqual(1, stats.NextValues[1]);
            Assert.AreEqual(2, stats.NextValues[2]);
        }

        [Test]
        public void scheduler_used_to_subscribe_to_each_sequence()
        {
            var stats = new StatsObserver<int>();

            var scheduler = new ManualScheduler();

            var subjectA = new StatsSubject<int>();
            var subjectB = new StatsSubject<int>();
            var subjectC = new StatsSubject<int>();

            Observable.Merge(
                scheduler,
                subjectA,
                subjectB,
                subjectC
                )
                .Subscribe(stats);

            Assert.AreEqual(1, scheduler.QueueSize);
            scheduler.RunNext();

            Assert.IsTrue(subjectA.HasSubscriptions);
            Assert.IsFalse(subjectB.HasSubscriptions);

            Assert.AreEqual(1, scheduler.QueueSize);
            scheduler.RunNext();

            Assert.IsTrue(subjectB.HasSubscriptions);
            Assert.IsFalse(subjectC.HasSubscriptions);

            Assert.AreEqual(1, scheduler.QueueSize);
            scheduler.RunNext();

            Assert.IsTrue(subjectC.HasSubscriptions);

            Assert.AreEqual(1, scheduler.QueueSize);
            scheduler.RunNext();

            Assert.AreEqual(0, scheduler.QueueSize);
        }
    }
}
