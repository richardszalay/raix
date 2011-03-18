package raix.interactive
{
	internal class OrderedEnumerable extends AbsEnumerable implements IOrderedEnumerable
	{
		private var _source : IEnumerable;
		private var _compositeSelector : Function;
		private var _compositeComparer : Function;
		
		public function OrderedEnumerable(source : IEnumerable, compositeSelector : Function, compositeComparer : Function)
		{
			this._compositeSelector = compositeSelector;
			this._compositeComparer = compositeComparer;
			this._source = source;
		}
		
		public function thenBy(keySelector : Function, comparer : Function = null) : IOrderedEnumerable
		{
			return createOrderedEnumerable(keySelector, 
				comparer || Comparer.defaultComparer, false);
		}
		
		public function thenByDescending(keySelector : Function, comparer : Function = null) : IOrderedEnumerable
		{
			return createOrderedEnumerable(keySelector, 
				comparer || Comparer.defaultComparer, true);
		}
		
		public function createOrderedEnumerable(keySelector : Function, 
			comparer : Function, descending : Boolean) : IOrderedEnumerable
		{
			if (keySelector == null)
			{
				throw new ArgumentError("keySelector cannot be null");
			}
			
			comparer = comparer || Comparer.defaultComparer;
			
			if (descending)
			{
				comparer = Comparer.reverse(comparer);
			}
			
			var primarySelector : Function = _compositeSelector;
			var newKeySelector : Function = function(element:Object) : CompositeKey
			{
				return new CompositeKey(primarySelector(element), keySelector(element));
			};
			
			var newKeyComparer : Function = CompositeKey.comparer(_compositeComparer, comparer);
			
			return new OrderedEnumerable(_source, newKeySelector, newKeyComparer);
		}
		
		public override function getEnumerator():IEnumerator
		{
			var data : Array = _source.toArray();
			
			var length : int = data.length;
			var indexes : Array = new Array(length);
			var keys : Array = new Array(length);
			
			for (var i:int = 0; i<indexes.length; i++)
			{
				indexes[i] = i;
				keys[i] = _compositeSelector(data[i]);
			}
			
			var nextYield : int = 0;
			
			var stack : Array = new Array();
			stack.push(new LeftRight(0, length - 1));
			
			var currentValue : Object = null;
			var right : int = -1;
			
			return new ClosureEnumerator(function():Boolean
			{
				if (nextYield <= right)
				{
					currentValue = data[indexes[nextYield]];
					nextYield++;
					
					return true;
				}
				
				while (stack.length > 0)
				{				
					var leftRight : LeftRight = stack.pop();
					
					var left : int = leftRight.left;
					right = leftRight.right;
					
					if (right > left)
					{
						var pivot : int = int(left + (right - left) / 2);
						var pivotPosition : int = partition(indexes, keys, left, right, pivot);
						
						stack.push(new LeftRight(pivotPosition + 1, right));
						stack.push(new LeftRight(left, pivotPosition - 1));
					}
					else if (nextYield <= right)
					{
						currentValue = data[indexes[nextYield]];
						nextYield++;
						
						return true;
					}
				}
				
				return false;
			},
			function():Object { return currentValue; });
		}
		
		private function partition(indexes : Array, keys : Array, left : int, right : int, pivot : int) : int
		{
			var pivotIndex : int = indexes[pivot];
			
			var pivotKey : Object = keys[pivotIndex];
			
			indexes[pivot] = indexes[right];
			indexes[right] = pivotIndex;
			
			var storeIndex : int = left;
			
			for (var i:int=left; i<right; i++)
			{
				var candidateIndex : int = indexes[i];
				var candidateKey : Object = keys[candidateIndex];
				
				var comparison : int = _compositeComparer(candidateKey, pivotKey);
				
				if (comparison < 0 || (comparison == 0 && candidateIndex < pivotIndex))
				{
					indexes[i] = indexes[storeIndex];
					indexes[storeIndex] = candidateIndex;
					storeIndex++;
				}
			}
			
			var tmp : int = indexes[storeIndex];
			indexes[storeIndex] = indexes[right];
			indexes[right] = tmp;
			
			return storeIndex;
		}

	}
}

class CompositeKey
{
	public var primary : Object;
	public var secondary : Object;
	
	public function CompositeKey(primary : Object, secondary : Object)
	{
		this.primary = primary;
		this.secondary = secondary;
	}
	
	public static function comparer(primaryComparer : Function, secondaryComparer : Function) : Function
	{
		return function(l:CompositeKey, r:CompositeKey) : int
		{
			var primaryResult : int = primaryComparer(l.primary, r.primary);
			
			if (primaryResult != 0)
			{
				return primaryResult;
			}
			
			return secondaryComparer(l.secondary, r.secondary);
		};
	}
}

class LeftRight
{
	public var left : int;	
	public var right : int;
	
	public function LeftRight(left : int, right : int)
	{
		this.left = left;
		this.right = right;
	}
}