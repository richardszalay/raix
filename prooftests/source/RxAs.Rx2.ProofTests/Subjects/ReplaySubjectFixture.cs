using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;
using System.Threading;

namespace RxAs.Rx2.ProofTests.Subjects
{
    [TestFixture]
    public class ReplaySubjectFixture
    {
        [Test]
        public void sends_live_values()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            Assert.AreEqual(3, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2, 3}));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void sends_live_values_after_replay()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);

            subject.Subscribe(stats);

            subject.OnNext(3);
            subject.OnCompleted();

            Assert.AreEqual(3, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2, 3 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void replays_values_when_incomplete()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);

            subject.Subscribe(stats);

            Assert.AreEqual(3, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2, 3 }));
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void replays_values_when_complete()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            subject.Subscribe(stats);

            Assert.AreEqual(3, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2, 3 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void replays_values_when_errored()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnError(new Exception());

            subject.Subscribe(stats);

            Assert.AreEqual(3, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2, 3 }));
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void replays_empty_sequence()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnCompleted();

            subject.Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void replays_error_sequence()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnError(new Exception());

            subject.Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void ignores_buffer_size_for_live_subscriptions()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>(2);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            Assert.AreEqual(3, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2, 3 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void honours_buffer_size_for_replays_with_priority_to_most_recent()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>(2);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);

            subject.Subscribe(stats);

            Assert.AreEqual(2, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 2, 3 }));
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void buffer_size_includes_oncompleted()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>(2);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            subject.Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 3 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void buffer_size_includes_onerror()
        {
            ReplaySubject<int> subject = new ReplaySubject<int>(2);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnError(new Exception());

            subject.Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 3 }));
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void ignores_window_for_live_subscriptions()
        {
            ReplaySubject<int> subject = 
                new ReplaySubject<int>(TimeSpan.FromMilliseconds(10));

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            Assert.AreEqual(3, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2, 3 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void honours_window_for_replays_with_priority_to_most_recent()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject =
                new ReplaySubject<int>(TimeSpan.FromMilliseconds(10), scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            DateTime start = DateTime.UtcNow;

            scheduler.Now = start;
            subject.OnNext(1);

            scheduler.Now = start.AddMilliseconds(5);
            subject.OnNext(2);

            scheduler.Now = start.AddMilliseconds(10);
            subject.OnNext(3);

            scheduler.Now = start.AddMilliseconds(11);
            subject.Subscribe(stats);

            scheduler.RunAll();

            Assert.AreEqual(2, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 2, 3 }));
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void window_includes_oncompleted()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject =
                new ReplaySubject<int>(TimeSpan.FromMilliseconds(10), scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            DateTime start = DateTime.UtcNow;

            scheduler.Now = start;
            subject.OnNext(1);

            scheduler.Now = start.AddMilliseconds(5);
            subject.OnNext(2);

            scheduler.Now = start.AddMilliseconds(10);
            subject.OnCompleted();

            scheduler.Now = start.AddMilliseconds(11);
            subject.Subscribe(stats);

            scheduler.RunAll();

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 2 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void window_includes_onerror()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject =
                new ReplaySubject<int>(TimeSpan.FromMilliseconds(10), scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            DateTime start = DateTime.UtcNow;

            scheduler.Now = start;
            subject.OnNext(1);

            scheduler.Now = start.AddMilliseconds(5);
            subject.OnNext(2);

            scheduler.Now = start.AddMilliseconds(10);
            subject.OnError(new Exception());

            scheduler.Now = start.AddMilliseconds(11);
            subject.Subscribe(stats);

            scheduler.RunAll();

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 2 }));
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void window_can_pass_complete()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject =
                new ReplaySubject<int>(TimeSpan.FromMilliseconds(10), scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            DateTime start = DateTime.UtcNow;

            scheduler.Now = start;
            subject.OnCompleted();

            scheduler.Now = start.AddMilliseconds(11);
            subject.Subscribe(stats);

            scheduler.RunAll();

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void window_can_pass_error()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject =
                new ReplaySubject<int>(TimeSpan.FromMilliseconds(10), scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            DateTime start = DateTime.UtcNow;

            scheduler.Now = start;
            subject.OnError(new Exception());

            scheduler.Now = start.AddMilliseconds(11);
            subject.Subscribe(stats);

            scheduler.RunAll();

            Assert.IsFalse(stats.ErrorCalled);
        }

        [Test]
        public void with_both_window_and_buffer_size_values_can_be_ignored_by_buffer_size()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject =
                new ReplaySubject<int>(2, TimeSpan.FromMilliseconds(10), scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            DateTime start = DateTime.UtcNow;

            scheduler.Now = start; // ignored by buffer size
            subject.OnNext(1);

            scheduler.Now = start.AddMilliseconds(5);
            subject.OnNext(2);

            scheduler.Now = start.AddMilliseconds(8);
            subject.OnCompleted();

            scheduler.Now = start.AddMilliseconds(8);
            subject.Subscribe(stats);

            scheduler.RunAll();

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 2 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void with_both_window_and_buffer_size_values_can_be_ignored_by_window()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject =
                new ReplaySubject<int>(3, TimeSpan.FromMilliseconds(10), scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            DateTime start = DateTime.UtcNow;

            scheduler.Now = start; // ignored by window
            subject.OnNext(1);

            scheduler.Now = start.AddMilliseconds(5);
            subject.OnNext(2);

            scheduler.Now = start.AddMilliseconds(8);
            subject.OnCompleted();

            scheduler.Now = start.AddMilliseconds(11);
            subject.Subscribe(stats);

            scheduler.RunAll();

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 2 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void live_values_are_sent_through_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject = new ReplaySubject<int>(scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnCompleted();

            Assert.IsFalse(stats.NextCalled);

            scheduler.RunNext();
            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1 }));
            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();
            Assert.AreEqual(2, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2 }));
            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void replayed_values_are_sent_through_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject = new ReplaySubject<int>(scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnCompleted();

            subject.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);

            scheduler.RunNext();
            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1 }));
            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();
            Assert.AreEqual(2, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2 }));
            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void errors_are_sent_through_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject = new ReplaySubject<int>(scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnError(new Exception());

            subject.Subscribe(stats);

            Assert.IsFalse(stats.ErrorCalled);

            scheduler.RunNext();
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void values_can_be_replayed_out_of_order()
        {
            ManualScheduler scheduler = new ManualScheduler();

            ReplaySubject<int> subject = new ReplaySubject<int>(scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);

            subject.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);

            scheduler.RunNext();
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1 }));

            subject.OnNext(3);

            scheduler.RunNext();
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1, 2 }));

            subject.OnCompleted();

            scheduler.RunNext();
            Assert.IsTrue(stats.CompletedCalled);
        }
    }
}
