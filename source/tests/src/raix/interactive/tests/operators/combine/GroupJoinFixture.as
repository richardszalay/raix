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
	public class GroupJoinFixture
	{
		[Test]
		public function joins_sequences_based_on_key() : void
		{
			var outer : Array = [
				"first", "second", "third"
			];
			
			var inner : Array = [
				"essence", "offer", "eating", "psalm"
			];
			
			var query : IEnumerable = toEnumerable(outer).groupJoin(
				toEnumerable(inner),
				function(outer:String):String { return outer.charAt(0); },
				function(inner:String):String { return inner.charAt(1); },
				function(outer:String, inner:IEnumerable) : String { return outer.toString() + ":" + inner.toArray().join(';'); })
				
			AssertEx.assertArrayEquals(
				["first:offer", "second:essence;psalm", "third:"],
				query.toArray());
		}
	}
}