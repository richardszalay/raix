package rx
{
	public class Pattern
	{
		private var _sources : Array;
		private var _types : Array;
		
		public function Pattern(sources : Array)
		{
			_sources = sources;
			
			_types = new Array(_sources.length);
			
			for (var i:int=0; i<_sources.length; i++)
			{
				_types[i] = _sources[i].type;
			}
		}
		
		public function and(source : IObservable) : Pattern
		{
			return new Pattern(_sources.concat(source));
		}
		
		public function then(type : Class, thenFunction : Function) : Plan
		{
			return new Plan(type, _sources, thenFunction); 
		}
		
		public function types() : Array
		{
			return _types.slice();
		}
	}
}