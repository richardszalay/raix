using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class IfFixture
    {
        [Test]
        public void true_sequence_is_used_when_predicate_returns_true()
        {
            var stats = new StatsObserver<int>();

            Observable.If(() => true,
                Observable.Return(1),
                Observable.Return(2)
                )
                .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(1, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void false_sequence_is_used_when_predicate_returns_false()
        {
            var stats = new StatsObserver<int>();

            Observable.If(() => false,
                Observable.Return(1),
                Observable.Return(2)
                )
                .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(2, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void error_is_called_when_predicate_throws_exception()
        {
            var stats = new StatsObserver<int>();

            Exception exception = new ArgumentException();

            Observable.If(() => { throw exception; },
                Observable.Return(1),
                Observable.Return(2)
                )
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreEqual(exception, stats.Error);
        }
    }
}
