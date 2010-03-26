using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace RxAs.Rx2.ProofTests.Mock
{
    public class ClosureDisposable : IDisposable
    {
        private Action disposeFunc;

        public ClosureDisposable(Action disposeFunc)
        {
            this.disposeFunc = disposeFunc;
        }

        public void Dispose()
        {
            disposeFunc();
        }
    }
}
