using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class CreateFixture
    {
        [Test]
        public void create_calls_delegate()
        {
            bool createCalled = false;

            Observable.Create<int>(x => { createCalled = true; return () => { }; })
                .Subscribe(new Subject<int>());

            Assert.IsTrue(createCalled);
        }

        [Test]
        public void calls_dispose_function_when_unsubscribed_from()
        {
            bool disposeCalled = false;

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Create<int>(x => () => { disposeCalled = true; })
                .Subscribe(stats)
                .Dispose();

            Assert.IsTrue(disposeCalled);
        }

        [Test]
        public void calls_dispose_function_when_sequence_completes()
        {
            bool disposeCalled = false;

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Create<int>(x => { x.OnCompleted(); return () => { disposeCalled = true; }; })
                .Subscribe(stats);

            Assert.IsTrue(disposeCalled);
        }

        [Test]
        public void calls_dispose_function_when_sequence_errors()
        {
            bool disposeCalled = false;

            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Create<int>(x => { x.OnError(new Exception()); return () => { disposeCalled = true; }; })
                .Subscribe(stats);

            Assert.IsTrue(disposeCalled);
        }

        [Test, ExpectedException(typeof(ArgumentNullException))]
        public void throws_argument_error_when_return_value_is_null()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            Observable.Create<int>(x => null)
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }
    }
}
