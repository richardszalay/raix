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
    public class FinallyFixture
    {
        [Test]
        public void finally_action_is_executed_on_complete()
        {
            bool finallyCalled = false;

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Empty<int>()
                .Finally(() =>
                {
                    finallyCalled = true;
                })
                .Subscribe(stats);

            Assert.IsTrue(finallyCalled);
        }

        [Test]
        public void finally_action_is_executed_after_complete()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Empty<int>()
                .Finally(() =>
                {
                    Assert.IsTrue(stats.CompletedCalled);
                })
                .Subscribe(stats);
        }

        [Test]
        public void finally_action_is_executed_on_error()
        {
            bool finallyCalled = false;

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Throw<int>(new ApplicationException())
                .Finally(() =>
                    {
                        finallyCalled = true;
                    })
                .Subscribe(stats);

            Assert.IsTrue(finallyCalled);
        }

        [Test]
        public void finally_action_is_executed_after_error()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Throw<int>(new ApplicationException())
                .Finally(() =>
                {
                    Assert.IsTrue(stats.ErrorCalled);
                })
                .Subscribe(stats);
        }

        [Test]
        public void finally_action_is_executed_after_source_subscription_is_disposed()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            bool sourceSubscriptionDisposed = true;

            Observable.CreateWithDisposable<int>(obs =>
                {
                    return Disposable.Create(() =>
                        {
                            sourceSubscriptionDisposed = true;
                        });
                })
                .Finally(() =>
                {
                    Assert.IsTrue(sourceSubscriptionDisposed);
                })
                .Subscribe(stats)
                .Dispose();
        }

        [Test, ExpectedException(typeof(ApplicationException))]
        public void finally_action_is_executed_if_disposition_source_subscription_throws_exception()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            bool finallyCalled = true;

            try
            {
                Observable.CreateWithDisposable<int>(obs =>
                    {
                        return Disposable.Create(() =>
                        {
                            throw new ApplicationException();
                        });
                    })
                    .Finally(() =>
                    {
                        finallyCalled = true;
                    })
                    .Subscribe(stats)
                    .Dispose();
            }
            finally
            {
                Assert.IsTrue(finallyCalled);
            }
        }
    }
}
