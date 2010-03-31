using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace RxAs.Rx2.ProofTests.Mock
{
    public class StatsObserver<T> : IObserver<T>
	{
		private int _nextCount = 0;
		private int _errorCount = 0;
		private int _completedCount = 0;
		
		private List<T> _nextValues = new List<T>();
		private Exception _error = null;
		
		public StatsObserver()
		{
		}

		public void OnCompleted()
		{
			_completedCount++;
		}
		
		public void OnError(Exception exception)
		{
			_error = exception;
			_errorCount++;
		}
		
		public void OnNext(T value)
		{
			_nextValues.Add(value);
			
			_nextCount++;
		}
		

		public int NextCount { get { return _nextCount; } }
		public int ErrorCount { get { return _errorCount; } }
		public int CompletedCount { get { return _completedCount; } }
		
		public bool NextCalled { get { return _nextCount > 0; } }
		public bool ErrorCalled { get { return _errorCount > 0; } }
		public bool CompletedCalled { get { return _completedCount > 0; } }
		
		public ICollection<T> NextValues { get { return _nextValues; } }

        public Exception Error { get { return _error; } }
	}
}
