using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class WindowFixture
    {
        Subject<int> source;
        List<StatsSubject<Unit>> windows;

        List<StatsObserver<int>> windowsStats;
        StatsObserver<int> overallStats;

        IDisposable subscription;

        [SetUp]
        public void SetUp()
        {
            source = new Subject<int>();
            windows = new List<StatsSubject<Unit>>();
            windowsStats = new List<StatsObserver<int>>();
            overallStats = new StatsObserver<int>();

            subscription = source.Window(() => 
                {
                    StatsSubject<Unit> window = new StatsSubject<Unit>();

                    windows.Add(window);

                    return window;
                })
                .Subscribe(o =>
                {
                    var stats = new StatsObserver<int>();
                    windowsStats.Add(stats);

                    o.Subscribe(stats);
                },
                overallStats.OnError,
                overallStats.OnCompleted);
        }

        [Test]
        public void first_window_is_opened_immediately()
        {
            Assert.AreEqual(1, windowsStats.Count);
        }

        [Test]
        public void values_within_window_are_emitted()
        {
            source.OnNext(0);
            source.OnNext(1);
            source.OnNext(2);

            Assert.AreEqual(1, windowsStats.Count);
            Assert.AreEqual(3, windowsStats[0].NextCount);
            Assert.AreEqual(new int[] { 0, 1, 2 }, windowsStats[0].NextValues);
        }

        [Test]
        public void new_window_is_opened_immediately_after_last_window_closes()
        {
            source.OnNext(0);
            source.OnNext(1);

            windows[0].OnNext(new Unit());

            Assert.AreEqual(2, windowsStats.Count);
        }

        [Test]
        public void windows_can_be_completed_using_oncompleted()
        {
            source.OnNext(0);
            source.OnNext(1);

            windows[0].OnCompleted();

            Assert.AreEqual(2, windowsStats.Count);
        }

        [Test]
        public void previous_window_values_are_completed_when_new_window_opens()
        {
            windows[0].OnCompleted();

            Assert.IsTrue(windowsStats[0].CompletedCalled);
        }

        [Test]
        public void source_observer_completes_when_source_completes()
        {
            source.OnCompleted();

            Assert.IsTrue(overallStats.CompletedCalled);
        }

        [Test]
        public void open_window_completes_when_source_completes()
        {
            source.OnCompleted();

            Assert.IsTrue(windowsStats[0].CompletedCalled);
        }

        [Test]
        public void open_window_errors_when_source_errors()
        {
            source.OnError(new Exception());

            Assert.IsTrue(windowsStats[0].ErrorCalled);
        }

        [Test]
        public void source_observer_errors_when_source_errors()
        {
            source.OnError(new Exception());

            Assert.IsTrue(overallStats.ErrorCalled);
        }

        [Test]
        public void source_observer_errors_when_open_window_errors()
        {
            windows[0].OnError(new Exception());

            Assert.IsTrue(overallStats.ErrorCalled);
        }

        [Test]
        public void window_observer_errors_when_open_window_errors()
        {
            windows[0].OnError(new Exception());

            Assert.IsTrue(this.windowsStats[0].ErrorCalled);
        }

        [Test]
        public void unsubscripes_from_open_window_when_source_subscription_is_disposed()
        {
            subscription.Dispose();

            Assert.IsFalse(windows[0].HasSubscriptions);
        }
    }
}
