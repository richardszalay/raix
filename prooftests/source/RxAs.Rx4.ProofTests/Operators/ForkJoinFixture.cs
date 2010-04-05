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
        [Test]
		public void uses_first_value_from_each_and_completes()
		{
            var stats = new StatsObserver<int[]>();

            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();
            var subjectC = new Subject<int>();

            Observable.ForkJoin(subjectA, subjectB, subjectC)
                .Subscribe(stats);

            subjectA.OnNext(0); // first A
            Assert.AreEqual(0, stats.NextCount);

            subjectB.OnNext(1); // first B
            Assert.AreEqual(0, stats.NextCount);

            subjectB.OnNext(2);
            Assert.AreEqual(0, stats.NextCount);

            subjectA.OnNext(3);
            Assert.AreEqual(0, stats.NextCount);

            subjectC.OnNext(4); // first C
            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0][0]);
            Assert.AreEqual(1, stats.NextValues[0][1]);
            Assert.AreEqual(4, stats.NextValues[0][2]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void order_of_values_matches_observers()
        {
            var stats = new StatsObserver<int[]>();

            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();
            var subjectC = new Subject<int>();

            Observable.ForkJoin(subjectA, subjectB, subjectC)
                .Subscribe(stats);

            subjectC.OnNext(4); // first C
            subjectB.OnNext(1); // first B
            subjectA.OnNext(0); // first A
            
            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0][0]);
            Assert.AreEqual(1, stats.NextValues[0][1]);
            Assert.AreEqual(4, stats.NextValues[0][2]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void completes_with_no_value_when_child_sequence_completes_with_no_value()
        {
            var stats = new StatsObserver<int[]>();

            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();
            var subjectC = new Subject<int>();

            Observable.ForkJoin(subjectA, subjectB, subjectC)
                .Subscribe(stats);

            subjectA.OnCompleted();
            subjectB.OnNext(0);
            subjectC.OnNext(1);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsTrue(stats.CompletedCalled);
        }
    }
}
