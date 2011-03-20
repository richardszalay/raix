package raix.interactive
{
	import flash.utils.Proxy;
	
	/**
	 * Converts a value to an IEnumerable sequence. It can be considered to have the following overloads:
	 * 
	 * <ul>
	 * <li>function():IEnumerable - returns an empty sequence</li>
	 * <li>function(array : Array):IEnumerable - returns a sequence that wraps an array</li>
	 * <li>function(enumerable : IEnumerable):IEnumerable - returns enumerable</li>
	 * <li>function(proxy : Proxy):IEnumerable - returns enumerable that wraps an enumerable Proxy</li>
	 * <li>function(value : *):IEnumerable - returns enumerable that contains a single value</li>
	 * </ul>
	 */
	public function toEnumerable(... args) : IEnumerable
	{
		if (args.length == 0)
		{
			return Enumerable.empty();
		}
		
		if (args[0] is Array)
		{
			return Enumerable.fromArray(args[0]);
		}
		
		if (args[0] is IEnumerable)
		{
			return args[0] as IEnumerable;
		}
		
		if (args[0] is Proxy)
		{
			return Enumerable.fromProxy(args[0]);
		}
		
		return Enumerable.value(args[0]);
	}
}