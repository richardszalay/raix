using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
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

        [Test, ExpectedException(typeof(ArgumentOutOfRangeException))]
        public void take_zero_throws_argument_exception()
        {
            Observable.Range(0, 5).Take(0);
        }
    }
}
