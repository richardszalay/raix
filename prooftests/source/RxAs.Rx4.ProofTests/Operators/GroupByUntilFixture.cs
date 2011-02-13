using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class GroupByUntilFixture
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
        public void groups_are_recreated_after_duration_ends()
        {
            var groupKeys = new List<int>();

            source.ToObservable().GroupByUntil(x => x.Key, x => x.Value, g => Observable.Empty<int>())
                .Subscribe(group =>
                {
                    groupKeys.Add(group.Key);
                });

            Assert.AreEqual(6, groupKeys.Count);
        }

        [Test]
        public void group_duration_can_be_completed_by_a_value()
        {
            var groupKeys = new List<int>();

            source.ToObservable().GroupByUntil(x => x.Key, x => x.Value, g => Observable.Return<int>(1).Concat(Observable.Never<int>()))
                .Subscribe(group =>
                {
                    groupKeys.Add(group.Key);
                });

            Assert.AreEqual(6, groupKeys.Count);
        }

        [Test]
        public void durations_are_unsubscribed_from_oncompleted()
        {
            var groupStats = new StatsObserver<IGroupedObservable<int, int>>();

            var durationSubjects = new List<StatsSubject<int>>();

            source.ToObservable().GroupByUntil(x => x.Key, x => x.Value, g =>
                {
                    var duration = new StatsSubject<int>(); 
                    durationSubjects.Add(duration); 
                    return duration;
                })
                .Subscribe(groupStats);

            Assert.AreEqual(
                durationSubjects.Select(_ => false).ToArray(),
                durationSubjects.Select(s => s.HasSubscriptions).ToArray()
                );
        }

        [Test]
        public void durations_are_unsubscribed_from_onerror()
        {
            var groupStats = new StatsObserver<IGroupedObservable<int, int>>();

            var durationSubjects = new List<StatsSubject<int>>();

            source.ToObservable().Concat(Observable.Throw<GroupableObject>(new Exception())).GroupByUntil(x => x.Key, x => x.Value, g =>
            {
                var duration = new StatsSubject<int>();
                durationSubjects.Add(duration);
                return duration;
            })
                .Subscribe(groupStats);

            Assert.AreEqual(
                durationSubjects.Select(_ => false).ToArray(),
                durationSubjects.Select(s => s.HasSubscriptions).ToArray()
                );
        }

        [Test]
        public void groups_are_created_for_each_key()
        {
            var dictionary = new Dictionary<int,List<int>>();

            source.ToObservable().GroupByUntil(x => x.Key, x => x.Value, g => Observable.Never<int>())
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

            source.ToObservable().GroupByUntil(x => { throw new Exception(); return x.Key; }, x => x.Value, g => Observable.Never<int>())
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void error_thrown_by_elementselector_sent_to_onerror()
        {
            var stats = new StatsObserver<IGroupedObservable<int, int>>();

            source.ToObservable().GroupByUntil(x => x.Key, x => { throw new Exception(); return x.Key; }, g => Observable.Never<int>())
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void error_thrown_by_keycomparer_sent_to_onerror()
        {
            var stats = new StatsObserver<IGroupedObservable<int, int>>();

            source.ToObservable().GroupByUntil(x => x.Key, x => x.Value, g => Observable.Never<int>(), 
                new AnonymousComparer<int>((x,y) => { throw new Exception(); }))
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
        }

        [Test]
        public void errors_are_emitted_into_each_group()
        {
            bool outsideError = false;
            StatsObserver<int> groupStats = new StatsObserver<int>();

            Observable.Return(1).Concat(Observable.Throw<int>(new Exception()))
                .GroupByUntil(x => x, g => Observable.Never<int>())
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
