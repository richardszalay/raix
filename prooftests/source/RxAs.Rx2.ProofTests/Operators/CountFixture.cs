using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class CountFixture
    {
        [Test]
        public void value_equals_number_of_values()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(5, 3).Count().Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(3, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void value_is_not_sent_until_completion()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(5, 3)
                .Concat(Observable.Never<int>())
                .Count()
                .Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void zero_is_sent_if_no_values_received()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Empty<int>()
                .Count()
                .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void value_is_not_sent_on_error()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(5, 3)
                .Concat(Observable.Throw<int>(new ApplicationException()))
                .Count()
                .Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.ErrorCalled);
        }
    }
}
