using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class ScanFixture
    {
        [Test]
        public void outputs_one_value_for_each_input()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(0, 5)
                .Scan((x, y) => x + y)
                .Subscribe(stats);

            Assert.AreEqual(5, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0]);
            Assert.AreEqual(1, stats.NextValues[1]);
            Assert.AreEqual(3, stats.NextValues[2]);
            Assert.AreEqual(6, stats.NextValues[3]);
            Assert.AreEqual(10, stats.NextValues[4]);
        }

        [Test]
        public void outputs_accumulator_type_if_different()
        {
            StatsObserver<DateTimeOffset> stats = new StatsObserver<DateTimeOffset>();

            DateTimeOffset start = DateTimeOffset.UtcNow;

            Observable.Range(0, 5)
                .Scan(start, (x, y) => x.AddDays(y))
                .Subscribe(stats);

            Assert.AreEqual(5, stats.NextCount);
            Assert.AreEqual(start.AddDays(0), stats.NextValues[0]);
            Assert.AreEqual(start.AddDays(1), stats.NextValues[1]);
            Assert.AreEqual(start.AddDays(3), stats.NextValues[2]);
            Assert.AreEqual(start.AddDays(6), stats.NextValues[3]);
            Assert.AreEqual(start.AddDays(10), stats.NextValues[4]);
        }

        [Test]
        public void calls_accumulator_for_first_value_when_initial_value_supplied()
        {
            StatsObserver<DateTimeOffset> stats = new StatsObserver<DateTimeOffset>();

            List<int> accumulatorValues = new List<int>();

            DateTimeOffset start = DateTimeOffset.UtcNow;

            Observable.Range(0, 5)
                .Scan(start, (x, y) => { accumulatorValues.Add(y); return x.AddDays(y); })
                .Subscribe(stats);

            Assert.AreEqual(0, accumulatorValues[0]);
        }

        [Test]
        public void does_not_call_accumulator_for_first_value_initial_value_not_supplied()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            List<int> accumulatorValues = new List<int>();

            Observable.Range(0, 5)
                .Scan((x, y) => { accumulatorValues.Add(y); return x + y; })
                .Subscribe(stats);

            Assert.AreEqual(1, accumulatorValues[0]);
        }

        [Test]
        public void does_not_error_on_empty_source()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Empty<int>()
                .Scan((x, y) => x + y)
                .Subscribe(stats);

            Assert.IsFalse(stats.ErrorCalled);
            Assert.IsTrue(stats.CompletedCalled);
        }
    }
}
