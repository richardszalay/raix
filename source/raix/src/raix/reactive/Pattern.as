package raix.reactive
{
	/**
	 * A combination of multiple IObservable sequences that can be combined 
	 * into a Plan
	 * 
	 * <p>Generally, a Pattern will be created using IObservable.and or 
	 * Pattern.and(), rather than creating a Pattern directly</p>
	 */	
	public class Pattern
	{
		private var _sources : Array;
	
		public function Pattern(sources : Array)
		{
			_sources = sources;
		}
		
		/**
		 * Creates another pattern that combines the IObservable sequences 
		 * of this Pattern with another IObservable sequence 
		 * @param source The IObservable sequence to add
		 * @return A Pattern with the new set of sequences
		 * 
		 */		
		public function and(source : IObservable) : Pattern
		{
			return new Pattern(_sources.concat(source));
		}
		
		/**
		 * Creates a Plan from this Pattern, by supplying a 
		 * valueClass and a mappingFunction for the values from each 
		 * sequence in this Pattern 
		 * @param valueClass The valueClass that will be returned by thenFunction
		 * @param thenFunction The function that will accept one argument for each 
		 * sequence in the pattern and output a valueClass
		 * @return A Plan that can be used with Observable.when
		 */		
		public function then(thenFunction : Function) : Plan
		{
			return new Plan(_sources, thenFunction); 
		}
	}
}