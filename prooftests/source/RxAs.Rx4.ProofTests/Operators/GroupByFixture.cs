using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class GroupByFixture
    {
        GroupableObject[] source = new GroupableObject[]
            {
                new GroupableObject { Key = 0, Value = 1 },
                new GroupableObject { Key = 1, Value = 2 },
                new GroupableObject { Key = 2, Value = 3 },
                new GroupableObject { Key = 0, Value = 4 },
                new GroupableObject { Key = 1, Value = 5 },
                new GroupableObject { Key = 2, Value = 6 }
            };

        [Test]
        public void groups_are_created_for_each_key()
        {
            var dictionary = new Dictionary<int,List<int>>();

            source.ToObservable().GroupBy(x => x.Key, x => x.Value)
                .Subscribe(group =>
                    {
                        dictionary[group.Key] = new List<int>();

                        group.Subscribe(value => dictionary[group.Key].Add(value));
                    });

            Assert.AreEqual(3, dictionary.Keys.Count);
            Assert.AreEqual(new int[] { 0, 1, 2 }, dictionary.Keys);
            Assert.AreEqual(new int[] { 1, 4 }, dictionary[0]);
            Assert.AreEqual(new int[] { 2, 5 }, dictionary[1]);
            Assert.AreEqual(new int[] { 3, 6 }, dictionary[2]);
        }

        [Test]
        public void error_thrown_by_keyselector_sent_to_onerror()
        {
            var stats = new StatsObserver<IGroupedObservable<int, int>>();

            source.ToObservable().GroupBy(x => { throw new Exception(); return x.Key; }, x => x.Value)
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void error_thrown_by_elementselector_sent_to_onerror()
        {
            var stats = new StatsObserver<IGroupedObservable<int, int>>();

            source.ToObservable().GroupBy(x => x.Key, x => { throw new Exception(); return x.Key; })
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void error_thrown_by_keycomparer_sent_to_onerror()
        {
            var stats = new StatsObserver<IGroupedObservable<int, int>>();

            source.ToObservable().GroupBy(x => x.Key, x => x.Value, new AnonymousComparer<int>((x,y) => { throw new Exception(); }))
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void errors_are_emitted_into_each_group()
        {
            bool outsideError = false;
            StatsObserver<int> groupStats = new StatsObserver<int>();

            Observable.Return(1).Concat(Observable.Throw<int>(new Exception()))
                .GroupBy(x => x)
                .Subscribe(group =>
                    {
                        group.Subscribe(groupStats);
                    },
                    ex => outsideError = true);

            Assert.IsTrue(outsideError);
            Assert.IsTrue(groupStats.ErrorCalled);
        }

        private class GroupableObject
        {
            public int Key { get; set; }

            public int Value { get; set; }
        }

        private class AnonymousComparer<T> : IEqualityComparer<T>
        {
            private readonly Func<T, T, bool> comparer;

            public AnonymousComparer(Func<T, T, bool> comparer)
            {
                this.comparer = comparer;
            }

            public bool Equals(T x, T y)
            {
                return comparer(x, y);
            }

            public int GetHashCode(T obj)
            {
                return 0;
            }
        }
    }
}
