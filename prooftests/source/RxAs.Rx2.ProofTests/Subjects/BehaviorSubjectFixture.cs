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
    public class BehaviorSubjectFixture
    {

        [Test]
        public void sends_live_values()
        {
            BehaviorSubject<int> subject = new BehaviorSubject<int>(0);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            Assert.AreEqual(4, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 0, 1, 2, 3}));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void only_replays_one_value()
        {
            BehaviorSubject<int> subject = new BehaviorSubject<int>(0);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);

            subject.Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 2 }));
        }

        [Test]
        public void sends_live_values_after_replay()
        {
            BehaviorSubject<int> subject = new BehaviorSubject<int>(0);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);

            subject.Subscribe(stats);

            subject.OnNext(3);
            subject.OnCompleted();

            Assert.AreEqual(2, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 2, 3 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void replays_no_values_when_complete()
        {
            BehaviorSubject<int> subject = new BehaviorSubject<int>(0);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            subject.Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void replays_no_values_when_errored()
        {
            BehaviorSubject<int> subject = new BehaviorSubject<int>(0);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnError(new Exception());

            subject.Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void replays_empty_sequence()
        {
            BehaviorSubject<int> subject = new BehaviorSubject<int>(0);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnCompleted();

            subject.Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void replays_error_sequence()
        {
            BehaviorSubject<int> subject = new BehaviorSubject<int>(0);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnError(new Exception());

            subject.Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }


        [Test]
        public void live_values_are_sent_through_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            BehaviorSubject<int> subject = new BehaviorSubject<int>(0, scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnCompleted();

            Assert.IsFalse(stats.NextCalled);

            scheduler.RunNext();
            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 0 }));
            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();
            Assert.AreEqual(2, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 0, 1 }));
            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();
            Assert.AreEqual(3, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 0, 1, 2 }));
            Assert.IsFalse(stats.CompletedCalled);

            scheduler.RunNext();
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void replayed_values_are_sent_through_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            BehaviorSubject<int> subject = new BehaviorSubject<int>(0, scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);

            subject.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);

            scheduler.RunNext();
            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 1 }));
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void default_value_is_sent_through_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            BehaviorSubject<int> subject = new BehaviorSubject<int>(0, scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);

            scheduler.RunNext();
            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 0 }));
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void complete_is_sent_through_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            BehaviorSubject<int> subject = new BehaviorSubject<int>(0, scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnCompleted();

            subject.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);

            scheduler.RunNext();
            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void errors_are_sent_through_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            BehaviorSubject<int> subject = new BehaviorSubject<int>(0, scheduler);

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnError(new Exception());

            subject.Subscribe(stats);

            Assert.IsFalse(stats.ErrorCalled);

            scheduler.RunNext();
            Assert.IsTrue(stats.ErrorCalled);
        }
    }
}
