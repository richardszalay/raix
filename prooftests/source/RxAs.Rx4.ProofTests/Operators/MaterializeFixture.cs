using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class MaterializeFixture
    {
        [Test]
        public void oncomplete_still_raised()
        {
            var obs = Observable.Range(0, 5).Take(3).Materialize();

            int nextCalled = 0;
            bool completedCalled = false;

            var subs = obs.Subscribe(
                pl => nextCalled++,
                () => completedCalled = true
            );

            Assert.AreEqual(4, nextCalled);
            Assert.IsTrue(completedCalled);
        }

        [Test]
        public void oncomplete_is_raised_instead_of_error()
        {
            var obs = Observable.Range(0, 5).Take(3)
                .Concat(Observable.Throw<int>(new Exception()))
                .Materialize();

            int nextCalled = 0;
            bool errorCalled = false;
            bool completeCalled = false;

            var subs = obs.Subscribe(
                pl => nextCalled++,
                e => errorCalled = true,
                () => completeCalled = true
            );

            Assert.AreEqual(4, nextCalled);
            Assert.IsFalse(errorCalled);
            Assert.IsTrue(completeCalled);
        }

        [Test]
        public void unsubscribed_errors_do_not_cause_uncaught_exception()
        {
            var obs = Observable.Range(0, 5).Take(3)
                .Concat(Observable.Throw<int>(new Exception()))
                .Materialize();

            var subs = obs.Subscribe(
                pl => { }
            );
        }
    }
}
