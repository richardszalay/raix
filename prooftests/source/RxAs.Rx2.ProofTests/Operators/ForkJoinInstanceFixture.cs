using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class ForkJoinInstanceFixture
    {
        private Func<int, int, string> selector = (x, y) => String.Concat(x.ToString(), ",", y.ToString());

        [Test]
        public void no_values_are_emitted_if_one_source_is_empty()
        {
            var stats = new StatsObserver<String>();

            Observable.Empty<int>().ForkJoin(Observable.Return(1), selector)
                    .Subscribe(stats);

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void value_array_is_emitted_if_both_sources_have_one_value()
        {
            var stats = new StatsObserver<String>();

            Observable.Return(1).ForkJoin(Observable.Return(2), selector)
                    .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual("1,2", stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void first_values_are_emitted_if_both_sources_have_multiple_values()
        {
            var stats = new StatsObserver<String>();

            Observable.Range(0, 2).ForkJoin(Observable.Range(2, 2), selector)
                    .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual("0,2", stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void values_are_emitted_after_all_are_available()
        {
            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();

            var stats = new StatsObserver<String>();

            subjectA.ForkJoin(subjectB, selector)
                    .Subscribe(stats);

            subjectA.OnNext(0);
            subjectB.OnNext(1);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual("0,1", stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void sequence_completes_when_all_values_are_available()
        {
            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();

            var stats = new StatsObserver<String>();

            subjectA.ForkJoin(subjectB, selector)
                    .Subscribe(stats);

            subjectA.OnNext(0);
            Assert.IsFalse(stats.CompletedCalled);

            subjectB.OnNext(1);
            Assert.IsTrue(stats.CompletedCalled);
        }
    }
}
