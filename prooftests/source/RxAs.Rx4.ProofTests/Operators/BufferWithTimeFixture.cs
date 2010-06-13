using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Threading;
using System.Concurrency;
using System.Diagnostics;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class BufferWithTimeFixture
    {
        [Test]
        public void zero_length_list_is_emitted_when_no_values_are_available()
        {
            var stats = new StatsObserver<IList<int>>();

            var scheduler = new ManualScheduler();

            var manObs = Observable.Never<int>()
                .BufferWithTime(TimeSpan.FromMilliseconds(1), scheduler)
                .Take(1)
                .Subscribe(stats);

            scheduler.RunNext();

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0].Count);
        }

        [Test]
        public void values_are_released_on_completion()
        {
            var stats = new StatsObserver<IList<int>>();

            var manObs = Observable.Range(0, 2)
                .BufferWithTime(TimeSpan.FromMilliseconds(200), new ManualScheduler())
                .Take(1)
                .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(2, stats.NextValues[0].Count);
        }

        [Test]
        public void empty_values_are_released_on_completion()
        {
            var stats = new StatsObserver<IList<int>>();

            var manObs = Observable.Empty<int>()
                .BufferWithTime(TimeSpan.FromMilliseconds(1000), new ManualScheduler())
                .Take(1)
                .Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0].Count);
        }

        [Test]
        public void time_offset_excludes_values_of_exact_offset()
        {
            var stats = new StatsObserver<IList<int>>();

            var valueScheduler = new ManualScheduler();
            var bufferScheduler = new ManualScheduler();

            DateTimeOffset startTime = DateTimeOffset.UtcNow;

            Observable.Range(0, 5, valueScheduler)
                .BufferWithTime(TimeSpan.FromMilliseconds(30), TimeSpan.FromMilliseconds(20), bufferScheduler)
                .Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);

            bufferScheduler.Now = startTime.AddMilliseconds(10);
            valueScheduler.RunNext();

            bufferScheduler.Now = startTime.AddMilliseconds(20); // exact offset value
            valueScheduler.RunNext();

            bufferScheduler.Now = startTime.AddMilliseconds(30);
            valueScheduler.RunNext();

            bufferScheduler.RunNext();
            bufferScheduler.RunNext();

            Assert.AreEqual(2, stats.NextCount);
            Assert.AreEqual(1, stats.NextValues[1].Count);
        }

        [Test]
        public void buffer_is_abortrd_on_error()
        {
            var stats = new StatsObserver<IList<int>>();

            var bufferScheduler = new ManualScheduler();

            DateTimeOffset startTime = DateTimeOffset.UtcNow;

            Observable.Range(0, 5).Concat(Observable.Throw<int>(new Exception()))
                .BufferWithTime(TimeSpan.FromMilliseconds(30), bufferScheduler)
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreEqual(0, stats.NextCount);
            //Assert.AreEqual(5, stats.NextValues[0].Count);
        }

        [Test]
        public void empty_buffer_is_aborted_on_error()
        {
            var stats = new StatsObserver<IList<int>>();

            var bufferScheduler = new ManualScheduler();

            DateTimeOffset startTime = DateTimeOffset.UtcNow;

            Observable.Empty<int>().Concat(Observable.Throw<int>(new Exception()))
                .BufferWithTime(TimeSpan.FromMilliseconds(30), bufferScheduler)
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreEqual(0, stats.NextCount);
            //Assert.AreEqual(0, stats.NextValues[0].Count);
        }
    }
}
