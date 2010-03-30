package rx.tests.mocks
{
	import rx.IObserver;

	public class StatsObserver implements IObserver
	{
		private var _nextCount : int = 0;
		private var _errorCount : int = 0;
		private var _completedCount : int = 0;
		
		private var _nextValues : Array = new Array();
		private var _error : Error = null;
		
		public function StatsObserver()
		{
		}

		public function onCompleted():void
		{
			_completedCount++;
		}
		
		public function onError(error:Error):void
		{
			_error = error;
			_errorCount++;
		}
		
		public function onNext(value:Object):void
		{
			_nextValues.push(value);
			
			_nextCount++;
		}
		
		public function get nextCount() { return _nextCount; }
		public function get errorCount() { return _errorCount; }
		public function get completedCount() { return _completedCount; }
		
		public function get nextCalled() { return _nextCount > 0; }
		public function get errorCalled() { return _errorCount > 0; }
		public function get completedCalled() { return _completedCount > 0; }
		
		public function get nextValues() : Array { return _nextValues; }
		
		public function get error() : Error { return _error; }
	}
}