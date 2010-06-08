using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Disposables;
using System.Threading;

namespace RxAs.Rx4.ProofTests.Mock
{
    public class StatsSubject<T> : ISubject<T>
    {
        private int totalSubscriptionCount;
        private int subscriptionCount;

        private Subject<T> innerSubject;

        public StatsSubject()
        {
            innerSubject = new Subject<T>();
        }

        public int SubscriptionCount
        {
            get { return subscriptionCount; }
        }

        public int TotalSubscriptionCount
        {
            get { return totalSubscriptionCount; }
        }

        public bool HasSubscriptions
        {
            get { return subscriptionCount > 0; }
        }

        public void OnCompleted()
        {
            innerSubject.OnCompleted();
        }

        public void OnError(Exception exception)
        {
            innerSubject.OnError(exception);
        }

        public void OnNext(T value)
        {
            innerSubject.OnNext(value);
        }

        public IDisposable Subscribe(IObserver<T> observer)
        {
            Interlocked.Increment(ref subscriptionCount);
            Interlocked.Increment(ref totalSubscriptionCount);

            IDisposable disposable = innerSubject.Subscribe(observer);

            return Disposable.Create(() =>
                 {
                     disposable.Dispose();

                     Interlocked.Decrement(ref subscriptionCount);
                 });
        }
    }
}
