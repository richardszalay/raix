package raix.interactive
{
	import flash.utils.Dictionary;
	
	internal class Lookup extends AbsEnumerable implements ILookup
	{
		private static var _nullKey : Object = {};
		
		private var _hashMap : Dictionary = new Dictionary();
		private var _keys : Array = new Array();
		
		private var _hashSelector : Function;
		
		private var _count : uint = 0;
		
		public function Lookup(hashSelector : Function)
		{
			_hashSelector = hashSelector;
		}
		
		internal function add(key : Object, value : Object) : void
		{
			var hashedKey : Object = getHashedKey(key);
			
			var values : Array = null;
			
			if (_hashMap[hashedKey] === undefined)
			{
				values = new Array();
				
				_hashMap[hashedKey] = values;
				_keys.push(key);
			}
			else
			{
				values = _hashMap[hashedKey] as Array;
			}
			
			values.push(value);
			_count++;
		}
		
		public override function getEnumerator():IEnumerator
		{
			return toEnumerable(_keys)
				.map(function(key:Object):Object
				{
					var hashedKey : Object = getHashedKey(key);
					
					return new Grouping(key, 
						toEnumerable(_hashMap[hashedKey]));
				})
				.getEnumerator();
		}
		
		public function getValues(key : Object) : IEnumerable
		{
			var hashedKey : Object = getHashedKey(key);
			
			if (_hashMap[hashedKey] === undefined)
			{
				return Enumerable.empty();
			}
			
			return toEnumerable(_hashMap[hashedKey]);
		}
		
		public override function count():uint
		{
			return _count;
		}
		
		public function containsKey(key : Object) : Boolean
		{
			return _hashMap[getHashedKey(key)] !== undefined;
		}
		
		private function getHashedKey(key : Object) : Object
		{
			var selectorHashedKey : Object = (_hashSelector != null)
				? _hashSelector(key)
				: key;
				
			return (selectorHashedKey == null)
				? _nullKey
				: selectorHashedKey;
		}

	}
}