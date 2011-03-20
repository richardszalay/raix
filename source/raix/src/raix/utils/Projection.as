package raix.utils
{
	/**
	 * Contains common projection functions that can be used with IEnumerable.map 
	 * and other 
	 */	
	public class Projection
	{
		/**
		 * Returns a selector function that retrieves a property from an element. 
		 * @param propertyName The property to map from each element
		 * @return A function that returns the property value of propertyName or null if the element was null
		 */	
		public static function property(propertyName : String) : Function
		{
			if (propertyName == null || propertyName.length == 0)
			{
				throw new ArgumentError("propertyName cannot be null or empty");
			}
			
			return function(v:Object) : Object
			{
				return (v != null)
					? v[propertyName]
					: null;
			};
		}
		
		/**
		 * Returns a selector function that converts a string to lower case
		 * @return A function that returns the string element as lower case or null if the element was null
		 */
		public static function get toLowerCase() : Function
		{
			return function(v:String) : String
			{
				return (v != null)
					? v.toLowerCase()
					: null;
			}
		}
		
		/**
		 * Returns a selector function that converts a string to upper case
		 * @return A function that returns the string element as lower case or null if the element was null
		 */		
		public static function get toUpperCase() : Function
		{
			return function(v:String) : String
			{
				return (v != null)
					? v.toUpperCase()
					: null;
			}
		}
		
		/**
		 * Returns a selector function that converts an object to a string
		 * @return A function that returns the string representation of an element or null if the element was null
		 */		
		public static function get toString() : Function
		{
			return function(v:Object) : String
			{
				return (v != null)
					? v.toString()
					: null;
			}
		}
	}
}