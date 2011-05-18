package raix.interactive
{
	internal class Grouping extends AbsEnumerable implements IGrouping
	{
		private var _key : Object;
		private var _elements : IEnumerable;
		
		public function Grouping(key : Object, elements : IEnumerable)
		{
			_key = key;
			_elements = elements;
		}
		
		public override function getEnumerator():IEnumerator
		{
			return _elements.getEnumerator();
		}
		
		public function get key() : Object { return _key; }
	}
}