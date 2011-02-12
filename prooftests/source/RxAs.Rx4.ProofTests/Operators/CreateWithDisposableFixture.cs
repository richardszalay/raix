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
    public class CreateWithDisposableFixture
    {
        [Test]
        public void create_calls_delegate()
        {
            bool createCalled = false;

            Observable.CreateWithDisposable<int>(x => { createCalled = true; return Disposable.Empty; })
                .Subscribe(new Subject<int>());

            Assert.IsTrue(createCalled);
        }

        [Test]
        public void calls_dispose_function_when_unsubscribed_from()
        {
            bool disposeCalled = false;

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.CreateWithDisposable<int>(x => Disposable.Create(() => { disposeCalled = true; }))
                .Subscribe(stats)
                .Dispose();

            Assert.IsTrue(disposeCalled);
        }

        [Test]
        public void calls_dispose_function_when_sequence_completes()
        {
            bool disposeCalled = false;

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.CreateWithDisposable<int>(x => 
            { 
                x.OnCompleted();

                return Disposable.Create(() => { disposeCalled = true; });
            })
            .Subscribe(stats);

            Assert.IsTrue(disposeCalled);
        }

        [Test]
        public void calls_dispose_function_when_sequence_errors()
        {
            bool disposeCalled = false;

            StatsObserver<int> stats = new StatsObserver<int>();
            

            Observable.CreateWithDisposable<int>(x => 
            { 
                x.OnError(new Exception());

                return Disposable.Create(() => { disposeCalled = true; });
            })
            .Subscribe(stats);

            Assert.IsTrue(disposeCalled);
        }

        [Test]
        public void supports_null_cancelable_value()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.CreateWithDisposable<int>(x => null)
                .Subscribe(stats)
                .Dispose();
        }
    }
}
