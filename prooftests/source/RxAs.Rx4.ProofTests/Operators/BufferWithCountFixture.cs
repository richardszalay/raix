using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class BufferWithCountFixture
    {
        [Test]
		public void values_are_buffered_in_specified_groups()
		{
			var manObs = Observable.Range(0, 6);
			
			var obs = manObs.BufferWithCount(3);
			
			var expectedValues = new Queue<int[]>(new int[][]
                {
                    new int[] { 0, 1, 2 },
                    new int[] { 3, 4, 5 }
                });
				
			TestBufferResults(obs, expectedValues);
		}
		
		[Test]
		public void skip_value_is_honoured_when_less_than_count()
		{
			var obs = Observable.Range(0, 4).BufferWithCount(2, 1);
			
			var expectedValues = new Queue<int[]>(new int[][]
                {
                    new int[] { 0, 1 },
                    new int[] { 1, 2 },
                    new int[] { 2, 3 },
                    new int[] { 3 }
                });
				
			TestBufferResults(obs, expectedValues);
		}
		
		[Test]
		public void skip_value_is_honoured_when_equal_to_count()
		{
            var obs = Observable.Range(0, 4).BufferWithCount(2, 2);

			var expectedValues = new Queue<int[]>(new int[][]
                {
                    new int[] { 0, 1 },
                    new int[] { 2, 3 }
                });
				
			TestBufferResults(obs, expectedValues);
		}
		
		[Test]
		public void skip_value_is_honoured_when_greater_than_count()
		{
			var obs = Observable.Range(0, 4).BufferWithCount(2, 3);

			var expectedValues = new Queue<int[]>(new int[][]
                {
                    new int[] { 0, 1 },
                    new int[] { 3 }
                });
				
			TestBufferResults(obs, expectedValues);
		}
		
		[Test]
		public void remaining_items_are_released_on_completed()
		{
			var obs = Observable.Range(0, 3).BufferWithCount(2);

			var expectedValues = new Queue<int[]>(new int[][]
                {
                    new int[] { 0, 1 },
                    new int[] { 2 }
                });
				
			TestBufferResults(obs, expectedValues);
		}
		
		[Test]
		public void remaining_items_are_released_on_error()
		{
			var obs = Observable.Range(0, 4)
                .Take(3)
                .Concat<int>(Observable.Throw<int>(new Exception()))
                .BufferWithCount(2);

			var expectedValues = new Queue<int[]>(new int[][]
                {
                    new int[] { 0, 1 },
                    new int[] { 2 }
                });

            TestBufferResults(obs, expectedValues);
		}

        private void TestBufferResults<T>(IObservable<IList<T>> obs, Queue<T[]> expectedValues)
		{
			var nextCount = 0;
			
			var expectedValueCount = expectedValues.Count;
			
			obs.Subscribe(
                pl => 
                    {
                        nextCount++;

                        T[] expectedArr = expectedValues.Dequeue();

                        Assert.AreEqual(pl.Count, expectedArr.Length);

                        for (int i=0; i<expectedArr.Length; i++)
                        {
                            Assert.AreEqual(expectedArr[i], pl[i]);
                        }
                    },
                ex =>
                    {
                        Assert.AreEqual(expectedValueCount, nextCount, "incorrect number of values");
                    },
                () =>
                    {
                        Assert.AreEqual(expectedValueCount, nextCount, "incorrect number of values");
                    }
                );
		}
    }
}
