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
        public void values_are_buffered_in_specified_time()
        {
            var scheduler = new TestScheduler();
			
			var source = scheduler.CreateColdObservable(
                                                                // start #1 (@0)
				new Recorded<Notification<int>>(10, OnNext(1)),
				new Recorded<Notification<int>>(12, OnNext(2)),
                                                                // start #2 (@ 15)
                                                                // start #3 (@ 30)
				new Recorded<Notification<int>>(40, OnNext(3)),
                                                                // start #4 (@ 45)
				new Recorded<Notification<int>>(50, OnNext(4)),
				new Recorded<Notification<int>>(51, OnCompleted())
			);
			
			var stats = new StatsObserver<IList<int>>();

			source.BufferWithTime(new TimeSpan(15), scheduler)
				.Subscribe(stats);
			
			scheduler.Run();
			
			Assert.AreEqual(4, stats.NextCount);
            Assert.AreEqual(2, stats.NextValues[0].Count);
            Assert.AreEqual(0, stats.NextValues[1].Count);
            Assert.AreEqual(1, stats.NextValues[2].Count);
            Assert.AreEqual(1, stats.NextValues[3].Count);
        }

        [Test]
        public void time_shifted_values_make_it_into_the_next_window()
        {
            var scheduler = new TestScheduler();

            var source = scheduler.CreateColdObservable(
                // start #1 (@0)
                // start #2 (@10) <-- happens before subscribe so its before the first value
                new Recorded<Notification<int>>(10, OnNext(1)),
                new Recorded<Notification<int>>(12, OnNext(2)),
                // end #1 (@15)
                // start #3 (@20)
                // end #2 (@25)
                // start #4 (@30)
                // end #3 (@35)
                new Recorded<Notification<int>>(40, OnNext(3)),
                // start #5 (@40)
                // end #4 (@45)
                new Recorded<Notification<int>>(50, OnNext(4)),
                // start #6 (@50)
                new Recorded<Notification<int>>(51, OnCompleted())
            );

            var stats = new StatsObserver<IList<int>>();

            source.BufferWithTime(new TimeSpan(15), new TimeSpan(4), scheduler)
                .Subscribe(stats);

            scheduler.Run();

            Assert.AreEqual(6, stats.NextCount);
			Assert.AreEqual(2, stats.NextValues[0].Count);
			Assert.AreEqual(2, stats.NextValues[1].Count);
			Assert.AreEqual(0, stats.NextValues[2].Count);
			Assert.AreEqual(1, stats.NextValues[3].Count);
			Assert.AreEqual(1, stats.NextValues[4].Count);
			Assert.AreEqual(0, stats.NextValues[5].Count);
			
			Assert.IsTrue(stats.NextValues[0].SequenceEqual(new int[] { 1, 2 }));
			Assert.IsTrue(stats.NextValues[1].SequenceEqual(new int[] { 1, 2 }));
			Assert.IsTrue(stats.NextValues[3].SequenceEqual(new int[] { 3 }));
            Assert.IsTrue(stats.NextValues[4].SequenceEqual(new int[] { 4 }));
        }

        
    }
}
