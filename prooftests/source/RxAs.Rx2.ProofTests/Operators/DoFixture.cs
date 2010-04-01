using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class DoFixture
    {
        [Test]
        public void next_action_is_called_before_observer()
        {
            bool doCalled = false;
            bool observerCalled = false;

            Observable.Range(0, 1)
                .Do(x => { Assert.IsFalse(observerCalled); doCalled = true; })
                .Subscribe(x => { Assert.IsTrue(doCalled); observerCalled = true; });

            Assert.IsTrue(doCalled);
            Assert.IsTrue(observerCalled);
        }

        [Test]
        public void complete_action_is_called_before_observer()
        {
            bool doCalled = false;
            bool observerCalled = false;

            Observable.Range(0, 1)
                .Do(x => {}, () => { Assert.IsFalse(observerCalled); doCalled = true; })
                .Subscribe(x => {}, () => { Assert.IsTrue(doCalled); observerCalled = true; });

            Assert.IsTrue(doCalled);
            Assert.IsTrue(observerCalled);
        }

        [Test]
        public void error_action_is_called_before_observer()
        {
            bool doCalled = false;
            bool observerCalled = false;

            Observable.Throw<int>(new Exception())
                .Do(x => { }, e => { Assert.IsFalse(observerCalled); doCalled = true; })
                .Subscribe(x => { }, e => { Assert.IsTrue(doCalled); observerCalled = true; });

            Assert.IsTrue(doCalled);
            Assert.IsTrue(observerCalled);
        }

        [Test]
        public void exception_thrown_in_next_action_sent_to_onerror_when_only_next_action_is_used()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(0, 2)
                .Do(x => { throw new Exception(); })
                .Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test, ExpectedException(typeof(ApplicationException))]
        public void exception_thrown_in_next_action_bubbles_when_error_action_is_specifid()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(0, 2)
                .Do(x => { throw new ApplicationException(); }, e => { })
                .Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void exception_thrown_in_next_action_bubbles_when_complete_action_is_specifid()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(0, 2)
                .Do(x => { throw new Exception(); }, e => {},  () => { })
                .Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void exception_thrown_in_next_action_sent_to_error_action()
        {
            bool doCalled = false;
            bool observerCalled = false;

            Observable.Range(0, 5)
                .Do(x => { throw new Exception(); }, e => { observerCalled = true; })
                .Subscribe(x => { }, e => { }, () => { });

            Assert.IsTrue(observerCalled);
        }

        [Test, ExpectedException(typeof(ApplicationException))]
        public void exception_thrown_in_complete_action_is_bubbled()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Range(0, 2)
                .Do(x => { }, () => { throw new ApplicationException(); })
                .Subscribe(stats);
        }

        [Test, ExpectedException(typeof(ApplicationException))]
        public void exception_thrown_in_error_action_is_bubbled()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Throw<int>(new Exception())
                .Do(x => { }, e => { throw new ApplicationException(); })
                .Subscribe(stats);
        }
    }
}

