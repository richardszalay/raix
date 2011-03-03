using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Concurrency;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class WndowWithTimeFixture
    {
        private StatsObserver<IObservable<int>> stats = new StatsObserver<IObservable<int>>();

        private Subject<int> subject = new Subject<int>();

        private TimeSpan timeSpan = TimeSpan.FromMilliseconds(50);
        private TimeSpan timeShift = TimeSpan.FromMilliseconds(10);

        private TestScheduler scheduler = new TestScheduler();

        [SetUp]
        public void SetUp()
        {
            stats = new StatsObserver<IObservable<int>>();

            subject = new Subject<int>();

            timeSpan = TimeSpan.FromMilliseconds(50);
            timeShift = TimeSpan.FromMilliseconds(10);

            scheduler = new TestScheduler();
        }

        [Test]
        public void genenrates_window_on_subscription_using_scheduler()
        {
            subject.WindowWithTime(timeSpan, timeShift, scheduler)
                .Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);

            scheduler.RunTo(1);
            Assert.AreEqual(1, stats.NextCount);
        }

        [Test]
        public void genenrates_new_window_after_timeshift()
        {
            subject.WindowWithTime(timeSpan, timeShift, scheduler)
                .Subscribe(stats);

            scheduler.RunTo(timeShift.Ticks + 1);

            Assert.AreEqual(2, stats.NextCount);
        }
    }
}
