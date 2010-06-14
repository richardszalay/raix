using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class TakeLast
    {
        [Test]
        public void complete_is_called_after_source_completes()
        {
            var subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            subject
                .TakeLast(3)
                .Subscribe(stats);

            subject.OnNext(0);
            subject.OnNext(0);
            subject.OnNext(0);
            Assert.IsFalse(stats.CompletedCalled);

            subject.OnCompleted();
            Assert.IsTrue(stats.CompletedCalled);
            Assert.AreEqual(3, stats.NextCount);
        }

        [Test]
        public void last_count_values_are_emitted()
        {
            var subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            subject
                .TakeLast(3)
                .Subscribe(stats);

            subject.OnNext(0);
            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();
            Assert.AreEqual(3, stats.NextCount);
            Assert.AreEqual(1, stats.NextValues[0]);
            Assert.AreEqual(2, stats.NextValues[1]);
            Assert.AreEqual(3, stats.NextValues[2]);            
        }

        [Test]
        public void no_values_are_emitted_on_empty_sequence()
        {
            var stats = new StatsObserver<int>();

            Observable.Empty<int>()
                .TakeLast(3)
                .Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
        }
    }
}
