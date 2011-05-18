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
    public class MergeManyFixture
    {
        private TestScheduler scheduler;
        private HotObservable<int>[] sources;

        [SetUp]
        public void SetUp()
        {
            scheduler = new TestScheduler();

            var sourceA = scheduler.CreateHotObservable(
                OnNext(5, 0),
                OnNext(25, 1),
                OnNext(45, 2),
                OnNext(65, 3),
                OnNext(85, 4),
                OnCompleted(85)
                );

            var sourceB = scheduler.CreateHotObservable(
                OnNext(10, 10),
                OnNext(30, 11),
                OnNext(50, 12),
                OnNext(70, 13),
                OnNext(90, 14),
                OnCompleted(90)
                );

            var sourceC = scheduler.CreateHotObservable(
                OnNext(15, 20),
                OnNext(35, 21),
                OnNext(55, 22),
                OnNext(75, 23),
                OnNext(95, 24),
                OnCompleted(95)
                );

            sources = new HotObservable<int>[] { sourceA, sourceB, sourceC };
        }

        [Test]
        public void concurrent_messages_are_merged()
        {
            var observer = new MockObserver<int>(scheduler);

            Observable.Merge(sources.ToObservable(), 2)
                .Subscribe(observer);

            scheduler.Run();

            observer.AssertEqual(
                OnNext(5, 0),
                OnNext(10, 10),
                OnNext(25, 1),
                OnNext(30, 11),
                OnNext(45, 2),
                OnNext(50, 12),
                OnNext(65, 3),
                OnNext(70, 13),
                OnNext(85, 4), // sourceA completes, sourceC subscribes
                OnNext(90, 14), 
                OnNext(95, 24),
                OnCompleted(95)
                );
        }

        [Test]
        public void queued_streams_are_subscribed_to_when_a_merged_stream_completes()
        {
            var observer = new MockObserver<int>(scheduler);

            Observable.Merge(sources.ToObservable(), 2)
                .Subscribe(observer);

            scheduler.Run();

            Assert.AreEqual(85, sources[2].Subscriptions[0].Subscribe);
        }

        [Test]
        public void all_streams_are_merged_if_no_concurrent_value_is_supplied()
        {
            var observer = new MockObserver<int>(scheduler);

            Observable.Merge((IObservable<IObservable<int>>)sources.ToObservable())
                .Subscribe(observer);

            scheduler.Run();

            observer.AssertEqual(
                OnNext(5, 0),
                OnNext(10, 10),
                OnNext(15, 20),
                OnNext(25, 1),
                OnNext(30, 11),
                OnNext(35, 21),
                OnNext(45, 2),
                OnNext(50, 12),
                OnNext(55, 22),
                OnNext(65, 3),
                OnNext(70, 13),
                OnNext(75, 23),
                OnNext(85, 4), // sourceA completes, sourceC subscribes
                OnNext(90, 14),
                OnNext(95, 24),
                OnCompleted(95)
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
