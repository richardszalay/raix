using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class CastFixture
    {
        [Test]
        public void onerror_is_called_on_invalid_cast()
        {
            var arr = new object[]
            {
                new AssemblyLoadEventArgs(typeof(CastFixture).Assembly),
                new EventArgs(),
                new AssemblyLoadEventArgs(typeof(CastFixture).Assembly)
            };

            var observable = arr.ToObservable();

            var castObs = observable.Cast<AssemblyLoadEventArgs>();

            var stats = new StatsObserver<AssemblyLoadEventArgs>();
            castObs.Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.ErrorCalled);
        }
    }
}
