using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class CaseFixture
    {
        [Test]
        public void lookup_value_is_subscribed_to()
        {
            Dictionary<string, IObservable<int>> dictionary = new Dictionary<string, IObservable<int>>()
            {
                { "keyA", Observable.Return(1) },
                { "keyB", Observable.Return(2) },
                { "keyC", Observable.Return(3) }
            };

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Case(() => "keyB", dictionary)
                .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(2, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void empty_is_returned_if_lookup_key_is_invalid()
        {
            Dictionary<string, IObservable<int>> dictionary = new Dictionary<string, IObservable<int>>()
            {
                { "keyA", Observable.Return(1) },
                { "keyB", Observable.Return(2) },
                { "keyC", Observable.Return(3) }
            };

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Case(() => "keyD", dictionary)
                .Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void error_is_raised_if_selector_throws_exception()
        {
            Dictionary<string, IObservable<int>> dictionary = new Dictionary<string, IObservable<int>>()
            {
                { "keyA", Observable.Return(1) },
                { "keyB", Observable.Return(2) },
                { "keyC", Observable.Return(3) }
            };

            StatsObserver<int> stats = new StatsObserver<int>();

            Exception exception = new ArgumentException();

            Observable.Case(() => { throw exception; }, dictionary)
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreEqual(exception, stats.Error);
            
        }
    }
}
