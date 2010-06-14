using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Threading;

namespace RxAs.Rx4.ProofTests.Subjects
{
    [TestFixture]
    public class AsyncSubjectFixture
    {
		[Test]
        public void sends_no_values_before_completion()
        {
            AsyncSubject<int> subject = new AsyncSubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void sends_last_value_after_completion_if_subscribed_before_values()
        {
            AsyncSubject<int> subject = new AsyncSubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.Subscribe(stats);

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            Assert.AreEqual(1, stats.NextCount);
            Assert.IsTrue(stats.NextValues.SequenceEqual(new int[] { 3 }));
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void sends_last_value_after_completion_if_subscribed_after_values()
        {
            AsyncSubject<int> subject = new AsyncSubject<int>();

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
        public void sends_no_values_after_error()
        {
            AsyncSubject<int> subject = new AsyncSubject<int>();

            StatsObserver<int> stats = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnError(new Exception());

            subject.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void scheduler_is_used_to_distribute_values()
        {
            ManualScheduler scheduler = new ManualScheduler();

            AsyncSubject<int> subject = new AsyncSubject<int>(scheduler);

            StatsObserver<int> statsA = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            subject.Subscribe(statsA);

            Assert.IsFalse(statsA.NextCalled);

            scheduler.RunNext();

            Assert.IsTrue(statsA.NextCalled);
        }

        [Test]
        public void next_and_complete_are_scheduled_separately()
        {
            ManualScheduler scheduler = new ManualScheduler();

            AsyncSubject<int> subject = new AsyncSubject<int>(scheduler);

            StatsObserver<int> statsA = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            subject.Subscribe(statsA);

            Assert.AreEqual(1, scheduler.QueueSize);
            scheduler.RunNext();
            Assert.IsTrue(statsA.NextCalled);
            Assert.IsFalse(statsA.CompletedCalled);

            Assert.AreEqual(1, scheduler.QueueSize);
            scheduler.RunNext();
            Assert.IsTrue(statsA.CompletedCalled);
        }

        [Test]
        public void each_subscriber_is_scheduled_individually()
        {
            ManualScheduler scheduler = new ManualScheduler();

            AsyncSubject<int> subject = new AsyncSubject<int>(scheduler);

            StatsObserver<int> statsA = new StatsObserver<int>();
            StatsObserver<int> statsB = new StatsObserver<int>();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            subject.Subscribe(statsA);
            subject.Subscribe(statsB);


            scheduler.RunNext();

            Assert.IsTrue(statsA.NextCalled);
            Assert.IsFalse(statsB.NextCalled);

            scheduler.RunNext();

            Assert.IsTrue(statsB.NextCalled);
        }
    }
}
