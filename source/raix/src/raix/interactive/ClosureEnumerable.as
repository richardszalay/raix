package raix.interactive
{
	import flash.errors.IllegalOperationError;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	internal class ClosureEnumerable extends AbsEnumerable
	{
		private var _createEnumerator : Function;
		
		
		public function ClosureEnumerable(createEnumerator : Function)
		{
			super();
			
			_createEnumerator = createEnumerator;
		}
		
		public override function getEnumerator():IEnumerator
		{
			return _createEnumerator();
		}
	}
}