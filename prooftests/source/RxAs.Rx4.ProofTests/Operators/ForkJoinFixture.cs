using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class ForkJoinFixture
    {
        [Test, Ignore("Bug in current Rx v1.0.2563.0")]
        public void no_values_are_emitted_if_one_source_is_empty()
        {
            var stats = new StatsObserver<int[]>();

            Observable.ForkJoin(
                    Observable.Empty<int>(),
                    Observable.Return(1)
                    )
                    .Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test, Ignore("Bug in current Rx v1.0.2563.0")]
        public void no_values_are_emitted_if_both_sources_are_empty()
        {
            var stats = new StatsObserver<int[]>();

            Observable.ForkJoin(
                    Observable.Empty<int>(),
                    Observable.Empty<int>()
                    )
                    .Subscribe(stats);


            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test, Ignore("Bug in current Rx v1.0.2563.0")]
        public void value_array_is_emitted_if_both_sources_have_one_value()
        {
            var stats = new StatsObserver<int[]>();

            Observable.ForkJoin(
                    Observable.Return(1),
                    Observable.Return(2)
                    )
                    .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(1, stats.NextValues[0][0]);
            Assert.AreEqual(2, stats.NextValues[0][1]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void last_values_are_emitted_if_both_sources_have_multiple_values()
        {
            var stats = new StatsObserver<int[]>();

            Observable.ForkJoin(
                    Observable.Range(0, 2),
                    Observable.Range(2, 2)
                    )
                    .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(1, stats.NextValues[0][0]);
            Assert.AreEqual(3, stats.NextValues[0][1]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void values_are_emitted_after_all_sequences_complete()
        {
            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();

            var stats = new StatsObserver<int[]>();

            Observable.ForkJoin(subjectA, subjectB)
                    .Subscribe(stats);

            subjectA.OnNext(0);
            subjectB.OnNext(1);
            subjectB.OnCompleted();
            Assert.IsFalse(stats.NextCalled);

            subjectA.OnCompleted();
            Assert.IsTrue(stats.NextCalled);

            Assert.AreEqual(0, stats.NextValues[0][0]);
            Assert.AreEqual(1, stats.NextValues[0][1]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void sequence_completes_when_all_sequences_complete()
        {
            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();

            var stats = new StatsObserver<int[]>();

            Observable.ForkJoin(subjectA, subjectB)
                    .Subscribe(stats);

            subjectA.OnNext(0);
            subjectB.OnNext(1);
            subjectB.OnCompleted();
            Assert.IsFalse(stats.CompletedCalled);

            subjectA.OnCompleted();
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void observable_order_is_preserved()
        {
            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();

            var stats = new StatsObserver<int[]>();

            Observable.ForkJoin(subjectA, subjectB)
                    .Subscribe(stats);

            subjectB.OnNext(1);
            subjectB.OnCompleted(); 
            
            subjectA.OnNext(0);
            subjectA.OnCompleted();

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0][0]);
            Assert.AreEqual(1, stats.NextValues[0][1]);
        }
    }
}
