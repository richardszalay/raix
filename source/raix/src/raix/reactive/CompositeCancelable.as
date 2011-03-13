package raix.reactive
{
	import raix.reactive.ICancelable;
	
	/**
	 * Represents a cancelable resource that controls multiple 
	 * other cancelable resources 
	 */
	public class CompositeCancelable implements ICancelable
	{
		private var _cancelled : Boolean = false;
		private var _cancelables : Array;
		
		/**
		 * Creates a composite cancelable instance with the cancelable 
		 * instances to start with
		 */
		public function CompositeCancelable(values : Array = null)
		{
			_cancelables = (values || []).slice();
		}
		
		/**
		 * Adds a cancelable resource to the list of cancelable resources. If 
		 * this instance has already been canceled, the resource will be immediately 
		 * canceled and not added to the list.
		 */
		public function add(cancelable : ICancelable) : void
		{
			if (_cancelled)
			{
				cancelable.cancel();
			}
			else
			{			
				_cancelables.push(cancelable);
			}
		}
		
		/**
		 * Removes a cancelable resource from the list
		 */
		public function remove(cancelable : ICancelable) : void
		{
			for (var i:int=0; i<_cancelables.length; i++)
			{
				if (_cancelables[i] == cancelable)
				{
					_cancelables.splice(i, 1);
					break;
				}
			}
		}
		
		/**
		 * Gets the number of resources in this list
		 */
		public function get count() : uint
		{
			return _cancelables.length;
		}

		/**
		 * Cancels (and removes) all resources in this instance
		 */
		public function cancel():void
		{
			_cancelled = true;
			
			while(_cancelables.length > 0)
			{
				_cancelables.shift().cancel();
			}
		}
		
		/**
		 * Gets the list of cancelable resources in this instance
		 */
		public function get cancelables() : Array
		{
			return _cancelables.slice();
		}
	}
}