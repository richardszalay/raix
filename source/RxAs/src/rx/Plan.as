package rx
{
	public class Plan
	{
		private var _type : Class;
		private var _selector : Function;
		private var _sources : Array;
		
		public function Plan(type : Class, sources : Array, selector : Function)
		{
			_type = type;
			_sources = sources;
			_selector = selector;
		}
		
		public function get sources() : Array
		{
			return new Array().concat(_sources);
		}
		
		public function get selector() : Function { return _selector; }
	}
}