package raix.reactive
{
	/**
	 * A combination of IObservable sequences and a selector that will 
	 * map the values of those sequences to an output value. A plan is intended 
	 * to be used with Observable.join
	 * 
	 * <p>Generally, a Plan will be created using Pattern.then(), rather 
	 * than creating a Plan directly</p>
	 */
	public class Plan
	{
		private var _selector : Function;
		private var _sources : Array;
		
		public function Plan(sources : Array, selector : Function)
		{
			_sources = sources;
			_selector = selector;
		}
		
		/**
		 * Gets the observable sequences in this plan
		 */		
		public function get sources() : Array
		{
			return _sources.slice();
		}
		
		/**
		 * Gets the function selector that will accept one argument for each 
		 * sequence in sources and return the output value
		 */		
		public function get selector() : Function { return _selector; }
	}
}