using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Disposables;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class RepeatFixture
    {
        [Test]
        public void repeats_specified_number_of_times()
        {
            var stats = new StatsObserver<int>();

            Observable.Range(0, 2).Repeat(2).Subscribe(stats);

            Assert.AreEqual(4, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0]);
            Assert.AreEqual(1, stats.NextValues[1]);
            Assert.AreEqual(0, stats.NextValues[2]);
            Assert.AreEqual(1, stats.NextValues[3]);
        }

        [Test]
        public void resubscribes_after_completion()
        {
            int subscribeCount = 0;

            var source = Observable.Create<int>(obs =>
                {
                    subscribeCount++;

                    obs.OnCompleted();

                    return () => { };
                });

            var stats = new StatsObserver<int>();
            source.Repeat(2).Subscribe(stats);

            Assert.AreEqual(2, subscribeCount);
        }

        [Test]
        public void errors_stop_repeats()
        {
            int subscribeCount = 0;

            var source = Observable.Create<int>(obs =>
            {
                subscribeCount++;

                obs.OnError(new Exception());

                return () => { };
            });

            var stats = new StatsObserver<int>();
            source.Repeat(2).Subscribe(stats);

            Assert.AreEqual(1, subscribeCount);
            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void repeat_with_no_arguments_repeats_forever()
        {
            int subscribeCount = 0;

            var source = Observable.Create<int>(obs =>
            {
                if (subscribeCount < 200)
                {
                    obs.OnNext(subscribeCount++);
                    obs.OnCompleted();
                }

                return () => { };
            });

            var stats = new StatsObserver<int>();
            source.Repeat().Subscribe(stats);

            Assert.AreEqual(200, subscribeCount);
            Assert.IsFalse(stats.CompletedCalled);
        }
    }
}
