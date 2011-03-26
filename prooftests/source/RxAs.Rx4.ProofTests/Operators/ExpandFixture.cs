using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using System.Concurrency;
using System.Reactive.Testing;
using System.Reactive.Testing.Mocks;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class ExpandFixture
    {
        [Test]
        public void asd()
        {
            var scheduler = new TestScheduler();

            var observer = new MockObserver<int>(scheduler);

            Observable.Range(0, 3, Scheduler.Immediate)
                .Expand(i => (i < 300) ? Observable.Return(i + 100) : Observable.Empty<int>())
                .Subscribe(observer);

            observer.AssertEqual(
                OnNext(0, 0),
                OnNext(0, 1),
                OnNext(0, 2),
                OnNext(0, 100),
                OnNext(0, 101),
                OnNext(0, 102),
                OnNext(0, 200),
                OnNext(0, 201),
                OnNext(0, 202),
                OnNext(0, 300),
                OnNext(0, 301),
                OnNext(0, 302),
                OnCompleted(0)
            );
        }

        [Test]
        public void recursively_expands_values_and_merges()
        {
            var scheduler = new TestScheduler();

            var observer = new MockObserver<int>(scheduler);

            scheduler.CreateColdObservable(
                OnNext(5, 0),
                OnNext(10, 1),
                OnNext(15, 2),
                OnCompleted(15)
            )
            .Expand(i => (i < 300)
                ? scheduler.CreateColdObservable(
                    OnNext(5, i + 100),
                    OnCompleted(5))
                : Observable.Empty<int>()
            )
            .Subscribe(observer);

            scheduler.Run();

            observer.AssertEqual(
                OnNext(5, 0),
                OnNext(10, 1),
                OnNext(10, 100),
                OnNext(15, 2),
                OnNext(15, 101),
                OnNext(15, 200),
                OnNext(20, 102),
                OnNext(20, 201),
                OnNext(20, 300),
                OnNext(25, 202),
                OnNext(25, 301),
                OnNext(30, 302),
                OnCompleted(30)
            );
        }

        private Recorded<Notification<int>> OnNext(long time, int value)
        {
            return new Recorded<Notification<int>>(time, new Notification<int>.OnNext(value));
        }

        private Recorded<Notification<int>> OnCompleted(long time)
        {
            return new Recorded<Notification<int>>(time, new Notification<int>.OnCompleted());
        }
    }
}
