package raix.interactive.tests.operators.mutation
{
	import flash.utils.Dictionary;
	
	import org.flexunit.Assert;
	
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ToDictionaryFixture
	{
		[Test]
		public function maps_values_into_dictionary_using_result_selector():void
		{
			var inputs : Array = [
				"one", "two", "three"
			];
			
			var dictionary : Dictionary = toEnumerable(inputs).toDictionary(
				function(x:String):String { return x.charAt(1); },
				function(x:String):String { return x.charAt(0); });
			
			Assert.assertEquals("o", dictionary["n"]);
			Assert.assertEquals("w", dictionary["t"]);
			Assert.assertEquals("h", dictionary["t"]);
		}
		
		[Test]
		public function uses_original_value_when_no_resultselector_specified():void
		{
			var inputs : Array = [
				"one", "two", "three"
			];
			
			var dictionary : Dictionary = toEnumerable(inputs).toDictionary(
				function(x:String):String { return x.charAt(1); });
			
			Assert.assertEquals("o", dictionary["one"]);
			Assert.assertEquals("w", dictionary["two"]);
			Assert.assertEquals("h", dictionary["three"]);
		}
		
		[Test(expects="ArgumentError")]
		public function does_not_support_duplicate_keys():void
		{
			var inputs : Array = [
				"one", "two", "three"
			];
			
			var dictionary : Dictionary = toEnumerable(inputs).toDictionary(
				function(x:String):String { return x.charAt(0); });
		}
		
		[Test(expects="ArgumentError")]
		public function does_not_support_null_keys():void
		{
			var inputs : Array = [
				"one", "two", "three"
			];
			
			var lookup : Dictionary = toEnumerable(inputs).toDictionary(
				function(x:Object):Object { return null; });
			
			AssertEx.assertArrayEquals(
				["one", "two", "three"],
				lookup.getValues(null).toArray());
				
			AssertEx.assertArrayStrictlyEquals(
				[null],
				lookup.map(function(g:IGrouping):Object { return g.key; })
					.toArray());
		}
	}
}