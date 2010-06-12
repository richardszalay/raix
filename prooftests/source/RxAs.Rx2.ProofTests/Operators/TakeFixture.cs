using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class TakeFixture
    {
        [Test]
        public void takes_values_and_completes()
        {
            var stats = new StatsObserver<int>();

            Observable.Range(0, 5).Take(3).Subscribe(stats);

            Assert.AreEqual(3, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0]);
            Assert.AreEqual(1, stats.NextValues[1]);
            Assert.AreEqual(2, stats.NextValues[2]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void scheduler_is_not_used_when_count_great_than_zero()
        {
            var scheduler = new ManualScheduler();

            var subject = new StatsSubject<int>();

            var stats = new StatsObserver<int>();

            subject.Take(3, scheduler).Subscribe(stats);

            subject.OnNext(0);
            subject.OnNext(1);
            subject.OnNext(2);
            
            Assert.AreEqual(0, scheduler.QueueSize);
        }

        [Test]
        public void scheduler_is_used_for_completion_when_take_is_zero()
        {
            var scheduler = new ManualScheduler();

            var stats = new StatsObserver<int>();

            new Subject<int>().Take(0, scheduler).Subscribe(stats);

            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();

            Assert.IsTrue(stats.CompletedCalled);
        }
    }
}
