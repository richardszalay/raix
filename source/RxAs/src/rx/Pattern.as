package rx
{
	public class Pattern
	{
		private var _sources : Array;
		
		public function Pattern(sources : Array)
		{
			_sources = sources;
		}
		
		public function and(source : IObservable) : Pattern
		{
			return new Pattern(_sources.concat(source));
		}
		
		public function then(type : Class, thenFunction : Function) : Plan
		{
			return new Plan(type, _sources, thenFunction); 
		}
	}
}