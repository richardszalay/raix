package raix.interactive.tests.operators.combine
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.interactive.IEnumerable;
	import raix.interactive.IEnumerator;
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ZipFixture
	{
		[Test]
		public function combines_sequences_in_order() : void
		{
			var left : Array = [
				1, 2, 3, 4
			];
			
			var right : Array = [
				"one", "two", "three", "four"
			];
			
			AssertEx.assertArrayEquals(
				["1:one", "2:two", "3:three", "4:four"],
				toEnumerable(left)
					.zip(toEnumerable(right), function(l:int, r:String):String
					{
						return l.toString() + ":" + r;
					})
					.toArray());
		}
		
		[Test]
		public function stops_at_the_first_end() : void
		{
			var left : Array = [
				1
			];
			
			var right : Array = [
				"one", "two", "three", "four"
			];
			
			AssertEx.assertArrayEquals(
				["1:one"],
				toEnumerable(left)
					.zip(toEnumerable(right), function(l:int, r:String):String
					{
						return l.toString() + ":" + r;
					})
					.toArray());
		}
	}
}