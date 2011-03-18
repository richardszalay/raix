package raix.interactive
{
	internal class OrderedEnumerable extends AbsEnumerable implements IOrderedEnumerable
	{
		private var _source : IEnumerable;
		private var _comparer : Function;
		
		public function OrderedEnumerable(source : IEnumerable, comparer : Function)
		{
			this._source = source;
			this._comparer = comparer;
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
			
			var secondaryComparer : Function = Comparer.projection(keySelector, comparer);
			
			if (descending)
			{
				secondaryComparer = Comparer.reverse(secondaryComparer);
			}
			
			return new OrderedEnumerable(_source, 
				Comparer.compound(_comparer, secondaryComparer));
		}
		
		public override function getEnumerator():IEnumerator
		{
			var currentValue : Object = null;
			var elements : Array = this.toArray();
			
			return new ClosureEnumerator(function():Boolean
			{
				if (elements.length > 0)
				{
					var minElement : Object = elements[0];
					var minElementIndex : int = 0;
					
					for (var i:int=1; i<elements.length; i++)
					{
						if (_comparer(elements[i], minElement) < 0)
						{
							minElement = elements[i];
							minElementIndex = i;
						}						
					}
					
					elements.splice(minElementIndex, 1);
					
					currentValue = minElement;
					
					return true;
				}
				
				return false;
			},
			function():Object { return currentValue; });
		}

	}
}