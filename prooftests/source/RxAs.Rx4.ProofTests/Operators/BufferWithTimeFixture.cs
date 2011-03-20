using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Threading;
using System.Concurrency;
using System.Diagnostics;
using System.Reactive.Testing;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class BufferWithTimeFixture
    {
        private Notification<int> OnNext(int value)
        {
            return new Notification<int>.OnNext(value);
        }

        private Notification<int> OnCompleted()
        {
            return new Notification<int>.OnCompleted();
        }

        [Test]
        public void using_test_scheduler()
        {
            var scheduler = new TestScheduler();
			
			var source = scheduler.CreateColdObservable(
				new Recorded<Notification<int>>(0, OnNext(1)),
				new Recorded<Notification<int>>(10, OnNext(2)),
				new Recorded<Notification<int>>(20, OnNext(3)),
				new Recorded<Notification<int>>(30, OnNext(4)),
				new Recorded<Notification<int>>(31, OnCompleted())
			);
			
			var stats = new StatsObserver<IList<int>>();
			
			source.BufferWithTime(new TimeSpan(15), scheduler)
				.Subscribe(stats);
			
			scheduler.Run();
			
			Assert.AreEqual(3, stats.NextCount);
            Assert.AreEqual(2, stats.NextValues[0].Count);
            Assert.AreEqual(2, stats.NextValues[1].Count);
            Assert.AreEqual(0, stats.NextValues[2].Count);
        }

        [Test]
        public void empty_buffers()
        {
            var scheduler = new TestScheduler();

            var source = scheduler.CreateColdObservable(
                new Recorded<Notification<int>>(0, OnNext(1)),
                new Recorded<Notification<int>>(10, OnNext(2)),
                new Recorded<Notification<int>>(40, OnNext(3)),
                new Recorded<Notification<int>>(50, OnNext(4)),
                new Recorded<Notification<int>>(51, OnCompleted())
            );

            var stats = new StatsObserver<IList<int>>();

            source.BufferWithTime(new TimeSpan(15), scheduler)
                .Subscribe(stats);

            scheduler.Run();

            Assert.AreEqual(3, stats.NextCount);
            Assert.AreEqual(2, stats.NextValues[0].Count);
            Assert.AreEqual(2, stats.NextValues[1].Count);
            Assert.AreEqual(0, stats.NextValues[2].Count);
        }

        [Test]
        public void empty_list()
        {
            var stats = new StatsObserver<IList<int>>();

            TestScheduler scheduler = new TestScheduler();

            var manObs = Observable.Never<int>()
                .BufferWithTime(TimeSpan.FromMilliseconds(1), scheduler)
                .Take(1)
                .Subscribe(stats);

            scheduler.Run();

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0].Count);
        }

        [Test]
        public void values_are_released_on_completion()
        {
            var stats = new StatsObserver<IList<int>>();

            TestScheduler scheduler = new TestScheduler();

            var manObs = Observable.Range(0, 2)
                .BufferWithTime(TimeSpan.FromMilliseconds(200), scheduler)
                .Subscribe(stats);

            scheduler.Run();

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(2, stats.NextValues[0].Count);
        }

        [Test]
        public void empty_values_are_released_on_completion()
        {
            var stats = new StatsObserver<IList<int>>();

            var scheduler = new TestScheduler();

            var manObs = Observable.Empty<int>()
                .BufferWithTime(TimeSpan.FromMilliseconds(1000), scheduler)
                .Take(1)
                .Subscribe(stats);

            scheduler.Run();

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(0, stats.NextValues[0].Count);
        }

        [Test]
        public void time_offset_excludes_values_of_exact_offset()
        {
            var stats = new StatsObserver<IList<int>>();

            var values = new Subject<int>();
            var bufferScheduler = new TestScheduler();

            var timeSpan = TimeSpan.FromMilliseconds(30);
            var timeShift = TimeSpan.FromMilliseconds(20);

            values
                .BufferWithTime(timeSpan, timeShift, bufferScheduler)
                .Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);

            values.OnNext(0);
            bufferScheduler.RunTo(TimeSpan.FromMilliseconds(10).Ticks);

            values.OnNext(1);
            bufferScheduler.RunTo(TimeSpan.FromMilliseconds(40).Ticks);

            values.OnNext(2);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(2, stats.NextValues[0].Count);
        }

        [Test]
        public void buffer_is_aborted_on_error()
        {
            var stats = new StatsObserver<IList<int>>();

            var bufferScheduler = new ManualScheduler();

            DateTimeOffset startTime = DateTimeOffset.UtcNow;

            Observable.Range(0, 5).Concat(Observable.Throw<int>(new Exception()))
                .BufferWithTime(TimeSpan.FromMilliseconds(30), bufferScheduler)
                .Subscribe(stats);

            bufferScheduler.RunNext();

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreEqual(0, stats.NextCount);
        }

        [Test]
        public void empty_buffer_is_aborted_on_error()
        {
            var stats = new StatsObserver<IList<int>>();

            var bufferScheduler = new ManualScheduler();

            DateTimeOffset startTime = DateTimeOffset.UtcNow;

            Observable.Throw<int>(new Exception())
                .BufferWithTime(TimeSpan.FromMilliseconds(30), bufferScheduler)
                .Subscribe(stats);

            Assert.AreEqual(bufferScheduler.QueueSize, 1);

            bufferScheduler.RunNext();

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreEqual(0, stats.NextCount);
        }

        [Test]
        public void error_is_emitted_through_scheduler()
        {
            var stats = new StatsObserver<IList<int>>();

            var bufferScheduler = new ManualScheduler();

            DateTimeOffset startTime = DateTimeOffset.UtcNow;

            Observable.Range(0, 5).Concat(Observable.Throw<int>(new Exception()))
                .BufferWithTime(TimeSpan.FromMilliseconds(30), bufferScheduler)
                .Subscribe(stats);

            Assert.AreEqual(bufferScheduler.QueueSize, 1);
            Assert.IsFalse(stats.ErrorCalled);

            bufferScheduler.RunNext();

            Assert.IsTrue(stats.ErrorCalled);
        }
    }
}
