using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class CatchFixture
    {
        [Test]
        public void catch_with_observer_does_not_fire_onerror()
        {
            StatsObserver<int> observer = new StatsObserver<int>();

            Observable.Throw<int>(new ApplicationException())
                .Catch(Observable.Empty<int>())
                .Subscribe(observer);

            Assert.IsFalse(observer.ErrorCalled);
        }

        [Test]
        public void catch_with_observer_fires_error_if_last_observer_raises_error()
        {
            StatsObserver<int> observer = new StatsObserver<int>();

            Observable.Throw<int>(new ApplicationException())
                .Catch(Observable.Throw<int>(new ApplicationException()))
                .Subscribe(observer);

            Assert.IsTrue(observer.ErrorCalled);
        }

        [Test]
        public void catch_with_action_does_not_fire_onerror()
        {
            StatsObserver<int> observer = new StatsObserver<int>();

            Observable.Throw<int>(new ApplicationException())
                .Catch<int,Exception>(e => Observable.Empty<int>())
                .Subscribe(observer);

            Assert.IsFalse(observer.ErrorCalled);
        }

        [Test]
        public void catch_with_action_fires_error_if_last_observer_raises_error()
        {
            StatsObserver<int> observer = new StatsObserver<int>();

            Observable.Throw<int>(new Exception())
                .Catch<int, Exception>(e => Observable.Throw<int>(new ApplicationException()))
                .Subscribe(observer);


            Assert.IsTrue(observer.ErrorCalled);
            Assert.IsInstanceOf<ApplicationException>(observer.Error);
        }

        [Test]
        public void catch_with_action_fires_error_if_action_throws_exception()
        {
            StatsObserver<int> observer = new StatsObserver<int>();

            Observable.Throw<int>(new Exception())
                .Catch<int, Exception>(e => { throw new ApplicationException(); })
                .Subscribe(observer);


            Assert.IsTrue(observer.ErrorCalled);
            Assert.IsInstanceOf<ApplicationException>(observer.Error);
        }

        [Test]
        public void catch_with_action_fires_original_error_if_error_is_not_of_specified_type()
        {
            StatsObserver<int> observer = new StatsObserver<int>();

            Observable.Throw<int>(new OverflowException())
                .Catch<int, ApplicationException>(e => { Assert.Fail("Unexpected call to defer action"); return null; })
                .Subscribe(observer);


            Assert.IsTrue(observer.ErrorCalled);
            Assert.IsInstanceOf<OverflowException>(observer.Error);
        }

        [Test]
        public void catch_with_action_raises_original_error_if_action_returns_null()
        {
            StatsObserver<int> observer = new StatsObserver<int>();

            Observable.Throw<int>(new OverflowException())
                .Catch<int, ApplicationException>(e => null)
                .Subscribe(observer);


            Assert.IsTrue(observer.ErrorCalled);
            Assert.IsInstanceOf<OverflowException>(observer.Error);
        }

        private class EventOwner
        {
            public event EventHandler<EventArgs> Event;

            public void Fire()
            {
                var handler = Event;

                if (handler != null)
                {
                    handler(this, EventArgs.Empty);
                }
            }

            public bool HasSubscriptions
            {
                get { return Event != null; }
            }
        }
    }
}
