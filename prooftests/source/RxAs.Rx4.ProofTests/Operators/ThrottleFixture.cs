using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RxAs.Rx4.ProofTests.Mock;
using NUnit.Framework;
using System.Concurrency;
using System.Reactive.Testing;
using System.Reactive.Testing.Mocks;
using System.Diagnostics;
using RxAs.Rx4.ProofTests.Extensions;

namespace RxAs.Rx4.ProofTests.Operators
{
    public class ThrottleFixture
    {
        private TestScheduler scheduler;
        private MockObserver<int> observer;
        private ColdObservable<int> observable;

        [SetUp]
        public void SetUp()
        {
            scheduler = new TestScheduler();

            observable = scheduler.CreateColdObservable(
                Next(10, 1),
                Next(15, 2),
                Next(20, 3),
                Next(35, 4),
                Next(40, 5));

            observer = new MockObserver<int>(scheduler);
         
            observable
                .Throttle(TimeSpan.FromTicks(5), scheduler)
                .Subscribe(observer);
        }

        [Test]
        public void immediately_subscribes_to_source()
        {
            Assert.AreEqual(1, observable.Subscriptions.Count);
        }

        [Test]
        public void values_are_not_released_when_emitted()
        {
            scheduler.RunTo(10);

            Assert.AreEqual(0, observer.Count);
        }

        [Test]
        public void value_is_released_after_no_values_received_in_duration()
        {
            scheduler.RunTo(25);

            Assert.AreEqual(1, observer.Count);
        }

        [Test]
        public void last_value_before_duration_is_emitted()
        {
            scheduler.RunTo(25);

            Assert.AreEqual(3, observer[0].Value.Value);
        }

        [Test]
        public void timeout_is_reset_after_next_value_is_received()
        {
            scheduler.RunTo(45);

            Assert.AreEqual(2, observer.Count);
            Assert.AreEqual(5, observer.GetValue(1));
        }

        private Recorded<Notification<int>> Next(long ticks, int value)
        {
            return new Recorded<Notification<int>>(ticks,
                new Notification<int>.OnNext(value));
        }
    }
}
