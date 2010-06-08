using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class CombineLatestFixture
    {
        [Test]
        public void subscribes_to_both_sources()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a,b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            Assert.AreEqual(1, subjectA.SubscriptionCount);
            Assert.AreEqual(1, subjectB.SubscriptionCount);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void emits_combinations_of_the_latest_values()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            subjectA.OnNext(1);
            subjectB.OnNext(2);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual("1,2", stats.NextValues[0]);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void reuses_values()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            subjectA.OnNext(1);
            subjectB.OnNext(2);
            subjectA.OnNext(3);
            subjectB.OnNext(4);

            Assert.AreEqual(3, stats.NextCount);
            Assert.AreEqual("1,2", stats.NextValues[0]);
            Assert.AreEqual("3,2", stats.NextValues[1]);
            Assert.AreEqual("3,4", stats.NextValues[2]);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void only_uses_latest_value()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            subjectA.OnNext(1);
            subjectA.OnNext(2);
            subjectB.OnNext(3);
            subjectB.OnNext(4);
            subjectA.OnNext(5);
            subjectA.OnNext(6);

            Assert.AreEqual(4, stats.NextCount);
            Assert.AreEqual("2,3", stats.NextValues[0]);
            Assert.AreEqual("2,4", stats.NextValues[1]);
            Assert.AreEqual("5,4", stats.NextValues[2]);
            Assert.AreEqual("6,4", stats.NextValues[3]);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void last_value_is_still_used_after_complete()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            subjectA.OnNext(1);
            subjectA.OnCompleted();

            subjectB.OnNext(2);
            subjectB.OnNext(3);

            Assert.AreEqual(2, stats.NextCount);
            Assert.AreEqual("1,2", stats.NextValues[0]);
            Assert.AreEqual("1,3", stats.NextValues[1]);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void complete_is_fired_when_both_sequences_complete()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            subjectA.OnNext(1);
            subjectA.OnCompleted();

            subjectB.OnNext(2);
            subjectB.OnCompleted();

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual("1,2", stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void error_is_fired_on_error_from_either_source()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            subjectA.OnError(new Exception());

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void unsubscribes_from_both_sequences_when_complete()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            subjectA.OnCompleted();
            subjectB.OnCompleted();

            Assert.AreEqual(0, subjectA.SubscriptionCount);
            Assert.AreEqual(0, subjectB.SubscriptionCount);
        }

        [Test]
        public void unsubscribes_from_both_sequences_on_error()
        {
            StatsSubject<int> subjectA = new StatsSubject<int>();
            StatsSubject<int> subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            subjectA.OnError(new Exception());

            Assert.AreEqual(0, subjectA.SubscriptionCount);
            Assert.AreEqual(0, subjectB.SubscriptionCount);
        }

        [Test]
        public void range()
        {
            var subjectA = Observable.Range(0, 2);
            var subjectB = Observable.Range(2, 4); 

            var stats = new StatsObserver<string>();

            subjectA.CombineLatest(subjectB, (a, b) => String.Concat(a.ToString(), ",", b.ToString()))
                .Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
        }
    }
}
