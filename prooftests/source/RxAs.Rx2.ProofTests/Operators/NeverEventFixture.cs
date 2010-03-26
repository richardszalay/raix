using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;
using System.Threading;

namespace RxAs.Rx2.ProofTests.Operators
{
    public class NeverEventFixture
    {
        private IObservable<int> obs;
		
		[SetUp]
		public void Setup()
		{
            obs = Observable.Empty<int>();
		}
		
		[Test]
        public void does_not_call_any_methods_on_observer()
        {
            var obs = Observable.Never<int>();

            bool wasCalled = false;

            obs.Subscribe(
                pl => wasCalled = true,
                e => wasCalled = true,
                () => wasCalled = true
                );

            Thread.Sleep(200);

            Assert.IsFalse(wasCalled);
        }
    }
}
