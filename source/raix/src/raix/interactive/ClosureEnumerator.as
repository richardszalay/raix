package raix.interactive
{
	internal class ClosureEnumerator implements IEnumerator
	{
		private var _moveNextFunc : Function;
		private var _currentFunc : Function;
		
		public function ClosureEnumerator(moveNextFunc : Function, currentFunc : Function)
		{
			_moveNextFunc = moveNextFunc;
			_currentFunc = currentFunc;
		}

		public function get current():Object
		{
			return _currentFunc();
		}
		
		public function moveNext():Boolean
		{
			return _moveNextFunc();
		}
	}
}