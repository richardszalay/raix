using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class SumFixture
    {
        [Test]
        public void returns_one_value_after_completion()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(0, 5)
                .Sum()
                .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(10, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
            Assert.IsFalse(stats.ErrorCalled);
        }

        [Test]
        public void returns_zero_on_empty_source()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Empty<int>()
                .Sum()
                .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
            Assert.IsFalse(stats.ErrorCalled);
        }
    }
}
