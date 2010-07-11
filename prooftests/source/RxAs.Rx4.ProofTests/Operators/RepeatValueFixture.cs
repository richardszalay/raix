using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Disposables;
using System.Concurrency;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class RepeatValueFixture
    {
        [Test]
        public void repeatCount_includes_initial_subscription()
        {
            var stats = new StatsObserver<int>();

            Observable.Repeat(1, 2).Subscribe(stats);

            Assert.AreEqual(2, stats.NextCount);
        }

        [Test]
        public void repeats_specified_number_of_times()
        {
            var stats = new StatsObserver<int>();

            Observable.Repeat(1, 2).Subscribe(stats);

            Assert.AreEqual(2, stats.NextCount);
            Assert.AreEqual(1, stats.NextValues[0]);
            Assert.AreEqual(1, stats.NextValues[1]);
        }

        [Test]
        public void repeat_with_no_arguments_repeats_forever()
        {
            var stats = new StatsObserver<int>();

            Observable.Repeat(1).Take(100).Subscribe(stats);

            Assert.AreEqual(100, stats.NextCount);
        }
    }
}
