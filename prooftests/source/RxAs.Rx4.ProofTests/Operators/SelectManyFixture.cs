using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Disposables;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class SelectManyFixture
    {
        [Test]
		public void observables_are_used_from_each_source_value()
		{
            var stats = new StatsObserver<int>();

            var manObs = Observable.Range(0, 3)
                .SelectMany(x => Observable.Range(x * 2, 2))
                .Subscribe(stats);

            Assert.AreEqual(6, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0]);
            Assert.AreEqual(1, stats.NextValues[1]);
            Assert.AreEqual(2, stats.NextValues[2]);
            Assert.AreEqual(3, stats.NextValues[3]);
            Assert.AreEqual(4, stats.NextValues[4]);
            Assert.AreEqual(5, stats.NextValues[5]);
		}

        [Test]
        public void values_are_taken_from_each_selected_value()
        {
            var stats = new StatsObserver<int>();

            var source = new Subject<int>();
            var first = new Subject<int>();
            var second = new Subject<int>();

            var remaining = new Queue<IObservable<int>>();
            remaining.Enqueue(first);
            remaining.Enqueue(second);

            var manObs = source
                .SelectMany(x => remaining.Dequeue())
                .Subscribe(stats);

            source.OnNext(0);
            first.OnNext(1);

            source.OnNext(2);
            second.OnNext(3);
            first.OnNext(4);
            second.OnNext(5);

            Assert.AreEqual(4, stats.NextCount);
            Assert.AreEqual(1, stats.NextValues[0]);
            Assert.AreEqual(3, stats.NextValues[1]);
            Assert.AreEqual(4, stats.NextValues[2]);
            Assert.AreEqual(5, stats.NextValues[3]);
        }

        [Test, ExpectedException(typeof(ArgumentNullException))]
        public void exception_thrown_when_selector_returns_null()
        {
            var stats = new StatsObserver<int>();

            var source = new Subject<int>();

            var manObs = source
                .SelectMany<int, int>(x => (IObservable<int>)null)
                .Subscribe(stats);

            source.OnNext(0);
            source.OnNext(2);

            Assert.AreEqual(0, stats.NextCount);
        }

        [Test]
        public void onerror_called_when_selector_throws_exception()
        {
            var stats = new StatsObserver<int>();

            var source = new Subject<int>();

            var manObs = source
                .SelectMany<int, int>(x => { throw new InvalidOperationException(); return (IObservable<int>)null; })
                .Subscribe(stats);

            source.OnNext(0);
            source.OnNext(2);

            Assert.AreEqual(1, stats.ErrorCount);
        }
		
    }
}
