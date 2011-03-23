using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Concurrency;
using System.Reactive.Testing;
using System.Reactive.Testing.Mocks;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class SampleFixture
    {
        [Test]
        public void uses_scheduler_to_schedule_samples()
        {
            var subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var scheduler = new ManualScheduler();

            subject
                .Sample(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);

            Assert.AreEqual(1, scheduler.QueueSize);

            subject.OnNext(0);
            scheduler.RunNext();

            Assert.AreEqual(1, scheduler.QueueSize);
            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0]);
        }

        [Test]
        public void last_value_is_taken_for_each_sample()
        {
            var subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var scheduler = new ManualScheduler();

            subject
                .Sample(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);

            subject.OnNext(0);
            subject.OnNext(1);
            scheduler.RunNext();

            subject.OnNext(2);
            subject.OnNext(3);
            scheduler.RunNext();

            Assert.AreEqual(2, stats.NextCount);
            Assert.AreEqual(1, stats.NextValues[0]);
            Assert.AreEqual(3, stats.NextValues[1]);
        }

        [Test]
        public void last_value_from_timeout_period_is_used()
        {
            TestScheduler scheduler = new TestScheduler();

            Subject<int> subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            subject.Sample(TimeSpan.FromSeconds(1), scheduler).Subscribe(stats);

            subject.OnNext(0);
            subject.OnNext(1);
            scheduler.RunTo(TimeSpan.FromMilliseconds(200).Ticks);

            subject.OnNext(2);
            subject.OnNext(3);
            scheduler.RunTo(TimeSpan.FromMilliseconds(1000).Ticks);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(3, stats.NextValues[0]);
        }

        [Test]
        public void no_value_is_emitted_if_sampled_value_hasnt_changed()
        {
            var subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var scheduler = new ManualScheduler();

            subject
                .Sample(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);

            stats.OnNext(0);

            scheduler.RunNext();
            scheduler.RunNext();

            Assert.AreEqual(1, stats.NextCount);
        }

        [Test]
        public void no_value_is_emitted_if_empty()
        {
            var subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var scheduler = new ManualScheduler();

            subject
                .Sample(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);

            Assert.AreEqual(1, scheduler.QueueSize);

            scheduler.RunNext();

            Assert.AreEqual(1, scheduler.QueueSize);
            Assert.AreEqual(0, stats.NextCount);
        }

        [Test]
        public void completion_occurs_after_interval()
        {
            var scheduler = new ManualScheduler();
            var stats = new StatsObserver<int>();

            Observable.Empty<int>()
                .Sample(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);

            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void latest_value_is_sampled_at_next_sample_time_after_completion()
        {
            var subject = new Subject<int>();

            var scheduler = new TestScheduler();

            var observer = new MockObserver<int>(scheduler);

            scheduler.CreateColdObservable(
                new Recorded<Notification<int>>(5, new Notification<int>.OnNext(0)),
                new Recorded<Notification<int>>(6, new Notification<int>.OnCompleted())
                )
                .Sample(new TimeSpan(15), scheduler)
                .Subscribe(observer);

            scheduler.Run();

            observer.AssertEqual(
                new Recorded<Notification<int>>(15, new Notification<int>.OnNext(0)),
                new Recorded<Notification<int>>(15, new Notification<int>.OnCompleted())
                );
        }

        [Test]
        public void interval_is_cancelled_on_completion()
        {
            var subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var scheduler = new ManualScheduler();

            subject
                .Sample(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);

            subject.OnNext(0);
            subject.OnCompleted();
            scheduler.RunNext();

            Assert.AreEqual(0, scheduler.QueueSize);
        }

        [Test]
        public void errors_do_not_wait_for_interval()
        {
            var scheduler = new ManualScheduler();

            var stats = new StatsObserver<int>();

            Observable.Throw<int>(new ApplicationException())
                .Sample(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void errors_cancel_interval()
        {
            var scheduler = new ManualScheduler();

            var stats = new StatsObserver<int>();

            Observable.Throw<int>(new ApplicationException())
                .Sample(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);

            Assert.AreEqual(0, scheduler.QueueSize);
        }
    }
}
