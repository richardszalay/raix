using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class AnyFixture
    {
        [Test]
		public void negative_value_is_received_on_completion()
		{
            var source = new Subject<int>();

            var stats = new StatsObserver<bool>();

            source.Any(x => x > 2).Subscribe(stats);

            source.OnNext(0);
            source.OnNext(1);
            source.OnNext(2);
            Assert.IsFalse(stats.NextCalled);

            source.OnCompleted();
            Assert.IsTrue(stats.CompletedCalled);
            Assert.IsTrue(stats.NextCalled);
            Assert.IsFalse(stats.NextValues[0]);
		}

        [Test]
        public void positive_value_is_received_immediately()
        {
            var source = new Subject<int>();

            var stats = new StatsObserver<bool>();

            source.Any(x => x > 2).Subscribe(stats);

            source.OnNext(3);
            Assert.IsTrue(stats.NextCalled);
            Assert.IsTrue(stats.NextValues[0]);
        }

        [Test]
        public void sequence_completes_after_positive_result()
        {
            var source = new Subject<int>();

            var stats = new StatsObserver<bool>();

            source.Any(x => x > 2).Subscribe(stats);

            source.OnNext(3);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void sequence_errors_after_error()
        {
            var source = new Subject<int>();

            var stats = new StatsObserver<bool>();

            source.Any(x => x > 2).Subscribe(stats);

            source.OnError(new ApplicationException());
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void empty_sequence_returns_false()
        {
            var stats = new StatsObserver<bool>();

            Observable.Empty<int>().Any(x => x > 2).Subscribe(stats);

            Assert.IsTrue(stats.CompletedCalled);
            Assert.IsTrue(stats.NextCalled);
            Assert.IsFalse(stats.NextValues[0]);
        }

        [Test]
        public void sequence_errors_after_exception_thrown_in_predicate()
        {
            var source = new Subject<int>();

            var stats = new StatsObserver<bool>();

            source.Any(x => { throw new ApplicationException(); }).Subscribe(stats);

            source.OnError(new ApplicationException());
            Assert.IsTrue(stats.ErrorCalled);
        }

    }
}

