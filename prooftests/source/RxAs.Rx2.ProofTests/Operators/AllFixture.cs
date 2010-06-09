using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class AllFixture
    {
        [Test]
        public void empty_sequence()
        {
            var stats = new StatsObserver<bool>();

            Observable.Empty<int>()
                .All(x => true)
                .Subscribe(stats);

            Assert.IsTrue(stats.NextValues[0]);

        }
    }
}
