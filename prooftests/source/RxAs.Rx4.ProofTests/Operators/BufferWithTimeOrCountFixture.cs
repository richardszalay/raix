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
    public class BufferWithTimeOrCountFixture
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
        public void values_can_be_triggered_by_time_or_count()
        {
            var scheduler = new TestScheduler();
			
			var source = scheduler.CreateColdObservable(
                // start #1 (@0)
				new Recorded<Notification<int>>(10, OnNext(1)),
				new Recorded<Notification<int>>(12, OnNext(2)),
                new Recorded<Notification<int>>(14, OnNext(3)),
                // start #2 (@ 15)
				new Recorded<Notification<int>>(16, OnNext(4)),
                new Recorded<Notification<int>>(20, OnNext(5)),
                new Recorded<Notification<int>>(24, OnNext(6)),
                new Recorded<Notification<int>>(28, OnNext(7)),
                // start #3 (@ 28)
                // start #4 (@ 43)
				new Recorded<Notification<int>>(50, OnNext(8)),
				new Recorded<Notification<int>>(51, OnCompleted())
			);
			
			var stats = new StatsObserver<IList<int>>();

			source.BufferWithTimeOrCount(new TimeSpan(15), 4, scheduler)
				.Subscribe(stats);
			
			scheduler.Run();
			
			Assert.AreEqual(4, stats.NextCount);
            Assert.AreEqual(3, stats.NextValues[0].Count);
            Assert.AreEqual(4, stats.NextValues[1].Count);
            Assert.AreEqual(0, stats.NextValues[2].Count);
            Assert.AreEqual(1, stats.NextValues[3].Count);
        }
    }
}
