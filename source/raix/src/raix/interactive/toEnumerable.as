package raix.interactive
{
	import flash.utils.Proxy;
	
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