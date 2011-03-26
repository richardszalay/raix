package raix.reactive
{
	import raix.interactive.IEnumerable;
	
	/**
	 * Converts a value to an IObservable sequence. It can be considered to have the following overloads:
	 * 
	 * <ul>
	 * <li>function():IObservable - returns an empty sequence</li>
	 * <li>function(array : Array):Observable - returns a sequence that wraps an array</li>
	 * <li>function(observable : IObservable):IObservable - returns observable</li>
	 * <li>function(enumerable : IEnumerable):IObservable - returns a sequence that wraps eumerable</li>
	 * <li>function(error : Error):IObservable - returns a sequence will error when subscribed to</li>
	 * <li>function(value : *):IEnumerable - returns enumerable that contains a single value</li>
	 * </ul>
	 */
	public function toObservable(... args) : IObservable
	{
		if (args.length == 0)
		{
			return Observable.empty();
		}
		
		if (args[0] is Array)
		{
			return Observable.fromArray(args[0]);
		}
		
		if (args[0] is IEnumerable)
		{
			return (args[0] as IEnumerable).toObservable();
		}
		
		if (args[0] is IObservable)
		{
			return args[0] as IObservable;
		}
		
		if (args[0] is Error)
		{
			return Observable.error(args[0] as Error);
		}
		
		return Observable.value(args[0]);
	}
}