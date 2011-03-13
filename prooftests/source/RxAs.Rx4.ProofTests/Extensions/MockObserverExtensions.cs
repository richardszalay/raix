using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Reactive.Testing.Mocks;

namespace RxAs.Rx4.ProofTests.Extensions
{
    public static class MockObserverExtensions
    {
        public static bool IsCompleted<T>(this MockObserver<T> source)
        {
            if (source.Count == 0)
            {
                return false;
            }

            return source.Last().Value is
                Notification<T>.OnCompleted;
        }

        public static T GetValue<T>(this MockObserver<T> source, int index)
        {
            if (index > source.Count - 1 ||
                !(source[index].Value is Notification<T>.OnNext))
            {
                throw new ArgumentOutOfRangeException("index");
            }

            var next = (Notification<T>.OnNext)source[index].Value;

            return next.Value;
        }
    }
}
